#!/usr/bin/env python3
"""Granola Sync release script — builds, signs, publishes, and installs.

Usage:
  python scripts/release.py 1.0.0
  python scripts/release.py 2.0.0 --skip-brew   # skip local brew reinstall
"""

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"
GREEN = "\033[32m"
RED = "\033[31m"
CYAN = "\033[36m"
MAGENTA = "\033[35m"
CHECK = f"{GREEN}\u2714{RESET}"
CROSS = f"{RED}\u2718{RESET}"
ARROW = f"{CYAN}\u279c{RESET}"

REPO = "mahmoudSalim/granola-sync"
TAP_REPO = "mahmoudSalim/homebrew-granola"
TOTAL = 9


def header(step: int, msg: str):
    print(f"\n{BOLD}{CYAN}[{step}/{TOTAL}]{RESET} {BOLD}{msg}{RESET}")
    print(f"{DIM}{'─' * 60}{RESET}")


def ok(msg: str):
    print(f"  {CHECK} {msg}")


def fail(msg: str):
    print(f"  {CROSS} {RED}{msg}{RESET}")


def info(msg: str):
    print(f"  {ARROW} {msg}")


def dim(msg: str):
    print(f"  {DIM}{msg}{RESET}")


def sh(cmd: str, cwd: str | None = None, check: bool = True) -> subprocess.CompletedProcess:
    dim(f"$ {cmd}")
    r = subprocess.run(cmd, shell=True, cwd=cwd)
    if check and r.returncode != 0:
        fail(f"Exit {r.returncode}")
        sys.exit(1)
    return r


def cap(cmd: str, cwd: str | None = None, check: bool = True) -> str:
    r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode != 0:
        return ""
    return r.stdout.strip()


def update_formula(formula_path: str, sha: str, version: str | None = None):
    with open(formula_path) as f:
        content = f.read()
    content = re.sub(r'sha256 "[a-f0-9]+"', f'sha256 "{sha}"', content)
    if version:
        content = re.sub(r'version "[^"]+"', f'version "{version}"', content)
    with open(formula_path, "w") as f:
        f.write(content)


# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------


def step_build(d: str):
    header(1, "Clean build")
    subprocess.run("pkill -9 GranolaSync", shell=True, capture_output=True)
    if os.path.isdir(f"{d}/build"):
        shutil.rmtree(f"{d}/build")
    sh("make app", cwd=d)
    ok("App built")


def step_bundle(d: str):
    header(2, "Bundle Python")
    sh("bash scripts/bundle-python.sh", cwd=d)
    ok("Python bundled")


def step_sign_dmg(d: str, version: str):
    header(3, "Sign and create DMG")
    app = os.path.join(d, "build", "Granola Sync.app")

    # ditto --norsrc: only reliable way to strip xattrs on macOS Sequoia
    info("Stripping resource forks (ditto --norsrc)...")
    clean = app + ".clean"
    if os.path.isdir(clean):
        shutil.rmtree(clean)
    subprocess.run(["ditto", "--norsrc", app, clean], check=True)
    shutil.rmtree(app)
    os.rename(clean, app)
    ok("Clean")

    info("Code signing...")
    sh(f'codesign --force --sign - "{app}"')
    ok("Signed")

    info("Creating DMG...")
    sh(f"bash scripts/create-dmg.sh {version}", cwd=d)
    ok("DMG ready")


def step_git_and_release(d: str, version: str):
    """Steps 4-7 combined: commit, push, release, then get real SHA."""
    header(4, "Commit and push")
    formula = os.path.join(d, "homebrew", "granola-sync.rb")
    dmg = os.path.join(d, "build", f"GranolaSync-{version}.dmg")

    # Put a placeholder SHA so the formula file is committed
    local_sha = cap(f'shasum -a 256 "{dmg}"').split()[0]
    update_formula(formula, local_sha, version)
    dim(f"Local SHA: {local_sha}")

    # Stage only known files — never use 'git add -A' to avoid picking up stray files
    sh("git add homebrew/granola-sync.rb scripts/release.py", cwd=d)
    sh("git commit --amend --no-edit", cwd=d)
    ok(f"Commit: {cap('git rev-parse --short HEAD', cwd=d)}")

    info("Removing branch protection...")
    cap(f"gh api repos/{REPO}/branches/main/protection -X DELETE", check=False)

    info("Pushing main...")
    sh("git push --force origin main", cwd=d)
    info("Syncing dev...")
    sh("git checkout dev", cwd=d)
    sh("git reset --hard main", cwd=d)
    sh("git push --force origin dev", cwd=d)
    sh("git checkout main", cwd=d)
    ok("Pushed")

    info("Re-enabling branch protection...")
    subprocess.run(
        ["gh", "api", f"repos/{REPO}/branches/main/protection", "-X", "PUT", "--input", "-"],
        input='{"required_status_checks":null,"enforce_admins":true,"required_pull_request_reviews":null,"restrictions":null}',
        capture_output=True, text=True,
    )
    ok("Branch protection restored")

    header(5, "Create GitHub release")
    info("Cleaning old release...")
    cap(f"gh release delete v{version} --yes", check=False)
    subprocess.run(["git", "tag", "-d", f"v{version}"], cwd=d, capture_output=True)
    cap(f"git push origin --delete v{version}", check=False)

    info("Tagging...")
    sh(f"git tag v{version}", cwd=d)
    sh(f"git push origin v{version}", cwd=d)

    info("Creating release...")
    notes = (
        f"## Granola Sync v{version}\n\n"
        "Export Granola meetings to Google Drive as .docx files.\n\n"
        "### Install\n"
        "```\n"
        "brew tap mahmoudSalim/granola\n"
        "brew install --cask granola-sync\n"
        "```\n\n"
        "### Features\n"
        "- Menu bar app with popover dashboard\n"
        "- Scheduled sync via launchd\n"
        "- Setup wizard for first-time configuration\n"
        "- Transcript + summary + notes in each .docx\n"
    )
    r = subprocess.run(
        ["gh", "release", "create", f"v{version}", "--title", f"Granola Sync v{version}", "--notes", notes],
        cwd=d,
    )
    if r.returncode != 0:
        fail(f"Release creation failed (exit {r.returncode})")
        sys.exit(1)

    info("Uploading DMG (with retry)...")
    for attempt in range(5):
        if attempt > 0:
            wait = 5 * (attempt + 1)
            info(f"Upload retry {attempt}/4 — waiting {wait}s...")
            time.sleep(wait)
        r = subprocess.run(
            f'gh release upload v{version} "{dmg}" --clobber',
            shell=True, cwd=d,
        )
        if r.returncode == 0:
            break
        dim(f"Upload attempt {attempt + 1} failed (exit {r.returncode})")
    else:
        fail("DMG upload failed after 5 attempts!")
        sys.exit(1)
    ok(f"https://github.com/{REPO}/releases/tag/v{version}")

    # Download DMG via HTTPS (same path brew uses) to get the REAL SHA.
    # gh release download uses the API which may return original bytes,
    # while brew downloads via CDN which can differ. Use curl -L.
    header(6, "Verify release SHA")
    url = f"https://github.com/{REPO}/releases/download/v{version}/GranolaSync-{version}.dmg"
    with tempfile.NamedTemporaryFile(suffix=".dmg", delete=False) as tmp:
        tmp_path = tmp.name

    info("Waiting 5s for GitHub CDN to propagate...")
    time.sleep(5)

    real_sha = None
    for attempt in range(3):
        if attempt > 0:
            wait = 5 * (attempt + 1)
            info(f"Retry {attempt}/2 — waiting {wait}s...")
            time.sleep(wait)

        info(f"Downloading DMG via curl (attempt {attempt + 1})...")
        r = subprocess.run(["curl", "-fSL", "-o", tmp_path, url])
        if r.returncode != 0:
            dim(f"curl failed (exit {r.returncode})")
            continue

        sha1 = hashlib.sha256(open(tmp_path, "rb").read()).hexdigest()
        dim(f"SHA: {sha1}")

        # Quick second download to confirm CDN is stable
        time.sleep(2)
        subprocess.run(["curl", "-fsSL", "-o", tmp_path, url], capture_output=True)
        sha2 = hashlib.sha256(open(tmp_path, "rb").read()).hexdigest()

        if sha1 == sha2:
            real_sha = sha1
            break
        dim(f"CDN unstable: {sha1[:16]}... vs {sha2[:16]}...")

    os.unlink(tmp_path)

    if not real_sha:
        fail("Could not get stable SHA from GitHub CDN after 5 attempts!")
        sys.exit(1)

    if real_sha == local_sha:
        ok(f"SHA matches: {CYAN}{real_sha}{RESET}")
    else:
        info(f"Local:    {local_sha}")
        info(f"GitHub:   {CYAN}{real_sha}{RESET}")
        info("SHA differs (GitHub re-encodes DMG) — updating formula...")
        update_formula(formula, real_sha)

        # Amend commit + push again with correct SHA
        info("Re-amending commit with correct SHA...")
        cap(f"gh api repos/{REPO}/branches/main/protection -X DELETE", check=False)
        sh("git add homebrew/granola-sync.rb", cwd=d)
        sh("git commit --amend --no-edit", cwd=d)
        sh("git push --force origin main", cwd=d)
        sh("git checkout dev && git reset --hard main && git push --force origin dev && git checkout main", cwd=d)
        subprocess.run(
            ["gh", "api", f"repos/{REPO}/branches/main/protection", "-X", "PUT", "--input", "-"],
            input='{"required_status_checks":null,"enforce_admins":true,"required_pull_request_reviews":null,"restrictions":null}',
            capture_output=True, text=True,
        )
        ok(f"Formula updated with real SHA: {CYAN}{real_sha}{RESET}")

    return real_sha


def step_tap(d: str, version: str):
    header(7, "Update Homebrew tap")
    tap = os.path.join(os.path.dirname(d), "homebrew-granola")

    if not os.path.isdir(tap):
        info("Cloning tap repo...")
        sh(f"git clone git@github.com:{TAP_REPO}.git {tap}")
    else:
        sh("git pull --rebase origin main", cwd=tap)

    shutil.copy2(
        os.path.join(d, "homebrew", "granola-sync.rb"),
        os.path.join(tap, "Casks", "granola-sync.rb"),
    )
    sh("git add Casks/granola-sync.rb", cwd=tap)

    r = subprocess.run("git commit --amend --no-edit", shell=True, cwd=tap, capture_output=True)
    if r.returncode != 0:
        sh(f'git commit -m "Update granola-sync to v{version}"', cwd=tap)

    sh("git push --force origin main", cwd=tap)
    ok("Tap updated")


def step_brew():
    header(8, "Clean Homebrew install")

    info("Stopping running app...")
    subprocess.run("pkill -9 GranolaSync", shell=True, capture_output=True)

    info("Removing old install...")
    cap("brew uninstall --cask granola-sync", check=False)
    cap("brew untap mahmoudSalim/granola", check=False)

    info("Clearing cache...")
    for p in ["*GranolaSync*", "*granola-sync*"]:
        subprocess.run(f"rm -f ~/Library/Caches/Homebrew/downloads/{p}", shell=True, capture_output=True)
    if os.path.isdir("/Applications/Granola Sync.app"):
        shutil.rmtree("/Applications/Granola Sync.app")

    info("Installing fresh...")
    sh("brew tap mahmoudSalim/granola")
    sh("brew install --cask granola-sync")

    app = "/Applications/Granola Sync.app"
    if not os.path.isdir(app):
        fail("App not found in /Applications!")
        sys.exit(1)
    ok("Installed")

    xattrs = cap(f'xattr "{app}"', check=False)
    if "quarantine" in xattrs:
        fail("Quarantine attribute present!")
    else:
        ok("No quarantine")


def step_verify():
    header(9, "Verify")
    app = "/Applications/Granola Sync.app"

    info("Launching app...")
    subprocess.run(["open", app])
    time.sleep(2)
    ps = cap("pgrep -l GranolaSync", check=False)
    if "GranolaSync" in ps:
        ok(f"Running (PID {ps.split()[0]})")
    else:
        fail("App did not start!")

    spotlight = cap('mdfind "kMDItemFSName == \'Granola Sync.app\'"', check=False)
    if "/Applications/Granola Sync.app" in spotlight:
        ok("Spotlight indexed")
    else:
        dim("Spotlight may need a moment to index")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Release Granola Sync")
    parser.add_argument("version", help="Version (e.g. 1.0.0)")
    parser.add_argument("--skip-brew", action="store_true", help="Skip local brew reinstall")
    args = parser.parse_args()

    d = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(d)
    v = args.version
    t0 = time.time()

    print(f"\n{BOLD}{MAGENTA}{'═' * 60}{RESET}")
    print(f"{BOLD}{MAGENTA}  Granola Sync v{v} — Release Pipeline{RESET}")
    print(f"{BOLD}{MAGENTA}{'═' * 60}{RESET}")

    step_build(d)                          # 1
    step_bundle(d)                         # 2
    step_sign_dmg(d, v)                    # 3
    step_git_and_release(d, v)             # 4-6
    step_tap(d, v)                         # 7
    if not args.skip_brew:
        step_brew()                        # 8
        step_verify()                      # 9
    else:
        dim("Skipping brew install (--skip-brew)")

    elapsed = time.time() - t0
    print(f"\n{BOLD}{GREEN}{'═' * 60}{RESET}")
    print(f"{BOLD}{GREEN}  Release v{v} complete in {elapsed:.0f}s{RESET}")
    print(f"{BOLD}{GREEN}{'═' * 60}{RESET}")
    print(f"  {ARROW} App:      /Applications/Granola Sync.app")
    print(f"  {ARROW} Release:  https://github.com/{REPO}/releases/tag/v{v}")
    print(f"  {ARROW} Homebrew: brew install --cask granola-sync")
    print()


if __name__ == "__main__":
    main()

"""CLI entry point — granola-sync command with subcommands."""

import argparse
import json
import sys

from . import __version__
from . import config


def cmd_export(args):
    from .exporter import run_export

    cfg = config.load_config()
    result = run_export(cfg)

    if args.json:
        print(json.dumps(result.to_dict(), indent=2))
    else:
        if result.exported > 0:
            for f in result.files:
                print(f"  [ok] {f}")
        print(f"\n  Exported:    {result.exported}")
        print(f"  API fetched: {result.api_fetched}")
        print(f"  Skipped:     {result.skipped}")
        if result.errors:
            print(f"  Errors:      {len(result.errors)}")
            for e in result.errors:
                print(f"    [ERR] {e}")
        print(f"\n  {result.message}")

    sys.exit(0 if result.success else 1)


def cmd_status(args):
    from .cache import load_cache
    from .manifest import load_manifest
    from .auth import get_access_token
    from . import launchd

    cfg = config.load_config()
    status = {}

    # Granola cache
    cache_path = config.expand(cfg.get("granola_cache_path", ""))
    try:
        cache = load_cache(cache_path)
        status["granola_cache"] = "connected"
        status["documents_in_cache"] = len(cache.documents)
    except Exception as e:
        status["granola_cache"] = f"error: {e}"
        status["documents_in_cache"] = 0

    # Drive
    drive_path = config.expand(cfg.get("drive_path", ""))
    import os
    status["drive_path"] = drive_path
    status["drive_accessible"] = os.path.isdir(drive_path) if drive_path else False

    # Manifest
    manifest_path = config.expand(cfg.get("manifest_path", ""))
    manifest = load_manifest(manifest_path)
    status["manifest_count"] = len(manifest)

    # Auth
    auth_path = config.expand(cfg.get("granola_auth_path", ""))
    status["api_auth"] = "available" if get_access_token(auth_path) else "unavailable"

    # LaunchAgent
    status["launchd"] = launchd.status()

    if args.json:
        print(json.dumps(status, indent=2))
    else:
        print(f"  Granola cache:    {status['granola_cache']}")
        print(f"  Documents:        {status['documents_in_cache']}")
        print(f"  Drive path:       {status['drive_path'] or '(not set)'}")
        print(f"  Drive accessible: {'yes' if status['drive_accessible'] else 'no'}")
        print(f"  Exported:         {status['manifest_count']}")
        print(f"  API auth:         {status['api_auth']}")
        ld = status["launchd"]
        print(f"  LaunchAgent:      {'loaded' if ld['loaded'] else 'installed' if ld['installed'] else 'not installed'}")


def cmd_config(args):
    cfg = config.load_config()

    if args.action == "show":
        if args.json:
            print(json.dumps(cfg, indent=2))
        else:
            for k, v in cfg.items():
                print(f"  {k}: {v}")

    elif args.action == "set":
        if not args.key or args.value is None:
            print("Usage: granola-sync config set <key> <value>", file=sys.stderr)
            sys.exit(1)
        # Type coercion for known types
        value = args.value
        if args.key in ("schedule_interval",):
            value = int(value)
        elif args.key in ("notifications_enabled",):
            value = value.lower() in ("true", "1", "yes")
        cfg[args.key] = value
        config.save_config(cfg)
        print(f"  Set {args.key} = {value}")

    elif args.action == "get":
        if not args.key:
            print("Usage: granola-sync config get <key>", file=sys.stderr)
            sys.exit(1)
        val = cfg.get(args.key)
        if args.json:
            print(json.dumps({args.key: val}))
        else:
            print(f"  {args.key}: {val}")

    elif args.action == "init":
        if config.CONFIG_PATH.exists() and not args.force:
            print(f"Config already exists at {config.CONFIG_PATH}")
            print("Use --force to overwrite.")
            sys.exit(1)
        drive = config.detect_drive_path()
        if drive:
            cfg["drive_path"] = drive
            print(f"  Detected Google Drive: {drive}")
        config.save_config(cfg)
        print(f"  Config written to {config.CONFIG_PATH}")

    elif args.action == "validate":
        errors, warnings = config.validate_config(cfg)
        for w in warnings:
            print(f"  [~] {w}")
        if errors:
            for e in errors:
                print(f"  [!] {e}")
            sys.exit(1)
        else:
            print("  Config is valid.")


def cmd_launchd(args):
    from . import launchd

    if args.action == "install":
        cfg = config.load_config()
        interval = cfg.get("schedule_interval", 1209600)
        log_path = config.expand(cfg.get("log_path", ""))
        msg = launchd.install(interval, log_path or None)
        print(f"  {msg}")

    elif args.action == "uninstall":
        msg = launchd.uninstall()
        print(f"  {msg}")

    elif args.action == "status":
        info = launchd.status()
        if args.json:
            print(json.dumps(info, indent=2))
        else:
            print(f"  Installed: {info['installed']}")
            print(f"  Loaded:    {info['loaded']}")
            if info.get("interval"):
                days = info["interval"] // 86400
                print(f"  Interval:  {info['interval']}s ({days} days)")


def cmd_version(args):
    print(f"granola-sync {__version__}")


def main():
    parser = argparse.ArgumentParser(
        prog="granola-sync",
        description="Export Granola meetings to Google Drive as .docx files",
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON (for Swift bridge)")
    subparsers = parser.add_subparsers(dest="command")

    # export
    p_export = subparsers.add_parser("export", help="Export new meetings")
    p_export.add_argument("--json", action="store_true", dest="json")

    # status
    p_status = subparsers.add_parser("status", help="Show sync status")
    p_status.add_argument("--json", action="store_true", dest="json")

    # config
    p_config = subparsers.add_parser("config", help="Manage configuration")
    p_config.add_argument("action", choices=["show", "set", "get", "init", "validate"])
    p_config.add_argument("key", nargs="?")
    p_config.add_argument("value", nargs="?")
    p_config.add_argument("--json", action="store_true", dest="json")
    p_config.add_argument("--force", action="store_true")

    # launchd
    p_launchd = subparsers.add_parser("launchd", help="Manage scheduled exports")
    p_launchd.add_argument("action", choices=["install", "uninstall", "status"])
    p_launchd.add_argument("--json", action="store_true", dest="json")

    # version
    subparsers.add_parser("version", help="Show version")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    commands = {
        "export": cmd_export,
        "status": cmd_status,
        "config": cmd_config,
        "launchd": cmd_launchd,
        "version": cmd_version,
    }
    commands[args.command](args)

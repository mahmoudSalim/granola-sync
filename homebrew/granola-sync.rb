cask "granola-sync" do
  version "1.1.1"
  sha256 "55ae4c94eea3db25ed6d144e48ed2afb3d6aa9052ffe35f53deb2b13fc1d1b1c"

  url "https://github.com/mahmoudSalim/granola-sync/releases/download/v#{version}/GranolaSync-#{version}.dmg"
  name "Granola Sync"
  desc "Export Granola meetings to Google Drive as .docx, .md, or .txt files"
  homepage "https://github.com/mahmoudSalim/granola-sync"

  app "Granola Sync.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-d", "com.apple.quarantine", "#{appdir}/Granola Sync.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/GranolaSync",
    "~/Library/LaunchAgents/com.granola-sync.export.plist",
  ]
end

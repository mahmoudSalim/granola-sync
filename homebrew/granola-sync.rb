cask "granola-sync" do
  version "1.0.0"
  sha256 "4e1e0014c72f42267bba137f45a441ddf7846ad1a35800cf3b16c75da9832a70"

  url "https://github.com/mahmoudSalim/granola-sync/releases/download/v#{version}/GranolaSync-#{version}.dmg"
  name "Granola Sync"
  desc "Export Granola meetings to Google Drive as .docx files"
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

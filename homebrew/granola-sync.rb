cask "granola-sync" do
  version "1.1.4"
  sha256 "74ece2612f4736a6ca648311eddf58f08c0b641661a255b773effba0901a4b2c"

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

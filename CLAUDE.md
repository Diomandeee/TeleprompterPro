# Teleprompter Pro

## Overview
iOS app — Teleprompter Pro

## Build
- Uses xcodegen: `xcodegen generate` to regenerate .xcodeproj
- Bundle ID: `com.openclaw.teleprompterpro`
- Team: `8643C988C4`
- Min iOS: 17.0, Swift 6

## Deploy
- Archive: `xcodebuild archive -scheme TeleprompterPro ...`
- Export: Uses `ExportOptions.plist` (destination=export, NOT upload)
- TestFlight: Tag with `v*` to trigger GitHub Actions upload

## Gotchas
- Always use `-skipMacroValidation -skipPackagePluginValidation` for TCA apps
- iPad orientations: ALL 4 required in Info.plist
- CFBundleIconName must be set or TestFlight upload 409s

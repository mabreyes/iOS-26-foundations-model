# Receipt AI Generator with Apple Foundation Models

A SwiftUI app that turns a food idea into structured ingredients and recipe suggestions with Apple Foundation Models.

See Apple's documentation: [Apple Foundation Models](https://developer.apple.com/documentation/FoundationModels).

## Requirements
- Xcode (latest stable recommended)
- Swift 5.9+
- Homebrew

## Quickstart
1. Clone and open in Xcode:
```bash
git clone <your-repo-url>
cd ios-foundations
open ios-foundations.xcodeproj || open ios-foundations.xcworkspace || open .
```
2. Build and run from Xcode.

## Tooling
- SwiftFormat: code formatting (`.swiftformat`)
- SwiftLint: linting (`.swiftlint.yml`)
- pre-commit: Git hooks (`.pre-commit-config.yaml`)

Install tools and hooks:
```bash
brew install swiftformat swiftlint
pip3 install --user pre-commit
pre-commit install
```
Run hooks on all files:
```bash
pre-commit run --all-files
```

### SwiftLint enforcement mode
`scripts/run-swiftlint.sh` currently runs in advisory mode (does not block commits). To enforce blocking on violations, change the tail to:
```bash
exec swiftlint --strict
```

## Project structure
- `ios_foundationsApp.swift`: App entry point
- `ContentView.swift`: Main SwiftUI view
- Receipt parsing and recipe suggestion logic: `RecipeParser.swift`, `RecipeGenerator.swift`
- `Assets.xcassets/`: App assets
- `scripts/run-swiftlint.sh`: SwiftLint wrapper for hooks
- `.{swiftlint.yml, swiftformat, pre-commit-config.yaml}`: Tool configs

## Common commands
Format all files:
```bash
swiftformat .
```
Run SwiftLint via wrapper:
```bash
scripts/run-swiftlint.sh
```

## Troubleshooting
- SwiftLint SourceKit error: ensure full Xcode is installed and selected
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
pre-commit run --all-files
```

## License
Add your license here.

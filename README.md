# Silenium

Minecraft: Java Edition launcher for iOS. Built for TrollStore first.

Silenium is a native SwiftUI launcher. It's a separate project from [Amethyst-iOS](https://github.com/AngelAuraMC/Amethyst-iOS), with its own code. Amethyst and the wider PojavLauncher family showed what an iOS launcher can do, and this project uses those ideas as reference.

## Status

Early stage. Right now:

- [x] list of Minecraft releases and snapshots from Mojang's version manifest
- [x] offline accounts (UUID computed the same way as the vanilla server)
- [x] 2D head of each account (via mc-heads.net)
- [ ] ely.by login
- [ ] installing Vanilla, Forge and Fabric
- [ ] mods, texture packs, datapacks from Modrinth and CurseForge
- [ ] instances, file manager
- [ ] in-game overlay (FPS, memory), on-screen controls

## Requirements

- iOS 16.0 or later
- JIT for running the game. TrollStore gives this automatically. Other methods (AltStore, SideStore, StikDebug) also work, but they need a computer or a device connection.

## Install

### TrollStore

1. Download `Silenium.ipa` from [Releases](https://github.com/VartixTM/silenium-ios/releases) or from the latest build in [Actions](https://github.com/VartixTM/silenium-ios/actions).
2. Open the file in TrollStore (share sheet, "Open in TrollStore").

Bundle ID: `com.vartix.silenium`

## Build

Requires macOS with Xcode 15 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open Silenium.xcodeproj
```

Or let GitHub Actions build the unsigned ipa: the `build ipa` workflow runs on every push to `main` and on `v*` tags.

## Project layout

```
Silenium/
  SileniumApp.swift       app entry point
  Design/Theme.swift      colors, glass cards, background
  Views/                  SwiftUI screens (versions, accounts)
  Mojang/MojangAPI.swift  version manifest from piston-meta
  Accounts/               account model, UUID, storage
project.yml               XcodeGen project description
.github/workflows/        CI: build and package ipa
```

## Credits

- **VartixTM**: группа, которая делает Silenium
- **AngelKlear** (con1xx): разработчик
- [Amethyst-iOS](https://github.com/AngelAuraMC/Amethyst-iOS) and [PojavLauncher](https://github.com/PojavLauncherTeam) for the reference on how an iOS Minecraft launcher works
- [MC-Heads](https://mc-heads.net) for player heads
- Mojang for the version manifest

## License

TBD. See [LICENSE](LICENSE).

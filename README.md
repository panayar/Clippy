<p align="center">
  <img src="assets/ClippyBar-logo.svg" width="80" alt="ClippyBar logo" />
</p>

<h1 align="center">ClippyBar</h1>

<p align="center">
  <strong>Paste smarter, not harder.</strong><br/>
  A lightweight, privacy-first clipboard manager for macOS.
</p>

<p align="center">
  <a href="https://apps.apple.com/co/app/clippybar/id6760884112?l=en-GB&mt=12"><img src="https://img.shields.io/badge/Mac_App_Store-Download-007AFF?style=flat-square&logo=apple&logoColor=white" alt="Mac App Store" /></a>
  <a href="https://github.com/panayar/Clippy/stargazers"><img src="https://img.shields.io/github/stars/panayar/Clippy?style=flat-square&color=FFD60A" alt="Stars" /></a>
  <a href="https://github.com/panayar/Clippy/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" /></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-000?style=flat-square&logo=apple&logoColor=white" alt="macOS 13+" />
</p>

---

## Install

<a href="https://apps.apple.com/co/app/clippybar/id6760884112?l=en-GB&mt=12">
  <img src="assets/mac-app-store-badge.svg" alt="Download on the Mac App Store" height="48" />
</a>

Free on the Mac App Store. Requires macOS 13 (Ventura) or later.

---

## What it does

ClippyBar lives in your menu bar and remembers everything you copy. Press a shortcut, search, and paste &mdash; all in one motion.

| Feature | |
|---|---|
| **Clipboard History** | Auto-saves text and images as you copy |
| **Instant Search** | Filter your entire history in milliseconds |
| **Global Hotkey** | `⌥V` opens the picker at your cursor |
| **Pin Items** | Keep frequently used snippets always on top |
| **Auto-Paste** | Select an item and it pastes instantly |
| **App Exclusions** | Skip 1Password, banking apps, etc. |
| **100% Local** | No cloud, no accounts, no network requests |
| **Memory-Only Mode** | Optional &mdash; nothing written to disk |

---

## Privacy

Your clipboard never leaves your Mac.

- All data stored locally in `~/Library/Application Support/ClippyBar/`
- Zero network requests, zero telemetry, zero tracking
- Exclude sensitive apps from monitoring
- Optional memory-only mode for maximum privacy

For the full privacy policy, visit [clippy.bar/#privacy-policy](https://clippy.bar/#privacy-policy).


---

## Permissions

ClippyBar needs **Accessibility** access for the global hotkey and auto-paste. macOS will prompt you on first launch &mdash; grant it in **System Settings > Privacy & Security > Accessibility**.

---

## Tech Stack

| Component | Stack |
|-----------|-------|
| macOS App | Swift, SwiftUI, SQLite3, Carbon |
| Website | Next.js, Tailwind CSS |

---

## License

MIT

---

<p align="center">
  <sub>Made by <a href="https://github.com/panayar">@panayar</a> &middot; <a href="https://clippy.bar">clippy.bar</a></sub>
</p>

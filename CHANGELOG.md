# Changelog

All notable changes to the Router Check for macOS project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.1] - 2026-09-24

### 🚀 Features
- feat(header): convert login and logout buttons to icon buttons (`4e1e06b`)
- feat(settings): replace startup window dropdown with toggle switch (`f41c274`)
- feat(menubar): implement rich popover window and dynamic status label (`9465d28`)
- feat(dashboard): convert stats to vertical rows and harmonize card layouts (`384796c`)
- feat(tooling): add license, changelog, developer scripts, and makefile workflow (`dbaec03`)

### 🐛 Bug Fixes
- fix(window): fit dashboard window size snugly to content cards (`7608629`)

### 🔧 Maintenance & Tooling
- style(menubar): refine status item icons and spacing (`d46b965`)
- chore(git): enhance .gitignore with macOS system and metadata patterns (`2b9a592`)

---

### 🍏 macOS Installation & Gatekeeper Note
Because this open-source build is distributed outside the Mac App Store without a paid Apple Developer ID, macOS Gatekeeper may show a warning (*"Apple could not verify..."*) on first launch.

**To open the app, run this single command in Terminal:**
```bash
xattr -cr "/Applications/Router Check.app"
```
*Alternatively, open **System Settings ➔ Privacy & Security** and click **Open Anyway**.* 



## [v1.0.0] - 2026-09-24

### 🚀 Features
- **license**: Open-sourced under the MIT License
- **app**: Initial release of Router Check native macOS menu bar and desktop application (`7f1b5d2`)
- **zte-client**: Pure Swift `URLSession` ZTE client with cookie jar management, Base64 authentication, and goform API support (`7f1b5d2`)
- **signal-monitor**: Real-time RSRP / SINR cellular signal strength monitoring, rating levels, and min/avg/max statistics (`7f1b5d2`)
- **traffic-stats**: Live download/upload speed gauges, sparkline trend graphs, and session traffic counters (`7f1b5d2`)
- **network-info**: WAN/LAN IP discovery, DHCP state, WiFi MAC, connected clients, PPP connect/disconnect controls, and device metadata (`7f1b5d2`)
- **menu-bar**: macOS Menu Bar Extra support with dynamic signal status summary and quick controls (`7f1b5d2`)
- **config**: Persistent JSON settings for router host, credentials, and configurable polling intervals (`7f1b5d2`)
- **automation & tooling**: Developer Makefile, build, package, install, logs, and automated release scripts

---

### 🍏 macOS Installation & Gatekeeper Note
Because this open-source build is distributed outside the Mac App Store without a paid Apple Developer ID, macOS Gatekeeper may show a warning (*"Apple could not verify..."*) on first launch.

**To open the app, run this single command in Terminal:**
```bash
xattr -cr "/Applications/Router Check.app"
```
*Alternatively, open **System Settings ➔ Privacy & Security** and click **Open Anyway**.* 

<p align="center">
  <img src="https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/Resources/AppIcon.icns" width="128" alt="exímIA Meter icon" />
</p>

<h1 align="center">exímIA Meter</h1>

<p align="center">
  <strong>macOS menu bar app for monitoring Claude Code token usage in real-time</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.0.0-F59E0B?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/platform-macOS%2014+-000?style=flat-square&logo=apple&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/license-MIT-10B981?style=flat-square" alt="License" />
</p>

---

## What is it?

**exímIA Meter** is a lightweight macOS menu bar app that tracks your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) token usage — weekly, daily, per session, and per project. It reads local files from `~/.claude/` and optionally connects to the Anthropic API for real-time usage data.

No API keys required for basic usage. No network calls needed. Everything runs locally.

---

## Features

### Dashboard

| Feature | Description |
|---------|-------------|
| **Weekly & Session Usage** | Progress bars with countdown to reset |
| **Burn Rate Projection** | Estimates when you'll hit the weekly limit and % remaining at reset |
| **Model Distribution** | Visual breakdown of Opus / Sonnet / Haiku usage (7 days) |
| **Per-Project Usage** | Token consumption by project with relative bars |
| **Project Cards** | Quick-launch projects, change model, update AIOS — all from the popover |

### Insights (v2.0)

| Feature | Description |
|---------|-------------|
| **Cost Estimation** | Estimated USD cost for the past 7 days, weighted by model |
| **Usage Streak** | Consecutive days with activity |
| **Week-over-Week** | % change compared to the previous week |
| **Sparkline Chart** | 7-day token usage bar chart |
| **Activity Heatmap** | 24-hour activity grid with intensity levels |
| **Peak Detection** | Alert when today's usage is 2x+ above average |
| **Model Suggestion** | Recommends cheaper model when Opus dominates >60% |

### Notifications

| Feature | Description |
|---------|-------------|
| **Threshold Alerts** | Warning and critical alerts for session & weekly usage |
| **Hysteresis** | 5% margin prevents notification spam when usage fluctuates |
| **Adaptive Cooldown** | Escalates from 5min to 4h cooldown after first fire |
| **Weekly Report** | Sunday summary with tokens, sessions, cost, and streak |
| **Idle Detection** | Welcome-back notification after 4h+ of inactivity |
| **macOS Native** | Notification Center banners, custom sounds (14 system sounds) |

### Project Management

| Feature | Description |
|---------|-------------|
| **Auto-Discovery** | Finds projects in `~/.claude/projects/` |
| **Rename Detection** | Detects renamed directories and offers to update paths |
| **Custom Colors** | Color picker for each project |
| **Visibility Toggle** | Show/hide projects on the main page |
| **AIOS Update** | One-click `npx aios-core@latest install` for AIOS projects |
| **Drag & Reorder** | Reorder projects by dragging |

### Other

| Feature | Description |
|---------|-------------|
| **Export CSV** | Export all usage data (tokens, messages, sessions, cost, per-project) |
| **Self-Update** | Check for updates and install directly from the app |
| **Changelog Popup** | Auto-shows what's new after each update |
| **Dark Mode** | Forced dark theme with custom design tokens |
| **3-Layer Data** | Hybrid: Anthropic API > local .jsonl scan > stats-cache estimation |

---

## Installation

### Quick Install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash
```

This will clone, build, install to `/Applications/`, and open the app.

### Manual Install

```bash
git clone https://github.com/hugocapitelli/eximia-meter.git
cd eximia-meter
bash build-app.sh release
cp -r "dist/exímIA Meter.app" /Applications/
open "/Applications/exímIA Meter.app"
```

### Requirements

- **macOS 14 (Sonoma)** or later
- **Xcode Command Line Tools** (`xcode-select --install`)
- **Claude Code** installed with at least one usage session

---

## How It Works

exímIA Meter reads local files that Claude Code writes automatically:

```
~/.claude/
├── stats-cache.json       # Accumulated stats (Layer 3)
├── history.jsonl           # Session history
└── projects/
    └── <project-dir>/
        └── *.jsonl         # Per-session detailed logs (Layer 2)
```

**3-Layer Hybrid Data System:**

| Layer | Source | Priority | Description |
|-------|--------|----------|-------------|
| 1 | Anthropic OAuth API | Highest | Real-time utilization % and reset times |
| 2 | Local `.jsonl` scan | Medium | Exact token counts from session logs |
| 3 | `stats-cache.json` | Fallback | Estimated from cached statistics |

The app refreshes every 60 seconds. Click the timestamp in the footer to refresh manually.

---

## Configuration

On first launch:

1. Click the menu bar icon (top-right corner)
2. Go to **Settings** (gear icon)
3. Select your **Claude plan**:
   - **Pro** — ~100M tokens/week
   - **Max 5x** — ~500M tokens/week
   - **Max 20x** — ~2B tokens/week
4. Configure alert thresholds (optional)
5. Add project folders via **Projects** tab or use **Discover**

### API Connection (Optional)

If Claude Code is authenticated via OAuth, the app auto-detects credentials from `~/.claude/` and uses the Anthropic API for precise usage data. No manual configuration needed.

---

## Architecture

```
EximiaMeter/
├── App/                    # AppDelegate, entry point
├── Models/                 # Data models (Project, UsageData, ClaudeModel, etc.)
├── Services/               # Business logic
│   ├── CLIMonitorService       # FSEvents file watcher + polling fallback
│   ├── ProjectUsageService     # Per-project .jsonl scanning with caching
│   ├── UsageCalculatorService  # 3-layer hybrid calculation
│   ├── AnthropicUsageService   # OAuth API client
│   ├── NotificationService     # Alerts with hysteresis & persistence
│   └── ProjectDiscoveryService # Auto-discover Claude projects
├── ViewModels/             # Observable view models
├── Views/
│   ├── MenuBar/            # Popover UI (dashboard, cards, insights)
│   ├── Settings/           # Settings window (tabs)
│   ├── Onboarding/         # First-launch wizard
│   └── Shared/             # Reusable components (ExButton, ExProgressBar, etc.)
└── Storage/                # UserDefaults persistence
```

**Key design decisions:**
- Pure Swift + SwiftUI (no external dependencies)
- `@Observable` pattern (not Combine's `@Published`)
- NSPopover for menu bar UI
- NSWindow for Settings / Onboarding / Changelog
- Design tokens via `ExTokens` enum (colors, typography, spacing, radius)

---

## Updating

### From the App

Go to **Settings > About > Check for Updates**. If a new version is available, click **Update Now** — the app will download, build, and reinstall automatically.

An update banner also appears on the main popover when a new version is detected.

### From Terminal

```bash
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash
```

---

## Uninstall

From the app: **Settings > About > Uninstall**

Or manually:

```bash
rm -rf "/Applications/exímIA Meter.app"
defaults delete com.eximia.meter  # Remove preferences
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No data shown | Use Claude Code at least once to generate `~/.claude/stats-cache.json` |
| Build failed | Run `xcode-select --install` to install Swift toolchain |
| App not in menu bar | It runs as a menu bar app (no Dock icon). Look for the icon near the clock |
| macOS blocks the app | System Settings > Privacy & Security > scroll down > "Open Anyway" |
| Notifications not working | System Settings > Notifications > exímIA Meter > Allow Notifications |

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI + AppKit (NSPopover, NSWindow)
- **Target:** macOS 14+ (Sonoma)
- **Build:** Swift Package Manager
- **Dependencies:** None (zero external packages)
- **Lines of code:** ~6,000+ across 55 Swift files

---

## Changelog

See the full changelog in **Settings > About > What's New** or in [`Changelog.swift`](EximiaMeter/Models/Changelog.swift).

### v2.0.0
- Insights dashboard: cost estimation, streak, week-over-week comparison
- Sparkline chart (7-day tokens) and activity heatmap (24h)
- Peak detection and model suggestion
- CSV export of all usage data
- Custom project colors
- Weekly summary notification (Sundays)
- Idle detection with welcome-back notification

### v1.7.x
- Notification spam fix (persistence + hysteresis + adaptive cooldown)
- Burn rate projection (% remaining at reset)
- AIOS update button on project cards
- Directory rename detection
- Changelog popup after updates

### v1.6.0
- Update banner on home page
- Eye toggle for project visibility
- Auto-prune deleted projects
- OAuth token auto-refresh
- In-app self-update with code signing

[View all versions...](EximiaMeter/Models/Changelog.swift)

---

## License

MIT

---

<p align="center">
  Built with <a href="https://docs.anthropic.com/en/docs/claude-code">Claude Code</a>
</p>

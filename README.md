# Lucid 2.0

An iOS app for eye care and digital wellness: guided eye exercises, vision tests, and Screen Time-based "20-20-20 rule" break reminders.

## Features

- **Home** — daily "Lucid Score" dashboard, exercise/test reminders, and streak tracking.
- **Care (Train)** — a library of guided eye exercises (blink training, near/far focus, saccadic jumps, smooth pursuits, pencil push-ups) and vision tests (Landolt C, OSDI).
- **Protect** — Screen Time integration (Family Controls / DeviceActivity) that schedules app-blocking windows and reminds the user to take a break every 20 minutes, look at something 20 feet away, for 20 seconds.
- **Profile** — user profile and app settings, synced with a Supabase backend.

## Project structure

| Target | Purpose |
|---|---|
| `Lucid2.0` | Main SwiftUI app |
| `LucidMonitor` | DeviceActivityMonitor extension — applies/clears Screen Time shields and triggers break notifications on schedule |
| `ScreenBreakWidgetExtension` | WidgetKit extension providing the Live Activity for screen-break countdowns |
| `LucidShieldConfiguration` | Screen Time shield UI customization (`ShieldConfigurationDataSource`) — not yet wired up as a build target |

Key app folders under `Lucid2.0/`:

- `Features/` — SwiftUI feature modules (`Home`, `Train`, `Protect`, `Profile`, `Onboarding`, `ShieldPreview`)
- `Exercises_storyboard/` / `Tests_storyboard/` — legacy UIKit storyboard-based exercise and vision-test screens
- `Services/` — screen time, notifications, streaks, Supabase sync, and personalization engines
- `Data/` — models and repositories
- `DesignSystem/` — shared colors, typography, shapes, and view modifiers

## Requirements

- Xcode with iOS 26/27 SDK support (deployment targets vary by target; the main app effectively requires iOS 26+)
- Swift 5

## Building

Open `Lucid2.0.xcodeproj` in Xcode and run the `Lucid2.0` scheme.

## Configuration

`Lucid2.0/Services/SupabaseService.swift` contains the Supabase project URL and anon key used for syncing user profiles. Access control for this data should be enforced via Supabase Row Level Security policies, since the anon key is embedded in the client.

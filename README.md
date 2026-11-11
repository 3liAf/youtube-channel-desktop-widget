# BrandIt Stats — YouTube Channel Menu Bar & Desktop Widget

A native macOS menu bar status monitor and floating desktop widget built for **BrandIt** ([@BrandItQuiz](https://www.youtube.com/@BrandItQuiz)).

---

## Features

- **Live Menu Bar Status**: Displays your live subscriber count (`▶ 1 Sub`) directly in your top menu bar.
- **Interactive Details Card**: Click the menu bar icon to reveal:
  - Channel avatar, verified badge, and handle (`@BrandItQuiz`).
  - Real-time subscriber count and total video count.
  - **Milestone Tracker**: Visual progress bar tracking your road to the next subscriber milestone (10, 50, 100, 500, 1K...).
  - One-click shortcuts to your **Channel** and **YouTube Studio**.
  - Instant refresh button.
- **Floating Desktop Widget**: Click **"Desktop Widget"** in the popover to detach a floating translucent card onto your desktop wallpaper. You can drag and position it anywhere on your screen.
- **Zero Config**: Live scraping of public stats without requiring complex Google Cloud API keys.
- **Ultra Lightweight**: Pure Swift native binary with practically 0% CPU and low memory footprint.

---

## How to Run It

### Option A: Double-Click
Simply double-click **`BrandItStats.app`** or **`run.command`** in Finder.

### Option B: Terminal
```bash
open "/Users/mac/Applications/YouTube Channel Desktop Widget/BrandItStats.app"
```

---

## How to Make It Launch on Mac Startup (Login Item)

### Method 1: Automated (One-Click)
Double-click **`add-to-login-items.command`** in this folder, or run:
```bash
"/Users/mac/Applications/YouTube Channel Desktop Widget/add-to-login-items.command"
```

### Method 2: Manual (macOS System Settings)
1. Open **System Settings** on your Mac.
2. Navigate to **General** > **Login Items & Extensions**.
3. Under the **Open at Login** section, click the **`+`** button.
4. Select `BrandItStats.app` from:
   `~/Applications/YouTube Channel Desktop Widget/BrandItStats.app`
5. Click **Open**. It will now launch automatically every time you log in to your Mac.

---

## Rebuilding from Source

If you ever want to customize or rebuild the app:
```bash
./build.sh
```
The script compiles the Swift sources (`Sources/`) and outputs a new `BrandItStats.app`.

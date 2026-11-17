# BrandIt Stats — YouTube Channel Menu Bar & Desktop Widget

A native macOS menu bar status monitor and floating desktop widget with **multi-account support**, real-time subscriber and video tracking, milestone tracking, and aggregated network statistics.

---

## ✨ Features

- **Multi-Account & Multi-Channel Support**:
  - Add any YouTube channel by handle (e.g. `@BrandItQuiz`, `@MrBeast`) or channel URL.
  - Switch between channels instantly using the header dropdown.
  - Remove or reorder active accounts anytime.
- **🌟 Combined Network Overview**:
  - View total combined subscribers and videos across all your channels.
  - Aggregated milestone progress bar.
  - Visual breakdown list of all connected channels with individual stats.
- **Live Menu Bar Status**:
  - Configurable display modes:
    - **Active Channel**: e.g. `▶ @BrandIt: 1 Sub`
    - **Combined (All Accounts)**: e.g. `▶ 21.4M (2 Ch)`
    - **Compact Count**: e.g. `▶ 21.4M`
    - **Icon Only**: clean minimalist YouTube icon `▶`
  - Option to show or hide the channel handle in the menu bar.
- **Comprehensive Settings & Configurations**:
  - **Account Management**: Add new channels with real-time validation and avatar loading. Remove existing channels.
  - **Auto-Refresh Frequency**: Configurable intervals (2 minutes, 5 minutes, 15 minutes, 30 minutes, 1 hour).
  - **Menu Bar Formatting**: Choose your preferred status text style.
  - **Desktop Floating Widget Target**: Choose whether the widget tracks your active channel or your combined network.
  - **Automatic Persistence**: All added channels and custom settings are automatically saved and restored across app restarts.
- **Floating Desktop Widget**:
  - Detach a sleek, translucent floating card onto your desktop wallpaper.
  - Drag and place it anywhere on screen.
  - Displays real-time subscriber counts, total videos, and milestone progress.
- **Zero Config & Ultra Lightweight**:
  - No Google Cloud API keys or OAuth required — parses live public channel stats directly.
  - Pure Swift native binary with practically 0% CPU and minimal memory footprint.

---

## 🚀 How to Run It

### Option A: Double-Click
Simply double-click **`BrandItStats.app`** or **`run.command`** in Finder.

### Option B: Terminal
```bash
open BrandItStats.app
```

---

## ⚙️ How to Add Channels & Change Settings

1. Click the **YouTube icon** (`▶`) in your top macOS menu bar.
2. In the popover that appears:
   - **Switch Channel**: Click the account selector dropdown in the top-left to switch between any connected channel or **"🌟 All Accounts (Combined)"**.
   - **Settings & Add Accounts**: Click the gear icon (`⚙️`) or select **"Settings & Add Accounts..."** from the dropdown.
   - **Add Account**: Type any channel handle (e.g. `@MrBeast`, `@SecretBlox`, `@BrandItQuiz`) into the input field and click **"Add"**.
   - **Remove Account**: Click the trash icon next to any account in the list.
   - **Menu Bar Display**: Switch between Active Channel, Combined Total, Compact Count, or Icon Only.
   - **Auto-Refresh Interval**: Pick how frequently stats refresh in the background.

---

## 🖥️ How to Make It Launch on Mac Startup (Login Item)

### Method 1: Automated (One-Click)
Double-click **`add-to-login-items.command`** in this folder, or run:
```bash
./add-to-login-items.command
```

### Method 2: Manual (macOS System Settings)
1. Open **System Settings** on your Mac.
2. Navigate to **General** > **Login Items & Extensions**.
3. Under the **Open at Login** section, click the **`+`** button.
4. Select `BrandItStats.app` from:
   `BrandItStats.app`
5. Click **Open**. It will now launch automatically every time you log in to your Mac.

---

## 🛠️ Rebuilding from Source

If you ever want to customize or rebuild the app:
```bash
./build.sh
```
The script compiles the Swift sources (`Sources/`) and outputs a new `BrandItStats.app`.

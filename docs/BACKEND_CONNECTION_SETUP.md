# Backend Connection Setup Guide

## Overview
PlantGO now supports dynamic backend configuration! No need to hardcode IP addresses anymore - just enter your computer's IP in the app settings.

## Quick Setup

### 1. Find Your Computer's IP Address

**On Mac:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Your IP will look like: `192.168.x.x`

**Current IP:** `192.168.201.134`

**On Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter.

**On Linux:**
```bash
ip addr show
```

### 2. Start the Backend Server

```bash
cd backend
npm start
```

You should see:
```
🚀 PlantGO NFT Backend running on port 3001
```

### 3. Configure in the App

1. Open PlantGO app on your device
2. Navigate to **Course Map** screen
3. Tap the **Settings (⚙️) button** in the top-right corner
4. Enter your computer's IP address (e.g., `192.168.201.134`)
   - You can enter just the IP: `192.168.201.134`
   - Or with port: `192.168.201.134:3001`
   - Or full URL: `http://192.168.201.134:3001`
5. Tap **"Test & Save"**
6. Wait for the green checkmark ✅

### 4. Test NFT Minting

1. Go to Scanner screen
2. Scan a plant
3. Confirm identification
4. The app will now mint a real NFT on Solana Devnet!

## Important Notes

### Network Requirements
- ✅ Your phone and computer **must be on the same WiFi network**
- ✅ Both devices must be on the same subnet (usually automatic)
- ❌ Won't work if using mobile data on phone
- ❌ Won't work with VPN enabled

### Default Configurations
- **Android Emulator:** Uses `10.0.2.2:3001` (automatically works)
- **Real Device:** Requires your computer's actual IP address

### Backend Health Check
Test if backend is accessible from your device:
```bash
curl http://192.168.201.134:3001/health
```

Expected response:
```json
{
  "status": "ok",
  "network": "devnet",
  "timestamp": "2026-01-13T02:38:41.459Z"
}
```

## Troubleshooting

### "Connection failed" Error

**1. Check if backend is running:**
```bash
curl http://localhost:3001/health
```

**2. Check if firewall is blocking:**
- Mac: System Settings → Network → Firewall
- Make sure Node.js/Terminal is allowed

**3. Verify both devices on same WiFi:**
```bash
# On Mac - check your IP
ifconfig | grep "inet "

# On phone - check WiFi settings
# Should be on same network (e.g., both on "Home WiFi")
```

**4. Test from another device on same network:**
```bash
# From another computer or phone browser
http://192.168.201.134:3001/health
```

### "Backend unavailable, using simulated mint"

This means the app couldn't reach the backend. Check:
1. Is backend running? (`npm start` in backend folder)
2. Did you enter the correct IP in settings?
3. Are phone and computer on same WiFi?

### Backend Takes Too Long to Respond

- Check backend logs for errors
- Ensure Solana devnet is accessible
- Verify your MINT_AUTHORITY_SECRET_KEY is set in `.env`

## Features

### Dynamic Configuration
- ✅ No need to rebuild app when changing networks
- ✅ Settings persist across app restarts
- ✅ Easy to switch between emulator and device
- ✅ Connection test before saving

### Visual Feedback
- 🟢 Green = Successfully connected
- 🔴 Red = Connection failed
- ⚙️ Settings icon always visible on Course Map

### IP Suggestions
The app provides common IP ranges to help you:
- 192.168.1.x - Most common home routers
- 192.168.0.x - Alternative range
- 192.168.2.x - Another common range
- 10.0.2.2 - Android emulator (special address)

## Example Flow

```
1. Mac IP: 192.168.201.134
2. Start backend: npm start → Running on :3001
3. Open PlantGO → Course Map → Settings ⚙️
4. Enter: 192.168.201.134
5. Tap "Test & Save"
6. ✅ Connected successfully!
7. Go to Scanner → Scan plant → Mint NFT
8. 🎴 Real NFT created on Solana!
```

## Technical Details

### How It Works
1. Backend URL stored in SharedPreferences (persistent)
2. URL cached in memory for fast access
3. All API services use `BackendUrlProvider.getBackendUrl()`
4. Health check at `/health` validates connection
5. Settings screen at `backend_config_screen.dart`

### Files Modified
- `lib/services/backend_config_service.dart` - Configuration management
- `lib/services/backend_url_provider.dart` - URL caching
- `lib/screens/backend_config_screen.dart` - Settings UI
- `lib/screens/course_map_screen.dart` - Added settings button
- All NFT services updated to use dynamic URL

### Reset to Default
If something goes wrong, tap **"Reset to Default"** in settings.
This will restore the Android emulator address: `http://10.0.2.2:3001`

# 🎨 Backend Configuration UI Preview

## Settings Button Location
```
┌────────────────────────────────────────┐
│  ← Back    Course Map          ⚙️      │  ← Settings icon here
├────────────────────────────────────────┤
│                                        │
│  🪙 1,250 Coins    🍃 45 Leaves       │
│                                        │
│         [Level path continues...]      │
│                                        │
└────────────────────────────────────────┘
```

## Backend Configuration Screen

### Main View
```
┌────────────────────────────────────────┐
│  ← Backend Configuration               │
├────────────────────────────────────────┤
│                                        │
│  ╔══════════════════════════════════╗  │
│  ║ 📡 Current Backend               ║  │
│  ║                                  ║  │
│  ║  http://10.0.2.2:3001           ║  │
│  ╚══════════════════════════════════╝  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ ℹ️  How to connect               │  │
│  │                                  │  │
│  │ 1. Ensure same WiFi              │  │
│  │ 2. Find your IP address          │  │
│  │ 3. Enter IP below                │  │
│  │ 4. Tap "Test & Save"             │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Backend Server IP                     │
│  ┌──────────────────────────────────┐  │
│  │ 💻 192.168.201.134              │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ ✅ Connected successfully!       │  │ ← Success feedback
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    ✅ Test & Save                │  │ ← Primary button
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    🔄 Reset to Default           │  │ ← Secondary button
│  └──────────────────────────────────┘  │
│                                        │
│  Common IP Ranges                      │
│  ┌──────┐ ┌──────┐ ┌──────┐          │
│  │192.x │ │10.0. │ │192.  │  ...     │ ← Quick select
│  └──────┘ └──────┘ └──────┘          │
│                                        │
└────────────────────────────────────────┘
```

### Loading State
```
┌────────────────────────────────────────┐
│  Backend Server IP                     │
│  ┌──────────────────────────────────┐  │
│  │ 💻 192.168.1.100                │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    ⏳ Testing...                 │  │ ← Testing state
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### Error State
```
┌────────────────────────────────────────┐
│  Backend Server IP                     │
│  ┌──────────────────────────────────┐  │
│  │ 💻 192.168.1.100                │  │
│  └──────────────────────────────────┘  │
│  ⚠️ Please enter an IP address         │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ ❌ Connection failed              │  │ ← Error feedback
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │    ✅ Test & Save                │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

## NFT Minting Success Screen (Updated)

### Before (No Explorer Button)
```
┌────────────────────────────────────────┐
│  🎉 NFT Minted Successfully!           │
│                                        │
│  [Plant Image]                         │
│                                        │
│  Rose (Primordial Relic)               │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │        Continue                   │  │ ← Only one button
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### After (With Explorer Button)
```
┌────────────────────────────────────────┐
│  🎉 NFT Minted Successfully!           │
│                                        │
│  [Plant Image]                         │
│                                        │
│  Rose (Primordial Relic)               │
│                                        │
│  ┌─────────────┐  ┌─────────────────┐ │
│  │ 🔗 View on │  │   Continue      │ │ ← Two buttons
│  │  Explorer  │  │                 │ │
│  └─────────────┘  └─────────────────┘ │
└────────────────────────────────────────┘
```

## User Flow

### Initial Setup
```
1. User opens app
   ↓
2. Goes to Course Map
   ↓
3. Taps ⚙️ Settings icon
   ↓
4. Sees Backend Configuration screen
   ↓
5. Enters IP: 192.168.201.134
   ↓
6. Taps "Test & Save"
   ↓
7. App tests connection to http://192.168.201.134:3001/health
   ↓
8. Shows ✅ "Connected successfully!"
   ↓
9. URL saved to SharedPreferences
   ↓
10. Ready to mint NFTs!
```

### NFT Minting with Explorer
```
1. User scans plant
   ↓
2. Confirms identification
   ↓
3. Minting dialog shows progress:
   • Determining rarity...
   • Minting on blockchain...
   • Recording discovery...
   ↓
4. Success screen appears
   ↓
5. User taps "View on Explorer" 🔗
   ↓
6. Browser opens to:
   https://explorer.solana.com/tx/2pFuk...?cluster=devnet
   ↓
7. User sees transaction details on Solana Explorer
   ↓
8. Returns to app, taps "Continue"
```

## Color Scheme

### Success States
- **Primary Action**: `#14F195` (Mint green)
- **Success Background**: `rgba(76, 175, 80, 0.1)` (Light green)
- **Success Icon**: Green checkmark

### Error States
- **Error Background**: `rgba(244, 67, 54, 0.1)` (Light red)
- **Error Icon**: Red X or warning

### Info States
- **Info Background**: `rgba(33, 150, 243, 0.1)` (Light blue)
- **Info Icon**: Blue info circle

### Neutral
- **Background**: White
- **Secondary Text**: Gray
- **Borders**: Light gray

## Responsive Design

### Phone Sizes
- **Small (< 360px)**: Single column, stacked buttons
- **Medium (360-600px)**: Standard layout as shown
- **Large (> 600px)**: More padding, centered content

### Tablet Support
```
┌──────────────────────────────────────────────────┐
│                                                  │
│    ┌────────────────────────────────────┐       │
│    │  Backend Configuration             │       │
│    │                                    │       │
│    │  [All content centered]            │       │
│    │                                    │       │
│    │  Max width: 600px                  │       │
│    └────────────────────────────────────┘       │
│                                                  │
└──────────────────────────────────────────────────┘
```

## Accessibility

- ✅ Large touch targets (48x48dp minimum)
- ✅ High contrast text
- ✅ Clear error messages
- ✅ Loading indicators
- ✅ Icon + text labels
- ✅ Keyboard-friendly input

## Animation

### Button Press
```
Normal → Pressed → Released
  100%     95%       100%
```

### Success Feedback
```
Hidden → Fade In → Stay → Fade Out (after 3s)
  0%      100%      100%    0%
```

### Connection Test
```
Button: "Test & Save"
   ↓
Spinner: "Testing..."
   ↓
Result: "✅ Connected!" or "❌ Failed"
```

## Platform Differences

### Android
- Material Design ripple effects
- System back button support
- Chrome opens for Explorer links

### iOS
- Cupertino-style transitions
- Swipe-back gesture support
- Safari opens for Explorer links

## Edge Cases Handled

1. **Empty input**: Shows error message
2. **Invalid IP format**: Shows format hint
3. **Backend offline**: Shows connection failed
4. **Network timeout**: Shows timeout error
5. **No WiFi**: Shows no internet message
6. **Firewall blocking**: Suggests checking settings
7. **Wrong port**: Auto-adds :3001
8. **Missing protocol**: Auto-adds http://

## Technical Implementation

### State Management
```dart
- _isLoading: bool          // Show spinner
- _isTesting: bool          // Testing connection
- _connectionStatus: bool?   // null/true/false
- _errorMessage: String?    // Error text
- _currentUrl: String       // Saved URL
```

### Validation
```dart
1. Check if input is empty
2. Validate IP format (regex)
3. Format URL (add http:// + :3001)
4. Test connection (/health endpoint)
5. Show result (success/error)
6. Save if successful
```

This UI design provides a professional, user-friendly experience for configuring the backend connection! 🎨

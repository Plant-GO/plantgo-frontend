#!/bin/bash

echo "🔍 NFT Minting Diagnostic Check"
echo "=================================="
echo ""

# Check if backend is running
echo "1️⃣ Backend Status:"
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "   ✅ Backend is running"
    curl -s http://localhost:3001/health | python3 -m json.tool
else
    echo "   ❌ Backend is NOT running!"
fi
echo ""

# Check recent backend logs
echo "2️⃣ Recent Backend Activity:"
echo "   Last 20 lines of logs:"
echo "   ──────────────────────────────"
if pgrep -f "node src/index.js" > /dev/null; then
    echo "   (Backend process found - check your terminal for logs)"
else
    echo "   ⚠️  Backend process not found"
fi
echo ""

# Test mint endpoint (without actually minting)
echo "3️⃣ Testing Mint Endpoint Connectivity:"
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
echo "   Testing: http://$IP:3001/health"
if curl -s "http://$IP:3001/health" > /dev/null 2>&1; then
    echo "   ✅ Backend accessible from network IP"
else
    echo "   ❌ Backend NOT accessible from network"
    echo "   💡 This is why you're getting simulated mints!"
fi
echo ""

echo "4️⃣ Common Issues:"
echo "   ▪️ Seeing 'Aurora Seed' every time?"
echo "      → AI might be identifying each plant with unique names"
echo "      → Check if plant names are consistent"
echo ""
echo "   ▪️ Getting simulated mints (sim_xxxxx)?"
echo "      → Backend not reachable from device"
echo "      → Configure IP in app: Settings → $IP"
echo ""
echo "   ▪️ PayloadTooLargeError?"
echo "      → Backend needs restart after recent fix"
echo "      → Run: npm start (in backend folder)"
echo ""

# Check Firebase connectivity (if possible)
echo "5️⃣ Debug Tips:"
echo "   To see what plant names are stored:"
echo "   • Check Firebase Console → plant_counters collection"
echo "   • Look for duplicate/similar plant names"
echo ""
echo "   To see actual mint logs:"
echo "   • Run: flutter logs (in another terminal)"
echo "   • Look for: '🎴 Starting mint for...' messages"
echo ""

echo "✨ Done!"

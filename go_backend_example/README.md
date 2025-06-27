# PlantGo Go Backend with WebSockets

This is a Go backend example for the PlantGo scanner using native WebSockets.

## Prerequisites

- Go 1.21 or higher
- Git

## Setup

1. **Install dependencies:**
   ```bash
   cd go_backend_example
   go mod tidy
   ```

2. **Run the server:**
   ```bash
   go run main.go
   ```

3. **Server will start on port 8080:**
   - WebSocket endpoint: `ws://localhost:8080/ws`
   - Health check: `http://localhost:8080/health`

## API Endpoints

### WebSocket: `/ws`
Real-time communication for plant scanning.

**Client → Server Messages:**
```json
{
  "type": "video_frame",
  "frame": "base64_encoded_image_data",
  "sessionId": "unique_session_id", 
  "timestamp": 1234567890
}
```

**Server → Client Messages:**

Progress Update:
```json
{
  "type": "scanning_progress",
  "confidence": 0.3,
  "sessionId": "unique_session_id"
}
```

Plant Identification:
```json
{
  "type": "plant_identified",
  "plantName": "Monstera Deliciosa",
  "confidence": 0.95,
  "sessionId": "unique_session_id"
}
```

### REST: `/health`
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "PlantGo Scanner Backend",
  "version": "1.0.0"
}
```

## How It Works

1. **WebSocket Connection**: Flutter app connects to `/ws`
2. **Frame Streaming**: App sends camera frames as base64 encoded images
3. **Progressive Analysis**: Server sends progress updates every few frames
4. **Plant Identification**: After analyzing enough frames, server returns plant identification
5. **Real-time Communication**: All communication happens over the persistent WebSocket connection

## Mock Plant Database

The example includes a mock plant database with common houseplants:
- Monstera Deliciosa
- Peace Lily
- Snake Plant
- Fiddle Leaf Fig
- Pothos
- Rubber Plant
- ZZ Plant
- Philodendron
- Spider Plant
- Aloe Vera

## Integration with Real AI

To integrate with a real plant identification AI:

1. **Replace the `processPlantFrame` function** with your AI model calls
2. **Add image preprocessing** if needed (resize, normalize, etc.)
3. **Implement proper session management** for tracking scan sessions
4. **Add authentication** and rate limiting for production use
5. **Store results** in a database if needed

## Production Considerations

- **CORS**: Update CORS settings for production domains
- **Authentication**: Add JWT or similar authentication
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **Logging**: Add structured logging
- **Error Handling**: Improve error handling and recovery
- **Monitoring**: Add health checks and metrics
- **SSL/TLS**: Use HTTPS and WSS in production
- **Load Balancing**: Consider WebSocket-aware load balancers

## Testing

Test the WebSocket connection:
```bash
# Install wscat for testing
npm install -g wscat

# Connect to the WebSocket
wscat -c ws://localhost:8080/ws

# Send a test frame
{"type":"video_frame","frame":"test_data","sessionId":"test_session","timestamp":1234567890}
```

## Differences from Socket.io

Unlike Socket.io, native WebSockets:
- ✅ Work with any backend language (Go, Python, Java, etc.)
- ✅ Lower overhead and better performance
- ✅ Standard protocol, better compatibility
- ❌ No automatic reconnection (implement manually if needed)
- ❌ No rooms/namespaces (implement manually if needed)
- ❌ Manual message routing (implement message types)

This example provides the same functionality as the Socket.io version but with native WebSockets for better Go integration.

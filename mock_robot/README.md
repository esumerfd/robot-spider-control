# Mock Hexapod Robot Server

A Python-based mock server that simulates a hexapod robot for testing the Flutter control app without physical hardware.

## Features

- **WebSocket Server** on port 8080
- **mDNS Advertisement** as `robot-spider.local`
- **Command Logging** with color-coded console output
- **Connection Tracking** for multiple clients
- **Optional Acknowledgments** for testing bidirectional communication

## Supported Commands

The server recognizes these plain text commands:

- `init` - Initialize connection
- `forward` - Move forward
- `backward` - Move backward
- `left` - Turn left
- `right` - Turn right

## Installation

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

### Quick Setup (Recommended - Using Makefile)

From the project root directory:

```bash
# One-time setup
make mock-setup

# Start the server
make mock-robot-run

# Or with acknowledgments
make mock-robot-run-acks
```

The Makefile targets automatically:
- Validate the environment is set up
- Activate the virtual environment
- Run the server with proper settings

### Manual Setup

1. Navigate to the mock_robot directory:
   ```bash
   cd mock_robot
   ```

2. Create a virtual environment (recommended):
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   # or
   venv\Scripts\activate     # On Windows
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

### Using Makefile (Recommended)

From the project root directory:

```bash
# Start the server (validates environment first)
make mock-robot-run

# Start with acknowledgments enabled
make mock-robot-run-acks
```

If the environment isn't set up, you'll get a clear error message:
```
❌ Error: Mock server environment not set up

Please run: make mock-setup
```

### Manual Usage

Start the server with default settings (no acknowledgments):

```bash
cd mock_robot
source venv/bin/activate
python3 mock_robot_server.py
```

With acknowledgments enabled:

```bash
cd mock_robot
source venv/bin/activate
python3 mock_robot_server.py --acks
```

When acknowledgments are enabled, the server will respond with `OK:<command>` for valid commands or `ERROR:<message>` for invalid ones.

### Expected Output

When running, you'll see:

```
============================================================
Mock Hexapod Robot Server
============================================================
[12:34:56.789] INFO: Local IP: 192.168.1.100
[12:34:56.790] INFO: WebSocket Port: 8080
[12:34:56.791] INFO: mDNS Hostname: robot-spider.local
[12:34:56.792] INFO: Send Acknowledgments: False
============================================================

[12:34:56.793] INFO: mDNS service registered as 'robot-spider.local'
[12:34:56.794] INFO: WebSocket server starting...
[12:34:56.795] INFO: Server is running! Waiting for connections...
[12:34:56.796] INFO: Press Ctrl+C to stop
```

When clients connect and send commands:

```
[12:35:10.123] INFO: Client connected: 192.168.1.50:54321
[12:35:10.124] INFO: Total connected clients: 1
[12:35:10.456] COMMAND: INIT from 192.168.1.50:54321
[12:35:11.789] COMMAND: FORWARD from 192.168.1.50:54321
[12:35:12.234] COMMAND: LEFT from 192.168.1.50:54321
```

### Stopping the Server

Press `Ctrl+C` to gracefully shut down:

```
[12:40:00.000] INFO: Shutting down server...
[12:40:00.001] INFO: mDNS service unregistered
[12:40:00.002] INFO: Total commands processed: 42
[12:40:00.003] INFO: Server stopped
```

## Testing with the Flutter App

1. Start the mock server on your development machine:
   ```bash
   make mock-robot-run
   ```
2. Ensure your mobile device/emulator is on the same network
3. Launch the Flutter app
4. The app should auto-discover the robot via mDNS
5. Connect and test the control buttons

The mock server will display all received commands in real-time with color coding:

- **INIT** - Cyan
- **FORWARD** - Green
- **BACKWARD** - Yellow
- **LEFT** - Magenta
- **RIGHT** - Blue

## Network Configuration

### Same Machine Testing

If running the Flutter app on an Android emulator on the same machine:

- The server will bind to `0.0.0.0` (all interfaces)
- Use `10.0.2.2` from the Android emulator to reach the host machine
- Or use the actual IP address displayed by the server

### Different Devices

1. Note the IP address displayed when the server starts
2. Ensure both devices are on the same WiFi network
3. Verify no firewall is blocking port 8080
4. The app should discover the server via mDNS automatically

### Manual Connection

If mDNS discovery doesn't work, you can manually connect using:

```
ws://<server-ip>:8080
```

Replace `<server-ip>` with the IP address shown in the server output.

## Troubleshooting

### mDNS Not Working

- **macOS**: mDNS (Bonjour) should work out of the box
- **Linux**: Install Avahi daemon: `sudo apt-get install avahi-daemon`
- **Windows**: Install Bonjour Print Services or use manual IP connection
- **Firewall**: Ensure UDP port 5353 is allowed for mDNS

### Connection Refused

- Check that port 8080 is not in use by another application
- Verify firewall settings allow incoming connections on port 8080
- Ensure devices are on the same network

### Commands Not Appearing

- Check that the Flutter app is successfully connected
- Verify the WebSocket connection in the app's UI
- Look for any error messages in the server console

## Development Notes

### Adding New Commands

To add support for new commands:

1. Add the command to `VALID_COMMANDS` set
2. Add color mapping to `COMMAND_COLORS` dict (optional)
3. The command will automatically be recognized and logged

### Simulating Robot Behavior

The current implementation just logs commands. To simulate actual robot behavior:

- Add delays to simulate movement duration
- Send status updates back to the client
- Track robot state (position, orientation, etc.)
- Simulate battery drain or sensor readings

### Protocol Extensions

The server supports sending messages back to clients when `--acks` is enabled. This can be extended to:

- Send telemetry data (battery, sensors)
- Report movement completion
- Send error conditions
- Stream real-time status

## Architecture

```
┌─────────────────────────┐
│    Flutter Control App  │
│                         │
│   mDNS Discovery        │
│        ↓                │
│   WebSocket Client      │
└────────┬────────────────┘
         │ ws://robot-spider.local:8080
         │ Commands: "init", "forward", etc.
         ↓
┌─────────────────────────┐
│  Mock Robot Server      │
│  (mock_robot_server.py) │
│                         │
│  ┌──────────────────┐   │
│  │ mDNS Service     │   │
│  │ Advertiser       │   │
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ WebSocket        │   │
│  │ Server :8080     │   │
│  └──────────────────┘   │
│                         │
│  ┌──────────────────┐   │
│  │ Command Parser   │   │
│  │ & Logger         │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

## Dependencies

- **websockets** (12.0+) - WebSocket server implementation
- **zeroconf** (0.132.0+) - mDNS service advertisement
- **colorama** (0.4.6+) - Cross-platform colored terminal output

## License

This mock server is part of the robot-spider-control project.

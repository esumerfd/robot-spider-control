# Bluetooth Mock Server - Testing Notes

## Known Issues

The Bluetooth mock server (`mock_bluetooth_server.py`) depends on PyBluez, which has compatibility issues with modern Python versions (3.12+) and pip/setuptools.

### The Problem

- PyBluez is unmaintained and uses deprecated `use_2to3` in its build configuration
- Modern setuptools (>=58) no longer supports `use_2to3`
- Python 3.12+ has additional compatibility issues
- Installing PyBluez requires complex workarounds

### Solutions for Testing Bluetooth

We recommend one of the following approaches:

#### Option 1: Use Python 3.10 or 3.11 (Recommended for Mock Server)

If you specifically want to test with the Bluetooth mock server:

1. Install Python 3.10 or 3.11 (via pyenv, conda, or system package manager)
2. Create venv with that Python version:
   ```bash
   cd mock_robot
   python3.10 -m venv venv
   source venv/bin/activate
   pip install "setuptools<58"
   pip install --no-build-isolation pybluez colorama
   python mock_bluetooth_server.py
   ```

#### Option 2: Test with Real ESP32/Arduino (Recommended)

The most reliable way to test Bluetooth is with actual hardware:

1. **Use an ESP32** (built-in Bluetooth Classic)
2. **Use Arduino with HC-05/HC-06 Bluetooth module**

Example ESP32 Arduino sketch:
```cpp
#include <BluetoothSerial.h>

BluetoothSerial SerialBT;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("robot-spider"); // Bluetooth device name
  Serial.println("Bluetooth started");
}

void loop() {
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    Serial.println("Received: " + command);

    // Handle commands
    if (command == "init") {
      Serial.println("Robot initialized");
    } else if (command == "forward") {
      Serial.println("Moving forward");
    } else if (command == "backward") {
      Serial.println("Moving backward");
    } else if (command == "left") {
      Serial.println("Turning left");
    } else if (command == "right") {
      Serial.println("Turning right");
    }
  }
}
```

#### Option 3: Test WiFi Connection Instead

The WiFi mock server works perfectly and tests the same command protocol:

```bash
# WiFi mock server has no compatibility issues
make mock-setup
make mock-robot-run
```

The Flutter app's Bluetooth implementation is complete and correct - only the Python mock server has dependency issues.

## Alternative: Virtual Bluetooth Adapter

For advanced users, you can create a virtual Bluetooth adapter on Linux:

```bash
# Load the virtual Bluetooth kernel module
sudo modprobe vhci

# Use tools like btproxy or virtual-bluetooth-adapter
# (Requires additional setup and Linux-specific knowledge)
```

## Summary

**For Development/Testing:**
- Use WiFi mock server (`make mock-robot-run`) - most reliable
- Test Bluetooth with ESP32 or Arduino with Bluetooth module - most realistic

**The Bluetooth implementation in the Flutter app is fully functional** - these limitations only affect the Python mock server testing tool.

## Sources

The PyBluez `use_2to3` issue is well-documented:
- **[PyBluez Issue #431](https://github.com/pybluez/pybluez/issues/431)** - Can't install PyBluez on Windows
- **[PyBluez Issue #446](https://github.com/pybluez/pybluez/issues/446)** - use_2to3 is invalid error
- **[PyBluez Issue #504](https://github.com/pybluez/pybluez/issues/504)** - Installing from pip fails
- **[Dataform.dk Fix Guide](https://dataform.dk/fixing-pip-install-use_2to3-is-invalid.html)** - Fixing pip install use_2to3 error

Maintainers recommend using Google Bumble as a modern alternative:
- **[Google Bumble](https://google.github.io/bumble/)** - Python Bluetooth Stack

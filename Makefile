# Hexapod Control - Makefile
# Android app build and run targets

.PHONY: help build run devices test clean install mock-setup mock-robot-run mock-robot-run-acks mock-test-mdns

# Default target
help:
	@echo "Hexapod Control - Available targets:"
	@echo ""
	@echo "  make build       - Build the Android APK"
	@echo "  make run         - Build, install, and run app on emulator"
	@echo "  make devices     - List connected Android devices/emulators"
	@echo "  make test        - Run Flutter tests"
	@echo "  make install     - Install APK on connected device"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make emulator    - Start Android emulator"
	@echo ""
	@echo "Mock Robot Server (WiFi):"
	@echo "  make mock-setup        - Setup Python environment for mock server (one-time)"
	@echo "  make mock-robot-run    - Start mock WiFi robot server"
	@echo "  make mock-robot-run-acks - Start mock WiFi robot server with acknowledgments"
	@echo "  make mock-test-mdns    - Test if robot-spider.local is resolvable via mDNS"
	@echo ""
	@echo "Mock Robot Server (Bluetooth):"
	@echo "  make bt-server-setup   - Setup Bluetooth mock server dependencies"
	@echo "  make bt-server-run     - Start mock Bluetooth robot server"
	@echo "  make bt-server-run-acks - Start mock Bluetooth robot server with acknowledgments"
	@echo ""

# Build the Android APK using system Gradle
build:
	@echo "Building Hexapod Control APK..."
	cd android && /usr/local/bin/gradle assembleDebug
	@echo "✓ Build complete: build/app/outputs/flutter-apk/app-debug.apk"

# Install APK on connected device/emulator
install: build
	@echo "Installing app on device..."
	/Users/esumerfd/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk
	@echo "✓ App installed"

# Build, install, and launch app
run: install
	@echo "Launching Hexapod Control..."
	/Users/esumerfd/Library/Android/sdk/platform-tools/adb shell am start -n com.hexapod.hexapod_control/.MainActivity
	@echo "✓ App is running!"

# List connected devices and emulators
devices:
	@echo "Connected Android devices:"
	@/Users/esumerfd/Library/Android/sdk/platform-tools/adb devices
	@echo ""
	@echo "Flutter devices:"
	@flutter devices

# Run Flutter tests
test:
	@echo "Running Flutter tests..."
	flutter test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd android && /usr/local/bin/gradle clean
	flutter clean
	@echo "✓ Clean complete"

# Start Android emulator
emulator:
	@echo "Starting Android emulator..."
	/Users/esumerfd/Library/Android/sdk/emulator/emulator -avd Pixel_API_34 -no-snapshot-load &
	@echo "Waiting for emulator to boot..."
	@/Users/esumerfd/Library/Android/sdk/platform-tools/adb wait-for-device
	@echo "✓ Emulator ready"

# Development helpers
.PHONY: logs analyze format

# View app logs
logs:
	@echo "Streaming app logs (Ctrl+C to stop)..."
	/Users/esumerfd/Library/Android/sdk/platform-tools/adb logcat | grep -i hexapod

# Run Flutter analyzer
analyze:
	@echo "Running Flutter analyzer..."
	flutter analyze

# Format Dart code
format:
	@echo "Formatting Dart code..."
	flutter format lib/

# Mock Robot Server targets
.PHONY: mock-setup mock-robot-run mock-robot-run-acks mock-check-env

# Check if mock server environment is set up
mock-check-env:
	@if [ ! -d "mock_robot/venv" ]; then \
		echo "❌ Error: Mock server environment not set up"; \
		echo ""; \
		echo "Please run: make mock-setup"; \
		echo ""; \
		exit 1; \
	fi
	@if ! mock_robot/venv/bin/python3 -c "import websockets, zeroconf, colorama" 2>/dev/null; then \
		echo "❌ Error: Mock server dependencies not installed"; \
		echo ""; \
		echo "Please run: make mock-setup"; \
		echo ""; \
		exit 1; \
	fi

# Setup Python environment for mock server (one-time)
mock-setup:
	@echo "Setting up mock robot server environment..."
	@cd mock_robot && python3 -m venv venv
	@cd mock_robot && . venv/bin/activate && pip install -r requirements.txt
	@echo "✓ Mock server environment ready"
	@echo ""
	@echo "To start the mock server, run:"
	@echo "  make mock-robot-run"

# Start mock robot server
mock-robot-run: mock-check-env
	@echo "Starting mock robot server..."
	@echo "Press Ctrl+C to stop"
	@echo ""
	@cd mock_robot && . venv/bin/activate && python3 mock_robot_server.py

# Start mock robot server with acknowledgments
mock-robot-run-acks: mock-check-env
	@echo "Starting mock robot server with acknowledgments..."
	@echo "Press Ctrl+C to stop"
	@echo ""
	@cd mock_robot && . venv/bin/activate && python3 mock_robot_server.py --acks

# Test mDNS resolution
mock-test-mdns: mock-check-env
	@echo "Testing mDNS resolution for robot-spider.local..."
	@echo ""
	@cd mock_robot && . venv/bin/activate && python3 test_mdns.py

# Bluetooth Mock Server targets
.PHONY: bt-server-setup bt-server-run bt-server-run-acks bt-check-env

# Check if Bluetooth server environment is set up
bt-check-env:
	@if [ ! -d "mock_robot/venv" ]; then \
		echo "❌ Error: Mock server environment not set up"; \
		echo ""; \
		echo "Please run: make bt-server-setup"; \
		echo ""; \
		exit 1; \
	fi
	@if ! mock_robot/venv/bin/python3 -c "import bluetooth, colorama" 2>/dev/null; then \
		echo "❌ Error: Bluetooth server dependencies not installed"; \
		echo ""; \
		echo "Please run: make bt-server-setup"; \
		echo ""; \
		exit 1; \
	fi

# Setup Bluetooth mock server dependencies
bt-server-setup:
	@echo "Setting up Bluetooth mock server environment..."
	@if [ ! -d "mock_robot/venv" ]; then \
		echo "Creating Python virtual environment..."; \
		cd mock_robot && python3 -m venv venv; \
	fi
	@echo "Installing Bluetooth dependencies..."
	@cd mock_robot && . venv/bin/activate && pip install -r requirements-bluetooth.txt
	@echo "✓ Bluetooth mock server environment ready"
	@echo ""
	@echo "⚠️  Note: On macOS, you may need to install PyObjC if you encounter Bluetooth errors:"
	@echo "  cd mock_robot && . venv/bin/activate && pip install pyobjc"
	@echo ""
	@echo "To start the Bluetooth mock server, run:"
	@echo "  make bt-server-run"

# Start Bluetooth mock robot server
bt-server-run: bt-check-env
	@echo "Starting Bluetooth mock robot server..."
	@echo "Make sure Bluetooth is enabled on your system"
	@echo "Press Ctrl+C to stop"
	@echo ""
	@cd mock_robot && . venv/bin/activate && python3 mock_bluetooth_server.py

# Start Bluetooth mock robot server with acknowledgments
bt-server-run-acks: bt-check-env
	@echo "Starting Bluetooth mock robot server with acknowledgments..."
	@echo "Make sure Bluetooth is enabled on your system"
	@echo "Press Ctrl+C to stop"
	@echo ""
	@cd mock_robot && . venv/bin/activate && python3 mock_bluetooth_server.py --acks

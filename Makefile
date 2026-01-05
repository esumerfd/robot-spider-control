# Hexapod Control - Makefile
# Android app build and run targets

.PHONY: help build run devices test clean install

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

ios-release:
	flutter clean
	flutter pub get
	cd ios && rm -f Podfile.lock && rm -rf Pods && pod install --repo-update
	flutter build ios --release --config-only
	open ios/Runner.xcworkspace

refresh:
	flutter clean
	flutter pub get
	rm -rf ~/Library/Developer/Xcode/DerivedData

wireless-android:
	@echo "Checking for connected USB device..."
	@if ! adb devices | grep -w "device" | grep -v "List"; then \
		echo "❌ No USB device found. Please connect via USB."; \
		exit 1; \
	fi
	@echo "Restarting ADB in TCP mode..."
	@adb tcpip 5555
	@echo "Waiting for device to reappear..."
	@sleep 2
	@adb devices
	@echo "Fetching device IP address..."
	@IP=$$(adb shell ip -f inet addr show wlan0 | grep -oP 'inet \K[\d.]+' | head -n 1); \
	if [ -z "$$IP" ]; then echo "❌ Failed to get IP. Is device on Wi-Fi?"; exit 1; fi; \
	echo "Device IP is $$IP"; \
	echo "Connecting wirelessly..."; \
	adb connect $$IP:5555 && echo "✅ Connected to $$IP:5555"

wireless-android-from-ios:
	@echo "Checking for connected USB device..."
	@if ! adb devices | grep -w "device" | grep -v "List"; then \
		echo "❌ No USB device found. Please connect via USB."; \
		exit 1; \
	fi
	@echo "Restarting ADB in TCP mode..."
	@adb tcpip 5555
	@echo "Waiting for device to reappear..."
	@sleep 2
	@adb devices
	@echo "Fetching device IP address..."
	@IP=$$(adb shell ip -f inet addr show wlan0 | sed -nE 's/.*inet ([0-9.]+).*/\1/p' | head -n 1); \
	if [ -z "$$IP" ]; then echo "❌ Failed to get IP. Is device on Wi-Fi?"; exit 1; fi; \
	echo "Device IP is $$IP"; \
	echo "Connecting wirelessly..."; \
	adb connect $$IP:5555 && echo "✅ Connected to $$IP:5555"



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
	@adb tcpip 5555
	@IP=$$(adb shell ip route | awk '{print $$9}'); \
	if adb devices | grep -q "$$IP:5555"; then \
		echo "Already connected to $$IP"; \
	else \
		adb connect $$IP && echo "Connected to $$IP"; \
	fi
	@adb devices

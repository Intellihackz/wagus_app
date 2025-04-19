ios-release:
	flutter clean
	flutter pub get
	cd ios && rm -f Podfile.lock && rm -rf Pods && pod install --repo-update
	flutter build ios --release --config-only
	open ios/Runner.xcworkspace

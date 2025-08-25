@echo off
echo 🕐 Time Capsule - App Icon Update Script
echo ========================================
echo.

echo Step 1: Getting dependencies...
flutter pub get

echo.
echo Step 2: Generating app icons...
flutter pub run flutter_launcher_icons:main

echo.
echo Step 3: Cleaning and rebuilding...
flutter clean
flutter pub get

echo.
echo ✅ App icon setup complete!
echo.
echo Your app now shows as "Time Capsule" with your custom logo.
echo To build APK: flutter build apk --release
echo.
pause
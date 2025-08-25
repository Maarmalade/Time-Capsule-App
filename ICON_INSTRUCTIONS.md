# 🕐 Time Capsule App Icon Setup Guide

## Quick Setup (3 Steps)

### Step 1: Save Your Logo
1. Save the golden clock/capsule logo image you provided as: `assets/images/app_logo.png`
2. Make sure it's at least 1024x1024 pixels for best quality

### Step 2: Generate Icons Automatically

#### Option A: Using Online Tool (Easiest)
1. Go to https://appicon.co/ or https://makeappicon.com/
2. Upload your `assets/images/app_logo.png`
3. Download the Android icon pack
4. Extract and copy the files to the respective folders:
   - Copy `mipmap-mdpi/ic_launcher.png` to `android/app/src/main/res/mipmap-mdpi/`
   - Copy `mipmap-hdpi/ic_launcher.png` to `android/app/src/main/res/mipmap-hdpi/`
   - Copy `mipmap-xhdpi/ic_launcher.png` to `android/app/src/main/res/mipmap-xhdpi/`
   - Copy `mipmap-xxhdpi/ic_launcher.png` to `android/app/src/main/res/mipmap-xxhdpi/`
   - Copy `mipmap-xxxhdpi/ic_launcher.png` to `android/app/src/main/res/mipmap-xxxhdpi/`

#### Option B: Using Flutter Launcher Icons Package
1. Add to pubspec.yaml under dev_dependencies:
   ```yaml
   flutter_launcher_icons: ^0.13.1
   ```

2. Add configuration to pubspec.yaml:
   ```yaml
   flutter_icons:
     android: true
     ios: true
     image_path: "assets/images/app_logo.png"
     ```

3. Run commands:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

### Step 3: Rebuild App
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## What's Already Configured ✅

- ✅ **App Name**: Changed from "time_capsule" to "Time Capsule"
- ✅ **Android**: AndroidManifest.xml updated
- ✅ **iOS**: Info.plist updated  
- ✅ **Assets**: Folder structure created
- ✅ **Description**: Updated in pubspec.yaml

## Your Logo Design
The golden clock/capsule design you provided is perfect for a Time Capsule app! It represents:
- ⏰ Time element (clock face)
- 💊 Capsule shape (memory storage)
- 🏆 Premium golden color
- 🎯 Clean, minimalist design

## Result
After following these steps, your app will:
- Display as "Time Capsule" on device home screens
- Show your custom golden clock logo as the app icon
- Look professional and branded

## Need Help?
If you encounter any issues, the Python script in `scripts/generate_icons.py` can also help generate the icons if you have Python and Pillow installed.
# Time Capsule App Icon Setup

## Steps to Update App Icon

### 1. Save Your Logo Image
- Save the provided logo image as `assets/images/app_logo.png`
- Make sure it's a high-resolution PNG (at least 512x512 pixels)

### 2. Generate Android Icons

#### Option A: Using Python Script (Recommended)
```bash
# Install Pillow if you haven't already
pip install Pillow

# Run the icon generation script
cd scripts
python generate_icons.py
```

#### Option B: Manual Creation
If you don't have Python, you can manually create the icons:

1. Resize your logo to these sizes and save in the respective folders:
   - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
   - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
   - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
   - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
   - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### 3. Rebuild the App
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## What's Already Done ✅

- ✅ App display name changed to "Time Capsule" in AndroidManifest.xml
- ✅ pubspec.yaml updated with proper description
- ✅ Assets folder structure created
- ✅ Icon generation scripts created

## Current App Name
The app will now display as "Time Capsule" instead of "time_capsule" on Android devices.
#!/usr/bin/env python3
"""
Script to generate Android app icons from a source image.
Requires PIL (Pillow) library: pip install Pillow
"""

from PIL import Image
import os

def generate_android_icons(source_path, output_dir):
    """Generate Android app icons in different sizes"""
    
    # Android icon sizes
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    # Load source image
    try:
        source_img = Image.open(source_path)
        print(f"Loaded source image: {source_path}")
        
        # Convert to RGBA if needed
        if source_img.mode != 'RGBA':
            source_img = source_img.convert('RGBA')
            
        for folder, size in sizes.items():
            # Create output directory if it doesn't exist
            folder_path = os.path.join(output_dir, folder)
            os.makedirs(folder_path, exist_ok=True)
            
            # Resize image
            resized_img = source_img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save as PNG
            output_path = os.path.join(folder_path, 'ic_launcher.png')
            resized_img.save(output_path, 'PNG')
            print(f"Generated: {output_path} ({size}x{size})")
            
        print("✅ Android icons generated successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("Make sure you have Pillow installed: pip install Pillow")

if __name__ == "__main__":
    source_image = "assets/images/app_logo.png"
    android_res_dir = "android/app/src/main/res"
    
    if os.path.exists(source_image):
        generate_android_icons(source_image, android_res_dir)
    else:
        print(f"❌ Source image not found: {source_image}")
        print("Please save your logo image as assets/images/app_logo.png")
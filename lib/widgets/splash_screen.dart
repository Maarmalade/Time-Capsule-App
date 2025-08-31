import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';

/// Splash screen widget displayed during authentication state initialization
/// 
/// This screen is shown while the app determines the user's authentication
/// status and decides which route to navigate to initially.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.access_time,
                  size: 64,
                  color: AppColors.textOnAccent,
                  semanticLabel: 'Time Capsule app icon',
                ),
              ),
              
              SizedBox(height: AppSpacing.xl),
              
              // App name
              Text(
                'Time Capsule',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                semanticsLabel: 'Time Capsule application',
              ),
              
              SizedBox(height: AppSpacing.md),
              
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                ),
              ),
              
              SizedBox(height: AppSpacing.md),
              
              // Loading text
              Text(
                'Loading...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                semanticsLabel: 'Application is loading',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
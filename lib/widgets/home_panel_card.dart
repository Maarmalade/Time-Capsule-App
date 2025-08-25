import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_spacing.dart';

class HomePanelCard extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final ImageProvider? image;

  const HomePanelCard({
    super.key,
    required this.text,
    required this.onTap,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: AppSpacing.cardRadius,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: AppSpacing.cardPadding,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Image(
                      image: image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (text.isNotEmpty)
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
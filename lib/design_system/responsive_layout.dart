import 'package:flutter/material.dart';
import 'app_responsive.dart';
import 'app_spacing.dart';

/// ResponsiveLayout provides common responsive layout patterns
/// that adapt to different screen sizes automatically
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);
        final contentWidth = maxWidth ?? 
            AppResponsive.getResponsiveContentWidth(screenWidth);

        Widget content = Container(
          width: contentWidth,
          padding: responsivePadding,
          child: child,
        );

        if (centerContent) {
          content = Center(child: content);
        }

        return content;
      },
    );
  }
}

/// ResponsiveContainer provides a container that adapts its properties
/// based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;
  final EdgeInsets? mobileMargin;
  final EdgeInsets? tabletMargin;
  final EdgeInsets? desktopMargin;
  final Color? backgroundColor;
  final BorderRadius? mobileBorderRadius;
  final BorderRadius? tabletBorderRadius;
  final BorderRadius? desktopBorderRadius;
  final double? width;
  final double? height;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
    this.mobileMargin,
    this.tabletMargin,
    this.desktopMargin,
    this.backgroundColor,
    this.mobileBorderRadius,
    this.tabletBorderRadius,
    this.desktopBorderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        final responsivePadding = AppResponsive.getResponsivePadding(
          screenWidth,
          mobilePadding: mobilePadding,
          tabletPadding: tabletPadding,
          desktopPadding: desktopPadding,
        );

        final responsiveMargin = AppResponsive.getResponsiveMargin(
          screenWidth,
          mobileMargin: mobileMargin,
          tabletMargin: tabletMargin,
          desktopMargin: desktopMargin,
        );

        final responsiveBorderRadius = AppResponsive.getResponsiveBorderRadius(
          screenWidth,
          mobileBorderRadius: mobileBorderRadius,
          tabletBorderRadius: tabletBorderRadius,
          desktopBorderRadius: desktopBorderRadius,
        );

        return Container(
          width: width,
          height: height,
          margin: responsiveMargin,
          padding: responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: responsiveBorderRadius,
          ),
          child: child,
        );
      },
    );
  }
}

/// ResponsiveRow provides a row that can stack vertically on smaller screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? spacing;
  final bool stackOnMobile;
  final bool stackOnTablet;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing,
    this.stackOnMobile = true,
    this.stackOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = AppResponsive.getDeviceType(screenWidth);
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);

        final shouldStack = (deviceType == DeviceType.mobile && stackOnMobile) ||
                           (deviceType == DeviceType.tablet && stackOnTablet);

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((child) => [child, SizedBox(height: responsiveSpacing)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }

        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children
              .expand((child) => [child, SizedBox(width: responsiveSpacing)])
              .take(children.length * 2 - 1)
              .toList(),
        );
      },
    );
  }
}

/// ResponsiveColumn provides a column that can become horizontal on larger screens
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double? spacing;
  final bool rowOnTablet;
  final bool rowOnDesktop;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing,
    this.rowOnTablet = false,
    this.rowOnDesktop = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = AppResponsive.getDeviceType(screenWidth);
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);

        final shouldUseRow = (deviceType == DeviceType.tablet && rowOnTablet) ||
                            (deviceType == DeviceType.desktop && rowOnDesktop);

        if (shouldUseRow) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children
                .expand((child) => [child, SizedBox(width: responsiveSpacing)])
                .take(children.length * 2 - 1)
                .toList(),
          );
        }

        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: children
              .expand((child) => [child, SizedBox(height: responsiveSpacing)])
              .take(children.length * 2 - 1)
              .toList(),
        );
      },
    );
  }
}

/// ResponsiveSideBySide provides a layout that shows content side by side
/// on larger screens and stacked on smaller screens
class ResponsiveSideBySide extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double? spacing;
  final double leftFlex;
  final double rightFlex;
  final bool stackOnMobile;
  final bool stackOnTablet;

  const ResponsiveSideBySide({
    super.key,
    required this.left,
    required this.right,
    this.spacing,
    this.leftFlex = 1.0,
    this.rightFlex = 1.0,
    this.stackOnMobile = true,
    this.stackOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = AppResponsive.getDeviceType(screenWidth);
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);

        final shouldStack = (deviceType == DeviceType.mobile && stackOnMobile) ||
                           (deviceType == DeviceType.tablet && stackOnTablet);

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: responsiveSpacing),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: leftFlex.round(),
              child: left,
            ),
            SizedBox(width: responsiveSpacing),
            Expanded(
              flex: rightFlex.round(),
              child: right,
            ),
          ],
        );
      },
    );
  }
}

/// ResponsiveCard provides a card that adapts its styling based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);
        final responsiveMargin = margin ?? 
            AppResponsive.getResponsiveMargin(screenWidth);
        final responsiveBorderRadius = borderRadius ?? 
            AppResponsive.getResponsiveBorderRadius(screenWidth);

        return Container(
          margin: responsiveMargin,
          child: Card(
            elevation: elevation ?? 2.0,
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: responsiveBorderRadius,
            ),
            child: Padding(
              padding: responsivePadding,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// ResponsiveDialog provides a dialog that adapts its size based on screen size
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final dialogWidth = AppResponsive.getResponsiveDialogWidth(screenWidth);
        final responsivePadding = contentPadding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        return Dialog(
          child: Container(
            width: dialogWidth,
            padding: responsivePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
                child,
                if (actions != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!
                        .expand((action) => [action, SizedBox(width: AppSpacing.sm)])
                        .take(actions!.length * 2 - 1)
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
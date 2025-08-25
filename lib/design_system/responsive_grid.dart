import 'package:flutter/material.dart';
import 'app_responsive.dart';
import 'app_spacing.dart';

/// ResponsiveGrid provides adaptive grid layouts that automatically
/// adjust column counts and spacing based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? spacing;
  final double? runSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columns = AppResponsive.getGridColumns(
          screenWidth,
          mobileColumns: mobileColumns ?? 1,
          tabletColumns: tabletColumns ?? 2,
          desktopColumns: desktopColumns ?? 3,
        );

        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);
        final responsiveRunSpacing = runSpacing ?? responsiveSpacing;
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        return Padding(
          padding: responsivePadding,
          child: GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: responsiveSpacing,
              mainAxisSpacing: responsiveRunSpacing,
              childAspectRatio: childAspectRatio ?? 1.0,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }
}

/// ResponsiveMemoryGrid specifically designed for memory album layouts
/// with optimized aspect ratios and column counts
class ResponsiveMemoryGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveMemoryGrid({
    super.key,
    required this.children,
    this.spacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columns = AppResponsive.getMemoryGridColumns(screenWidth);
        
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        return Padding(
          padding: responsivePadding,
          child: GridView.builder(
            shrinkWrap: shrinkWrap,
            physics: physics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: responsiveSpacing,
              mainAxisSpacing: responsiveSpacing,
              childAspectRatio: 1.0, // Square aspect ratio for memories
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }
}

/// ResponsiveStaggeredGrid for layouts with varying item heights
class ResponsiveStaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveStaggeredGrid({
    super.key,
    required this.children,
    this.spacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final columns = AppResponsive.getGridColumns(screenWidth);
        
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        // For staggered grid, we'll use a custom layout
        return Padding(
          padding: responsivePadding,
          child: _StaggeredGridLayout(
            columns: columns,
            spacing: responsiveSpacing,
            shrinkWrap: shrinkWrap,
            physics: physics,
            children: children,
          ),
        );
      },
    );
  }
}

/// Custom staggered grid layout implementation
class _StaggeredGridLayout extends StatelessWidget {
  final int columns;
  final double spacing;
  final List<Widget> children;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const _StaggeredGridLayout({
    required this.columns,
    required this.spacing,
    required this.children,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        return SingleChildScrollView(
          physics: physics,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columns, (columnIndex) {
              final columnChildren = <Widget>[];
              
              // Distribute children across columns
              for (int i = columnIndex; i < children.length; i += columns) {
                columnChildren.add(children[i]);
                if (i + columns < children.length) {
                  columnChildren.add(SizedBox(height: spacing));
                }
              }
              
              return SizedBox(
                width: columnWidth,
                child: Column(
                  children: columnChildren,
                ),
              );
            }).expand((column) => [
              column,
              if (columns > 1) SizedBox(width: spacing),
            ]).take(columns * 2 - 1).toList(),
          ),
        );
      },
    );
  }
}

/// ResponsiveList provides adaptive list layouts with responsive item heights
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const ResponsiveList({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        return Padding(
          padding: responsivePadding,
          child: ListView.separated(
            shrinkWrap: shrinkWrap,
            physics: physics,
            scrollDirection: scrollDirection,
            itemCount: children.length,
            separatorBuilder: (context, index) => scrollDirection == Axis.vertical
                ? SizedBox(height: responsiveSpacing)
                : SizedBox(width: responsiveSpacing),
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }
}

/// ResponsiveWrap provides adaptive wrap layouts that adjust spacing
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final double? runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final Axis direction;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.runSpacing,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveSpacing = spacing ?? 
            AppResponsive.getResponsiveSpacing(screenWidth);
        final responsiveRunSpacing = runSpacing ?? responsiveSpacing;
        final responsivePadding = padding ?? 
            AppResponsive.getResponsivePadding(screenWidth);

        return Padding(
          padding: responsivePadding,
          child: Wrap(
            direction: direction,
            alignment: alignment,
            crossAxisAlignment: crossAxisAlignment,
            spacing: responsiveSpacing,
            runSpacing: responsiveRunSpacing,
            children: children,
          ),
        );
      },
    );
  }
}
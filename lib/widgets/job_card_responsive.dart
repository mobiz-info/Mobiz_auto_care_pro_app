import 'package:flutter/material.dart';

class JobCardResponsive {
  static const double tabletBreakpoint = 600;
  static const double contentMaxWidth = 1100;

  static bool isTabletWidth(double width) => width >= tabletBreakpoint;
  static int columnsFor(double width) => isTabletWidth(width) ? 2 : 1;
}

class JobCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const JobCardContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : JobCardResponsive.contentMaxWidth;
        final contentWidth = availableWidth
            .clamp(0.0, JobCardResponsive.contentMaxWidth)
            .toDouble();
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: Padding(padding: padding, child: child),
          ),
        );
      },
    );
  }
}

class JobCardResponsiveList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final Widget? emptyTrailing;

  const JobCardResponsiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.physics,
    this.emptyTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(
          0.0,
          JobCardResponsive.contentMaxWidth,
        );
        return Center(
          child: SizedBox(
            width: width,
            child: LayoutBuilder(
              builder: (context, contentConstraints) {
                if (!JobCardResponsive.isTabletWidth(
                  contentConstraints.maxWidth,
                )) {
                  return ListView.separated(
                    padding: padding,
                    physics: physics,
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: itemBuilder,
                  );
                }

                final rows = (itemCount + 1) ~/ 2;
                return ListView.builder(
                  padding: padding,
                  physics: physics,
                  itemCount: rows,
                  itemBuilder: (context, rowIndex) {
                    final firstIndex = rowIndex * 2;
                    final secondIndex = firstIndex + 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: itemBuilder(context, firstIndex)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: secondIndex < itemCount
                                ? itemBuilder(context, secondIndex)
                                : emptyTrailing ?? const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class JobCardResponsiveFields extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  const JobCardResponsiveFields({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = JobCardResponsive.columnsFor(constraints.maxWidth);
        final fields = children
            .where((child) => child is! SizedBox || child.width != null)
            .toList();
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                fields[i],
              ],
            ],
          );
        }
        final itemWidth = (constraints.maxWidth - spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in fields)
              SizedBox(
                key: child.key != null ? ValueKey('resp_${child.key}') : null,
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

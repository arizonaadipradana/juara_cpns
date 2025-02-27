import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints, ScreenSize screenSize) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ScreenSize screenSize;
        if (constraints.maxWidth < 600) {
          screenSize = ScreenSize.mobile;
        } else if (constraints.maxWidth < 900) {
          screenSize = ScreenSize.tablet;
        } else {
          screenSize = ScreenSize.desktop;
        }
        return builder(context, constraints, screenSize);
      },
    );
  }
}

enum ScreenSize { mobile, tablet, desktop }

extension ScreenSizeExtension on ScreenSize {
  bool get isMobile => this == ScreenSize.mobile;
  bool get isTablet => this == ScreenSize.tablet;
  bool get isDesktop => this == ScreenSize.desktop;
}
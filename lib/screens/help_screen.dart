import 'package:flutter/material.dart';
import 'package:juara_cpns/theme/app_theme.dart';
import 'package:juara_cpns/widgets/responsive_builder.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Pusat Bantuan"),
      ),
      body: ResponsiveBuilder(builder: (context, constraints, screenSize) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: screenSize.isDesktop ? 48 : 16,
              vertical: 24
          ),
        );
      }),
    );
  }
}

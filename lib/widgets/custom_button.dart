import 'package:flutter/material.dart';
import 'package:juara_cpns/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;  // <-- Ini mengharapkan fungsi non-nullable
  final bool isLoading;
  final bool isPrimary;
  final bool isFullWidth;
  final IconData? icon;
  final bool disabled;  // <-- Property ini ditambahkan

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.isFullWidth = true,
    this.icon,
    this.disabled = false,  // <-- Default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? AppTheme.primaryButtonStyle
        : AppTheme.secondaryButtonStyle;

    Widget buttonContent = isLoading
        ? const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2,
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(text),
      ],
    );

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPrimary && !disabled ? AppTheme.buttonShadow : null,
      ),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,  // <-- Gunakan opacity untuk tampilan disabled
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,  // <-- Gunakan null untuk disabled
          style: buttonStyle,
          child: buttonContent,
        ),
      ),
    );
  }
}
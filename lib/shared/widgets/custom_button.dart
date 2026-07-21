import 'package:flutter/material.dart';
import 'package:live_auction/core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient = AppColors.primaryGradient,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final Color effectiveTextColor = enabled
        ? (textColor ?? Colors.black)
        : AppColors.textSecondary;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: enabled ? (gradient ?? AppColors.primaryGradient) : null,
        color: enabled ? backgroundColor : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: enabled ? null : Border.all(color: AppColors.border),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: effectiveTextColor, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: effectiveTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

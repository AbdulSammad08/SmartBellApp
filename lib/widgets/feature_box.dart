import 'package:flutter/material.dart';
import '../constants/colors.dart'; 

class FeatureBox extends StatelessWidget {
  final String featureName;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String? additionalText;
  final double boxHeight;

  const FeatureBox({
    super.key,
    required this.featureName,
    required this.icon,
    required this.color,
    required this.isActive,
    this.additionalText,
    this.boxHeight = 260,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      height: boxHeight,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            // Updated Text widget to use the static TextStyle
            Text(
              featureName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark, // Changed from dynamic color to static AppColors.textOnDark
              ),
            ),
            if (additionalText != null) ...[
              const SizedBox(height: 10),
              Text(
                additionalText!,
                style: TextStyle(
                  fontSize: 16,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 
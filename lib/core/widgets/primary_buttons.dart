import 'package:flutter/material.dart';
import 'package:time_track/core/constants/app_colors.dart';

class PrimaryButtons extends StatelessWidget {
  const PrimaryButtons({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
      onPressed: onPressed,
      child: Text(buttonText, style: TextStyle(color: AppColors.textWhite)),
    );
  }
}

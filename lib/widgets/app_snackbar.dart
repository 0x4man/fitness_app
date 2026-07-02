import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Simple SnackBar helper used instead of a third-party toast plugin
/// (some toast packages break on newer Android/Flutter versions due
/// to native embedding changes). This uses Flutter's built-in
/// SnackBar, so there's no extra native dependency to break.
void showAppMessage(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
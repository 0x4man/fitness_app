import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Branded top header shown on Home and other main tabs — the app's
/// "wordmark" (logo mark + name), plus a notification bell and profile
/// avatar on the right. Mirrors the top bar pattern used by most
/// polished fitness apps (Nike Training Club, Strava, etc.) instead of
/// a plain Material AppBar.
class AppHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final bool hasNotification;

  const AppHeader({
    super.key,
    this.onNotificationTap,
    this.onAvatarTap,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo mark
        
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            'assets/icon/viora_monogram_dark.png',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        // Wordmark
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Vio',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'ra',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          showDot: hasNotification,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  const _CircleIconButton(
      {required this.icon, this.showDot = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceBorder),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
          if (showDot)
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

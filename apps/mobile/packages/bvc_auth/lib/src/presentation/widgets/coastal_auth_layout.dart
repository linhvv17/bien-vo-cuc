import 'package:flutter/material.dart';

import 'package:bvc_ui/bvc_ui.dart';

/// Full-screen backdrop: deep sea gradient, animated waves, soft horizon glow (Biển Vô Cực).
class CoastalAuthBackdrop extends StatelessWidget {
  const CoastalAuthBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF030A14),
                AppColors.oceanDeep.withValues(alpha: 0.85),
                AppColors.background,
                const Color(0xFF0C1829),
              ],
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
        // Subtle “bầu trời / ánh sáng” phía trên
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 320,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.85),
                radius: 1.15,
                colors: [
                  AppColors.secondary.withValues(alpha: 0.18),
                  AppColors.oceanLight.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: WavesBackground(opaqueBackground: false)),
        // Phản chiếu hoàng hôn nhẹ phía dưới (gợi mặt nước)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.07),
                  AppColors.goldGlow.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Headline + địa danh cho màn auth.
class CoastalAuthHero extends StatelessWidget {
  const CoastalAuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = 'Biển Vô Cực · Thái Bình',
  });

  final String title;
  final String subtitle;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.45)),
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.waves_rounded, size: 16, color: AppColors.secondary.withValues(alpha: 0.95)),
                  const SizedBox(width: 6),
                  Text(
                    accent,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.oceanLight,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.foreground,
              AppColors.foreground.withValues(alpha: 0.92),
              AppColors.goldGlow.withValues(alpha: 0.95),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        _HorizonRule(),
      ],
    );
  }
}

class _HorizonRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.border.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.blur_on_rounded,
            size: 22,
            color: AppColors.secondary.withValues(alpha: 0.65),
          ),
        ),
        line,
      ],
    );
  }
}

/// Khung input mờ giống kính ven sóng.
class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadii.x2l),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.oceanDeep.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            border: InputBorder.none,
            floatingLabelStyle: const TextStyle(color: AppColors.mutedForeground),
            labelStyle: const TextStyle(color: AppColors.mutedForeground),
            hintStyle: const TextStyle(color: AppColors.mutedForeground),
            helperStyle: TextStyle(color: AppColors.mutedForeground.withValues(alpha: 0.9), fontSize: 11),
          ),
        ),
        child: child,
      ),
    );
  }
}

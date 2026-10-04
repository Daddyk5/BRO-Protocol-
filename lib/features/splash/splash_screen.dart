import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bro_logo.dart';
import '../../core/widgets/spark_painter.dart';

/// ~2.2s intro: fists slide in (500ms) → bump with recoil, spark and
/// shockwave (300ms) → wordmark fades up (400ms) → progress bar with rotating
/// status text → fade to Home. Reduced motion: static logo, fade only.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;
  bool _reducedMotion = false;

  // Timeline fractions of the 2200ms run.
  static const double _slideEnd = 500 / 2200;
  static const double _bumpEnd = 800 / 2200;
  static const double _ringEnd = 1100 / 2200;
  static const double _wordEnd = 1200 / 2200;
  static const double _progressEnd = 2000 / 2200;

  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _slideEnd, curve: Curves.easeOut),
  );

  // Recoil: fists knock each other back slightly, then settle into contact.
  late final Animation<double> _recoil = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 65),
  ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(_slideEnd, _bumpEnd)));

  late final Animation<double> _spark = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(_slideEnd, _bumpEnd)));

  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_slideEnd, _ringEnd, curve: Curves.easeOut),
  );

  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_bumpEnd, _wordEnd, curve: Curves.easeOut),
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_wordEnd, _progressEnd, curve: Curves.easeInOut),
  );

  // Reduced-motion fade.
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration =
        _reducedMotion ? AppConstants.splashReducedMotionDuration : AppConstants.splashDuration;
    _controller.forward().whenComplete(() {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Semantics(
        label: 'Bro Protocol is loading',
        child: Center(
          child: _reducedMotion ? _buildStatic() : _buildAnimated(context),
        ),
      ),
    );
  }

  Widget _buildStatic() {
    return FadeTransition(
      opacity: _fade,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BroLogo(size: 200),
          const SizedBox(height: 8),
          Text(AppConstants.appName, style: AppTextStyles.display),
          const SizedBox(height: 6),
          Text(AppConstants.tagline, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }

  Widget _buildAnimated(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = math.min(screenWidth * 0.72, 300.0);
    final unit = logoSize / 512;
    final travel = screenWidth / 2 + logoSize / 2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slideOffset = (1 - _slide.value) * travel;
        final recoilOffset = _recoil.value * 14 * unit * 2;
        final progress = _progress.value;
        final statusIndex = math.min(
          (progress * AppConstants.splashStatus.length).floor(),
          AppConstants.splashStatus.length - 1,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The fist band only occupies the middle ~55% of the square logo.
            SizedBox(
              width: logoSize,
              height: logoSize * 0.55,
              child: OverflowBox(
                minHeight: logoSize,
                maxHeight: logoSize,
                child: SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -slideOffset - recoilOffset,
                        top: 0,
                        child: SvgPicture.asset(BroAssets.fistRed, width: logoSize / 2, height: logoSize),
                      ),
                      Positioned(
                        left: logoSize / 2 + slideOffset + recoilOffset,
                        top: 0,
                        child: SvgPicture.asset(BroAssets.fistBlue, width: logoSize / 2, height: logoSize),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SparkPainter(
                            unit: unit,
                            sparkScale: _spark.value,
                            ringProgress: _ring.value,
                            ringOpacity: _ring.value > 0 ? 1 - _ring.value : 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _wordmark.value,
              child: Transform.translate(
                offset: Offset(0, (1 - _wordmark.value) * 16),
                child: Column(
                  children: [
                    Text(AppConstants.appName, style: AppTextStyles.display),
                    const SizedBox(height: 6),
                    Text(AppConstants.tagline, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            Opacity(
              opacity: progress > 0 ? 1 : 0,
              child: Column(
                children: [
                  _GradientProgressBar(value: progress, width: math.min(220, screenWidth * 0.6)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      child: Text(
                        AppConstants.splashStatus[statusIndex],
                        key: ValueKey(statusIndex),
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.value, required this.width});

  final double value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      value: '${(value * 100).round()}%',
      child: Container(
        width: width,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

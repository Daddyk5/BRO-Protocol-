import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'bro_logo.dart';
import 'spark_painter.dart';

/// Looping mini fist-bump: the fists close in, spark, and pull back.
/// Falls back to a gently fading static logo when reduced motion is on.
class FistBumpLoader extends StatefulWidget {
  const FistBumpLoader({super.key, this.size = 120, this.semanticsLabel = 'Writing your reply'});

  /// Width of the loader; height is 60% of it.
  final double size;
  final String semanticsLabel;

  @override
  State<FistBumpLoader> createState() => _FistBumpLoaderState();
}

class _FistBumpLoaderState extends State<FistBumpLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  // 0 = apart, 1 = touching. Close in fast, hold briefly, release slowly.
  late final Animation<double> _close = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 45),
  ]).animate(_controller);

  late final Animation<double> _spark = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 38),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final Widget content;
    if (reduced) {
      content = BroLogo(size: size);
    } else {
      final unit = size / 512;
      content = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final gap = (1 - _close.value) * size * 0.16;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -gap,
                top: 0,
                child: SvgPicture.asset(BroAssets.fistRed, width: size / 2, height: size),
              ),
              Positioned(
                left: size / 2 + gap,
                top: 0,
                child: SvgPicture.asset(BroAssets.fistBlue, width: size / 2, height: size),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: SparkPainter(
                    unit: unit,
                    sparkScale: _spark.value,
                    ringProgress: _spark.value > 0 ? 1 - _close.value * 0.6 : 0,
                    ringOpacity: _spark.value * 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: SizedBox(
        width: size,
        height: size * 0.6,
        child: OverflowBox(
          minHeight: size,
          maxHeight: size,
          child: SizedBox(width: size, height: size, child: content),
        ),
      ),
    );
  }
}

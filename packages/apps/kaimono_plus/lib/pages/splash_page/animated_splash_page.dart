import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AnimatedSplashPage extends HookWidget {
  const AnimatedSplashPage({
    required this.onFinished,
    super.key,
  });

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1700),
    );
    final hasFinished = useRef(false);

    useEffect(() {
      var isActive = true;

      Future<void> startAnimation() async {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (!isActive || !context.mounted) return;
        await controller.forward(from: 0);
        await Future<void>.delayed(const Duration(milliseconds: 420));
        if (!isActive || !context.mounted || hasFinished.value) return;
        hasFinished.value = true;
        onFinished();
      }

      startAnimation();

      return () {
        isActive = false;
      };
    }, [controller]);

    return Scaffold(
      backgroundColor: Colors.amber,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedShoppingBasket(
                controller: controller,
                onReplay: () {
                  if (hasFinished.value) return;
                  controller.forward(from: 0);
                },
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: controller,
                  curve: const Interval(0.72, 1, curve: Curves.easeOut),
                ),
                child: const Text(
                  'Kaimono+',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedShoppingBasket extends StatelessWidget {
  const _AnimatedShoppingBasket({
    required this.controller,
    required this.onReplay,
  });

  final Animation<double> controller;
  final VoidCallback onReplay;

  static const _letters = ['K', 'a', 'i', 'm', 'o', 'n', 'o'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReplay,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return SizedBox(
            width: 224,
            height: 190,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 18,
                  child: _BasketHandle(
                    progress: _curveProgress(
                      controller.value,
                      start: 0,
                      end: 0.38,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 18,
                  child: _BasketBody(
                    progress: _curveProgress(
                      controller.value,
                      start: 0.08,
                      end: 0.48,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                ),
                for (final indexedLetter in _letters.indexed)
                  _FlyingLetter(
                    index: indexedLetter.$1,
                    letter: indexedLetter.$2,
                    progress: controller.value,
                  ),
                Positioned(
                  right: 16,
                  bottom: 18,
                  child: _PlusBadge(
                    progress: controller.value,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BasketHandle extends StatelessWidget {
  const _BasketHandle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: progress,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 88,
        height: 68,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black87, width: 5),
            left: BorderSide(color: Colors.black87, width: 5),
            right: BorderSide(color: Colors.black87, width: 5),
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(36),
          ),
        ),
      ),
    );
  }
}

class _BasketBody extends StatelessWidget {
  const _BasketBody({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: progress,
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black87, width: 5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(34),
            bottomRight: Radius.circular(34),
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 26),
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pulse = _curveProgress(
      progress,
      start: 0.08,
      end: 0.36,
      curve: Curves.easeOutBack,
    );

    return Transform.scale(
      scale: 0.86 + (pulse * 0.16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 4),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

double _curveProgress(
  double value, {
  required double start,
  required double end,
  required Curve curve,
}) {
  final progress = ((value - start) / (end - start)).clamp(0.0, 1.0);
  return curve.transform(progress);
}

class _FlyingLetter extends StatelessWidget {
  const _FlyingLetter({
    required this.index,
    required this.letter,
    required this.progress,
  });

  final int index;
  final String letter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final start = 0.18 + (index * 0.075);
    final end = start + 0.34;
    final rawProgress = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    final easedProgress = Curves.easeOutCubic.transform(rawProgress);
    final bounceProgress = Curves.easeOutBack.transform(rawProgress);
    final targetX = -68.0 + (index * 22);
    final targetY = 26.0 + (index.isEven ? -3 : 4);
    final x = lerpDouble(74, targetX, easedProgress)!;
    final y = lerpDouble(52, targetY, bounceProgress)!;

    return Positioned(
      left: 101,
      top: 76,
      child: Transform.translate(
        offset: Offset(x, y),
        child: Opacity(
          opacity: rawProgress == 0 ? 0 : 1,
          child: Transform.scale(
            scale: 0.72 + (bounceProgress * 0.28),
            child: Container(
              width: 24,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.black87.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

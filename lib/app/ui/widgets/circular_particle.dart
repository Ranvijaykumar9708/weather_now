import 'dart:math';
import 'package:flutter/material.dart';

class CircularParticle extends StatefulWidget {
  final double awayRadius;
  final int numberOfParticles;
  final double speedOfParticles;
  final double height;
  final double width;
  final Color particleColor;
  final double maxParticleSize;
  final Duration awayAnimationDuration;
  final bool isRandomColor;

  const CircularParticle({
    super.key,
    required this.awayRadius,
    required this.numberOfParticles,
    required this.speedOfParticles,
    required this.height,
    required this.width,
    required this.particleColor,
    required this.maxParticleSize,
    required this.awayAnimationDuration,
    required this.isRandomColor,
  });

  @override
  State<CircularParticle> createState() => _CircularParticleState();
}

class _CircularParticleState extends State<CircularParticle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.awayAnimationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final particlePositions = List.generate(
      widget.numberOfParticles,
      (index) => Offset(
        _random.nextDouble() * widget.width,
        _random.nextDouble() * widget.height,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: particlePositions.asMap().entries.map((entry) {
        final index = entry.key;
        final basePos = entry.value;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final oscillation = widget.awayRadius * sin(2 * pi * (_controller.value + index / widget.numberOfParticles));
            final opacity = 0.5 + 0.2 * sin(2 * pi * (_controller.value * widget.speedOfParticles + index / widget.numberOfParticles));

            return Positioned(
              left: (basePos.dx % widget.width),
              top: (basePos.dy + oscillation) % widget.height,
              child: Opacity(
                opacity: opacity.clamp(0.3, 0.7),
                child: Container(
                  width: widget.maxParticleSize,
                  height: widget.maxParticleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isRandomColor
                        ? Color.fromRGBO(
                            _random.nextInt(256),
                            _random.nextInt(256),
                            _random.nextInt(256),
                            0.4,
                          )
                        : widget.particleColor,
                    boxShadow: [
                      BoxShadow(
                        color: widget.particleColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
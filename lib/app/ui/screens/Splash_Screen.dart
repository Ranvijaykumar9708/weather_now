import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather_now/app/ui/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Navigate after 3 seconds with fade transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        Get.to(() => const HomeScreen(), transition: Transition.fade, duration: const Duration(milliseconds: 500));
      });
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Generate particle positions once for more natural randomness
  final List<Offset> _particlePositions = List.generate(
    10,
    (index) => Offset(
      20.0 + (index * 50),
      50.0 + (index * 30),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.blue.shade800,
              Colors.cyan.shade400,
              Colors.blue.shade200.withOpacity(0.8),
            ],
            center: const Alignment(0, -0.3),
            radius: 1.5,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Particle effect simulation with smooth vertical movement & fade in/out loop
            ..._particlePositions.asMap().entries.map((entry) {
              final index = entry.key;
              final basePos = entry.value;

              // Staggered delay for each particle
              final delay = (index * 200).ms;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Calculate vertical oscillation between 0 and 20 pixels
                  final oscillation = 20 * sin(2 * pi * (_controller.value + index / 10));

                  // Opacity oscillates between 0.3 and 0.7
                  final opacity = 0.5 + 0.2 * sin(2 * pi * (_controller.value * 2 + index / 10));

                  return Positioned(
                    left: basePos.dx % size.width,
                    top: (basePos.dy + oscillation) % size.height,
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 0.7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.3),
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

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsating weather icon with smooth scaling animation
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final scale = 1 + 0.1 * sin(2 * pi * _controller.value);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Image.network(
                      'http://openweathermap.org/img/wn/01d@2x.png',
                      width: 140,
                      height: 140,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/icons/cloud.png',
                        width: 140,
                        height: 140,
                        color: Colors.white,
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 1200.ms)
                    .scale(duration: 800.ms, curve: Curves.easeOut)
                    .then()
                    .rotate(duration: 1200.ms, curve: Curves.easeInOut),

                  const SizedBox(height: 24),

                  // Gradient text with slide + shake animation
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.cyan, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'weather_app'.tr,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 15,
                            color: Colors.black38,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(duration: 1000.ms)
                    .slideY(duration: 800.ms, begin: 1, end: 0)
                    .then()
                    .shake(delay: 500.ms, hz: 2),

                  const SizedBox(height: 20),

                  // Rotating arc loader with continuous rotation
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: 2 * pi * _controller.value,
                          child: CustomPaint(
                            painter: _ArcPainter(isDarkMode: isDarkMode),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final bool isDarkMode;

  _ArcPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.cyanAccent : Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 28.0;
    const startAngle = -pi / 2;
    const sweepAngle = pi;

    // Always draw full arc - rotation handled in parent Transform.rotate
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math'; // Added for sin function
import 'package:shimmer/shimmer.dart'; // Added for shimmer effect
import 'package:weather_now/models/weather_controller.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<WeatherModel> forecastList;
  final bool isCelsius;
  final bool isLoading;

  const HourlyForecastWidget({
    super.key,
    required this.forecastList,
    required this.isCelsius,
    required this.isLoading,
  });

  // Get gradient based on weather description
  LinearGradient _getWeatherGradient(String description) {
    final isDarkMode = Get.isDarkMode;
    switch (description.toLowerCase()) {
      case 'clear':
        return LinearGradient(
          colors: isDarkMode
              ? [Colors.blue.shade900, Colors.blue.shade600]
              : [Colors.lightBlue.shade200, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'clouds':
        return LinearGradient(
          colors: isDarkMode
              ? [Colors.grey.shade800, Colors.grey.shade500]
              : [Colors.grey.shade300, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'rain':
        return LinearGradient(
          colors: isDarkMode
              ? [Colors.blueGrey.shade800, Colors.blueGrey.shade400]
              : [Colors.blueGrey.shade200, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'snow':
        return LinearGradient(
          colors: isDarkMode
              ? [Colors.lightBlue.shade900, Colors.blue.shade700]
              : [Colors.lightBlue.shade200, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: isDarkMode
              ? [Colors.grey.shade800, Colors.black45]
              : [Colors.orange.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hourly Forecast'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.indigo,
                  fontFamily: 'Roboto',
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150, // Increased for better spacing
            child: isLoading
                ? Center(
                    child: Shimmer.fromColors(
                      baseColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      highlightColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade100,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 4,
                      ),
                    ),
                  )
                : forecastList.isEmpty
                    ? Center(
                        child: Text(
                          'no_data'.tr,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: forecastList.length,
                        itemBuilder: (context, index) {
                          final weather = forecastList[index];
                          final date = DateTime.parse(weather.date);
                          final hour = '${date.hour.toString().padLeft(2, '0')}:00';

                          return GestureDetector(
                            onTap: () {
                              // Simulate interaction (e.g., show details)
                              Get.snackbar(
                                'Hourly Detail',
                                '${weather.date} - ${weather.temperature.toStringAsFixed(1)}${isCelsius ? '°C' : '°F'}',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                                colorText: isDarkMode ? Colors.white : Colors.black87,
                              );
                            },
                            child: Container(
                              width: 100, // Increased for readability
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20), // Increased radius
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Increased blur
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          gradient: _getWeatherGradient(weather.description),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDarkMode
                                                  ? Colors.black26
                                                  : Colors.grey.shade300,
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              hour,
                                              style: TextStyle(
                                                fontSize: 14, // Increased for readability
                                                fontWeight: FontWeight.w500,
                                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            AnimatedBuilder(
                                              animation: AlwaysStoppedAnimation(1),
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: 1 + 0.1 * (1 + sin(DateTime.now().millisecondsSinceEpoch / 300)),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: isDarkMode
                                                              ? Colors.blueAccent.withOpacity(0.4)
                                                              : Colors.orangeAccent.withOpacity(0.4),
                                                          blurRadius: 8,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Image.network(
                                                      'http://openweathermap.org/img/wn/${weather.icon}@2x.png',
                                                      width: 40, // Increased for impact
                                                      height: 40,
                                                      errorBuilder: (_, __, ___) => Icon(
                                                        Icons.cloud_off,
                                                        size: 36,
                                                        color: isDarkMode ? Colors.grey : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(
                                              '${weather.temperature.toStringAsFixed(1)}${isCelsius ? '°C' : '°F'}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16, // Increased for readability
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      width: 10, // Increased size
                                      height: 10,
                                      margin: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Colors.deepOrange, Colors.orangeAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.6),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate()
                              .fadeIn(duration: 500.ms)
                              .scale(
                                duration: 300.ms,
                                curve: Curves.easeOut,
                              )
                              .then()
                              .shimmer(
                                duration: 1000.ms,
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                              );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
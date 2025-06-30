import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather_now/models/weather_controller.dart';

class ForecastWidget extends StatelessWidget {
  final List<WeatherModel> forecastList;
  final bool isCelsius;
  final bool isLoading;

  const ForecastWidget({
    super.key,
    required this.forecastList,
    this.isCelsius = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5_day_forecast'.tr.isEmpty ? '5 Day Forecast' : '5_day_forecast'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 210,
                  child: isLoading
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (_, index) => Container(
                            width: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ).animate().shimmer(duration: 1200.ms),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: forecastList.length,
                          itemBuilder: (context, index) {
                            final weather = forecastList[index];
                            final date = DateTime.tryParse(weather.date) ?? DateTime.now();
                            final dayOfWeek = DateFormat.EEEE().format(date); // Full weekday
                            final isNight = date.hour < 6 || date.hour > 18;

                            final gradientColors = isNight
                                ? [Colors.indigo.shade900, Colors.blueGrey.shade800]
                                : [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.7)];

                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: screenWidth < 360 ? 100 : 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      dayOfWeek, // <-- Changed to full weekday name
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth < 360 ? 14 : null,
                                            color: isNight ? Colors.white : Colors.deepPurple,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.yMMMd().format(date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isNight ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Image.network(
                                      'http://openweathermap.org/img/wn/${weather.icon}.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.cloud_off,
                                        size: 40,
                                      ),
                                    ).animate().fadeIn(duration: 10000000.ms),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${weather.temperature.toStringAsFixed(1)}${isCelsius ? '°C' : '°F'}',
                                      style: TextStyle(
                                        fontSize: screenWidth < 360 ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: isNight ? Colors.white : Colors.teal.shade800,
                                      ),
                                    ),
                                    Text(
                                      'Min: ${weather.temperature.toStringAsFixed(1)}°\nMax: ${(weather.temperature + 3).toStringAsFixed(1)}°',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: isNight ? Colors.white70 : Colors.teal[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      weather.description.tr.capitalizeFirst ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isNight ? Colors.white70 : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn().slideX(begin: 0.1, duration: 300.ms);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

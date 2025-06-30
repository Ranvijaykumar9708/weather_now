import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather_now/models/weather_controller.dart';

class CurrentWeatherWidget extends StatelessWidget {
  final WeatherModel weather;
  final bool isCelsius;

  const CurrentWeatherWidget({
    super.key,
    required this.weather,
    required this.isCelsius,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.blueGrey[900]!, Colors.black54]
                : [Colors.blue[100]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weather.cityName.tr,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.indigo[900],
                    fontFamily: 'Roboto',
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.toStringAsFixed(1)}${isCelsius ? '°C' : '°F'}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.teal[800],
                            fontFamily: 'Roboto',
                          ),
                    ),
                    Text(
                      weather.description.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                    ),
                  ],
                ),
                Image.network(
                  'http://openweathermap.org/img/wn/${weather.icon}@2x.png',
                  width: 64,
                  height: 64,
                  errorBuilder: (_, __, ___) => const Icon(Icons.cloud_off, size: 64),
                ).animate().fadeIn(duration: 600.ms).shake(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${weather.minTemperature.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.teal[700],
                      ),
                ),
                Text(
                  'Max: ${weather.maxTemperature.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.teal[700],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Humidity: ${weather.humidity}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                ),
                Text(
                  'Wind: ${weather.windSpeed} ${isCelsius ? 'm/s' : 'mph'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale();
  }
}
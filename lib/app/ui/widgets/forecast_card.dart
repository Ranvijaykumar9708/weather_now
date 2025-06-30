import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:weather_now/models/weather_controller.dart';

class ForecastCard extends StatelessWidget {
  final WeatherModel weather;
  final bool isCelsius;
  final bool isNight;

  const ForecastCard({
    super.key,
    required this.weather,
    required this.isCelsius,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tempUnit = isCelsius ? '°C' : '°F';
    final temp = weather.temperature.toStringAsFixed(1);
    final minTemp = weather.minTemperature.toStringAsFixed(1);
    final maxTemp = weather.maxTemperature.toStringAsFixed(1);
    final humidity = weather.humidity.toStringAsFixed(0);
    final windSpeed = weather.windSpeed.toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth > 180 ? 140 : 120;
        return Container(
          width: width,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            // Added to constrain height
            height: 160, // Matches typical ListView item height
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: isDarkMode ? Colors.grey[900] : Colors.orange.shade50,
              shadowColor: isDarkMode ? Colors.black54 : Colors.orange.shade200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDarkMode
                      ? LinearGradient(
                          colors: [Colors.grey[900]!, Colors.black26],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFFFA726), Color(0xFFFFE0B2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8.0), // Reduced from 10.0
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weather.date.split(' ')[0].split('-').reversed.join('/'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // Reduced from 6
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.blueAccent.withOpacity(0.3)
                                : Colors.orangeAccent.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.network(
                        'http://openweathermap.org/img/wn/${weather.icon}@2x.png',
                        width: 40, // Reduced from 48
                        height: 40, // Reduced from 48
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.cloud_off, size: 40),
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      '$temp$tempUnit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18, // Reduced from 20
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : Colors.deepOrange[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4), // Reduced from 6
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Min: $minTemp°',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.teal[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 12, // Reduced from 14
                            ),
                          ),
                          Text(
                            'Max: $maxTemp°',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.red[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 12, // Reduced from 14
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.air,
                          size: 12,
                          color: Colors.blueGrey,
                        ), // Reduced from 14
                        Text(
                          '$windSpeed km/h',
                          style: TextStyle(
                            fontSize: 9, // Reduced from 10
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 1), // Reduced from 2
                        Icon(
                          Icons.water_drop,
                          size: 12,
                          color: Colors.blue,
                        ), // Reduced from 14
                        Text(
                          '$humidity%',
                          style: TextStyle(
                            fontSize: 9, // Reduced from 10
                            color: isDarkMode ? Colors.white60 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale();
      },
    );
  }
}

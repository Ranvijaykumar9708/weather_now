import 'dart:convert';
import 'package:get/get.dart';

class WeatherModel {
  final String cityName;
  final double temperature;
  final double minTemperature;
  final double maxTemperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String date;
  final List<Map<String, dynamic>>? alerts;
  final double? lat; // Added for currentLat
  final double? lon; // Added for currentLon
  final int? sunriseTime; // Added for sunrise
  final int? sunsetTime; // Added for sunset
  final double? rainChance; // Added for rain chance

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    this.date = '',
    this.alerts,
    this.lat,
    this.lon,
    this.sunriseTime,
    this.sunsetTime,
    this.rainChance,
  });

  factory WeatherModel.fromCurrentJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      minTemperature: (json['main']['temp_min'] as num?)?.toDouble() ?? 0.0,
      maxTemperature: (json['main']['temp_max'] as num?)?.toDouble() ?? 0.0,
      description: json['weather']?[0]?['description']?.toString().capitalize ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      humidity: json['main']['humidity']?.toInt() ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      alerts: (json['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      lat: (json['coord']['lat'] as num?)?.toDouble(),
      lon: (json['coord']['lon'] as num?)?.toDouble(),
      sunriseTime: json['sys']?['sunrise']?.toInt(),
      sunsetTime: json['sys']?['sunset']?.toInt(),
      rainChance: (json['rain']?['1h'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory WeatherModel.fromForecastJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['city']?['name'] ?? 'Unknown',
      temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      minTemperature: (json['main']['temp_min'] as num?)?.toDouble() ?? 0.0,
      maxTemperature: (json['main']['temp_max'] as num?)?.toDouble() ?? 0.0,
      description: json['weather']?[0]?['description']?.toString().capitalize ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      humidity: json['main']['humidity']?.toInt() ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      date: json['dt_txt'] ?? '',
      alerts: (json['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      lat: (json['city']?['coord']?['lat'] as num?)?.toDouble(),
      lon: (json['city']?['coord']?['lon'] as num?)?.toDouble(),
      rainChance: (json['rain']?['3h'] as num?)?.toDouble() ?? 0.0,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {
        'temp': temperature,
        'temp_min': minTemperature,
        'temp_max': maxTemperature,
        'humidity': humidity,
      },
      'weather': [
        {
          'description': description,
          'icon': icon,
        }
      ],
      'wind': {'speed': windSpeed},
      'dt_txt': date,
      if (alerts != null) 'alerts': alerts,
      if (lat != null) 'coord': {'lat': lat, 'lon': lon},
      if (sunriseTime != null) 'sys': {'sunrise': sunriseTime, 'sunset': sunsetTime},
      if (rainChance != null) 'rain': {'1h': rainChance},
    };
  }
}
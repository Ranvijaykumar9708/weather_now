import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    );
  }

  get sunriseTime => null;

  get rainChance => null;

  get sunsetTime => null;

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
    };
  }
}

Future<WeatherModel?> fetchWeatherAndCache(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final weather = WeatherModel.fromCurrentJson(jsonData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedWeather_${url.hashCode}', json.encode(weather.toJson()));
      return weather;
    }
    throw Exception('Failed to load weather');
  } catch (e) {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cachedWeather_${url.hashCode}');
    if (cached != null) {
      final cachedData = json.decode(cached);
      return WeatherModel.fromCurrentJson(cachedData);
    }
    return null;
  }
}
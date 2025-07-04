import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:weather_now/models/weather_controller.dart';
import 'package:weather_now/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final String apiKey = 'abd9a29ed1bbbc42691ee78be3d9882a';
  final Map<String, List<String>> _suggestionCache = {};

  @override
  Future<WeatherModel?> fetchWeather(String city, {required bool isCelsius}) async {
    final units = isCelsius ? 'metric' : 'imperial';
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$units';
    return fetchWeatherAndCache(url);
  }

  @override
  Future<WeatherModel?> fetchWeatherAndCache(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final weather = WeatherModel.fromCurrentJson(jsonData);
        await cacheWeatherData(jsonData, 'current_${url.hashCode}');
        return weather;
      }
      String errorMsg;
      if (response.statusCode == 401) {
        errorMsg = 'invalid_api_key'.tr;
        Get.snackbar(
          'Error'.tr,
          '$errorMsg\n${'please_update_api_key'.tr}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        );
      } else if (response.statusCode == 404) {
        errorMsg = 'city_not_found'.trParams({'city': url.split('q=')[1].split('&')[0]});
      } else if (response.statusCode == 429) {
        errorMsg = 'api_rate_limit_exceeded'.tr;
      } else {
        errorMsg = 'api_error'.trParams({
          'code': response.statusCode.toString(),
          'reason': response.reasonPhrase ?? 'Unknown'
        });
      }
      throw Exception(errorMsg);
    } catch (e) {
      final cachedWeather = await loadCachedWeather('current_${url.hashCode}');
      if (cachedWeather != null) {
        return cachedWeather;
      }
      throw Exception('network_error'.trParams({'error': e.toString()}));
    }
  }

  @override
  Future<List<WeatherModel>> fetchForecast(String city, {required bool isCelsius}) async {
    final units = isCelsius ? 'metric' : 'imperial';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=$units');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'];
        final Map<String, Map<String, dynamic>> dailyData = {};

        for (var item in list) {
          final date = DateTime.parse(item['dt_txt']);
          final dayKey = DateFormat('yyyy-MM-dd').format(date);
          final temp = (item['main']['temp'] as num).toDouble();
          final tempMin = (item['main']['temp_min'] as num).toDouble();
          final tempMax = (item['main']['temp_max'] as num).toDouble();
          final description = item['weather'][0]['description'] ?? 'Unknown';
          final icon = item['weather'][0]['icon'] ?? '01d';
          final humidity = item['main']['humidity']?.toInt() ?? 0;
          final windSpeed = (item['wind']['speed'] as num?)?.toDouble() ?? 0.0;

          if (!dailyData.containsKey(dayKey)) {
            dailyData[dayKey] = {
              'minTemp': tempMin,
              'maxTemp': tempMax,
              'temps': [temp],
              'description': description,
              'icon': icon,
              'date': item['dt_txt'],
              'humidity': humidity,
              'windSpeed': windSpeed,
            };
          } else {
            final currentMin = dailyData[dayKey]!['minTemp'] as double;
            final currentMax = dailyData[dayKey]!['maxTemp'] as double;
            dailyData[dayKey]!['minTemp'] = currentMin < tempMin ? currentMin : tempMin;
            dailyData[dayKey]!['maxTemp'] = currentMax > tempMax ? currentMax : tempMax;
            (dailyData[dayKey]!['temps'] as List<double>).add(temp);
            if (date.hour == 12) {
              dailyData[dayKey]!['description'] = description;
              dailyData[dayKey]!['icon'] = icon;
            }
          }
        }

        final forecastList = dailyData.entries.map((entry) {
          final day = entry.value;
          final temps = day['temps'] as List<double>;
          final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
          return WeatherModel(
            cityName: data['city']['name'] ?? 'Unknown',
            temperature: avgTemp,
            minTemperature: day['minTemp'] as double,
            maxTemperature: day['maxTemp'] as double,
            description: day['description'] as String,
            icon: day['icon'] as String,
            humidity: day['humidity'] as int,
            windSpeed: day['windSpeed'] as double,
            date: day['date'] as String,
            alerts: null,
          );
        }).toList();

        await cacheWeatherData(data, 'forecast_$city');
        return forecastList;
      } else {
        String errorMsg;
        if (response.statusCode == 401) {
          errorMsg = 'invalid_api_key'.tr;
          Get.snackbar(
            'Error'.tr,
            '$errorMsg\n${'please_update_api_key'.tr}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          );
        } else if (response.statusCode == 429) {
          errorMsg = 'api_rate_limit_exceeded'.tr;
        } else {
          errorMsg = 'failed_fetch_forecast'.trParams({
            'code': response.statusCode.toString(),
            'reason': response.reasonPhrase ?? 'Unknown'
          });
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      final cachedForecast = await loadCachedForecast('forecast_$city');
      if (cachedForecast.isNotEmpty) {
        return cachedForecast;
      }
      throw Exception('network_error'.trParams({'error': e.toString()}));
    }
  }

  @override
  Future<List<WeatherModel>> fetchHourlyForecast(String city, {required bool isCelsius}) async {
    final units = isCelsius ? 'metric' : 'imperial';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=$units');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'];
        final hourlyForecastList = list
            .take(12)
            .map<WeatherModel>((e) => WeatherModel.fromForecastJson({...e, 'city': data['city']}))
            .toList();
        await cacheWeatherData(data, 'forecast_$city');
        return hourlyForecastList;
      } else {
        String errorMsg;
        if (response.statusCode == 401) {
          errorMsg = 'invalid_api_key'.tr;
          Get.snackbar(
            'Error'.tr,
            '$errorMsg\n${'please_update_api_key'.tr}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          );
        } else if (response.statusCode == 429) {
          errorMsg = 'api_rate_limit_exceeded'.tr;
        } else {
          errorMsg = 'failed_fetch_forecast'.trParams({
            'code': response.statusCode.toString(),
            'reason': response.reasonPhrase ?? 'Unknown'
          });
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      final cachedForecast = await loadCachedForecast('forecast_$city');
      if (cachedForecast.isNotEmpty) {
        return cachedForecast.take(12).toList();
      }
      throw Exception('network_error'.trParams({'error': e.toString()}));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchWeatherAlerts(String city, {required bool isCelsius}) async {
    final units = isCelsius ? 'metric' : 'imperial';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$units');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = (data['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        await cacheWeatherData(data, 'alerts_$city');
        return alerts;
      } else {
        String errorMsg;
        if (response.statusCode == 401) {
          errorMsg = 'invalid_api_key'.tr;
          Get.snackbar(
            'Error'.tr,
            '$errorMsg\n${'please_update_api_key'.tr}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          );
        } else if (response.statusCode == 429) {
          errorMsg = 'api_rate_limit_exceeded'.tr;
        } else {
          errorMsg = 'failed_fetch_alerts'.trParams({
            'code': response.statusCode.toString(),
            'reason': response.reasonPhrase ?? 'Unknown'
          });
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      final cachedAlerts = await loadCachedAlerts('alerts_$city');
      if (cachedAlerts.isNotEmpty) {
        return cachedAlerts;
      }
      throw Exception('network_error_alerts'.trParams({'error': e.toString()}));
    }
  }

  @override
  Future<List<String>> fetchCitySuggestions(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final trimmedQuery = query.trim().toLowerCase();

    if (_suggestionCache.containsKey(trimmedQuery)) {
      return _suggestionCache[trimmedQuery]!;
    }

    final url = Uri.parse(
      'http://api.openweathermap.org/geo/1.0/direct?q=$trimmedQuery&limit=5&appid=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final suggestions = data.map((city) {
          final name = city['name'] as String;
          final country = city['country'] as String? ?? '';
          final state = city['state'] as String? ?? '';
          return state.isNotEmpty ? '$name, $state, $country' : '$name, $country';
        }).toList();
        _suggestionCache[trimmedQuery] = suggestions;
        return suggestions;
      } else {
        String errorMsg;
        if (response.statusCode == 401) {
          errorMsg = 'invalid_api_key_suggestions'.tr;
        } else if (response.statusCode == 429) {
          errorMsg = 'api_rate_limit_exceeded'.tr;
        } else {
          errorMsg = 'failed_fetch_suggestions'.trParams({'code': response.statusCode.toString()});
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('network_error_suggestions'.trParams({'error': e.toString()}));
    }
  }

  @override
  Future<void> cacheWeatherData(Map<String, dynamic> data, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<WeatherModel?> loadCachedWeather(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    final timestamp = prefs.getInt('${key}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && (now - timestamp) < 3600000) {
      final data = json.decode(cached);
      return WeatherModel.fromCurrentJson(data);
    }
    return null;
  }

  @override
  Future<List<WeatherModel>> loadCachedForecast(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    final timestamp = prefs.getInt('${key}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && (now - timestamp) < 3600000) {
      final data = json.decode(cached);
      final List list = data['list'] ?? [];
      final Map<String, Map<String, dynamic>> dailyData = {};

      for (var item in list) {
        final date = DateTime.tryParse(item['dt_txt'] ?? '') ?? DateTime.now();
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        final temp = (item['main']['temp'] as num?)?.toDouble() ?? 0.0;
        final tempMin = (item['main']['temp_min'] as num?)?.toDouble() ?? 0.0;
        final tempMax = (item['main']['temp_max'] as num?)?.toDouble() ?? 0.0;
        final description = item['weather']?[0]['description']?.toString() ?? 'Unknown';
        final icon = item['weather']?[0]['icon']?.toString() ?? '01d';
        final humidity = item['main']['humidity']?.toInt() ?? 0;
        final windSpeed = (item['wind']['speed'] as num?)?.toDouble() ?? 0.0;

        if (!dailyData.containsKey(dayKey)) {
          dailyData[dayKey] = {
            'minTemp': tempMin,
            'maxTemp': tempMax,
            'temps': [temp],
            'description': description,
            'icon': icon,
            'date': item['dt_txt']?.toString() ?? '',
            'humidity': humidity,
            'windSpeed': windSpeed,
          };
        } else {
          final currentMin = dailyData[dayKey]!['minTemp'] as double;
          final currentMax = dailyData[dayKey]!['maxTemp'] as double;
          dailyData[dayKey]!['minTemp'] = currentMin < tempMin ? currentMin : tempMin;
          dailyData[dayKey]!['maxTemp'] = currentMax > tempMax ? currentMax : tempMax;
          (dailyData[dayKey]!['temps'] as List<double>).add(temp);
          if (date.hour == 12) {
            dailyData[dayKey]!['description'] = description;
            dailyData[dayKey]!['icon'] = icon;
          }
        }
      }

      return dailyData.entries.map((entry) {
        final day = entry.value;
        final temps = day['temps'] as List<double>;
        final avgTemp = temps.isNotEmpty ? temps.reduce((a, b) => a + b) / temps.length : 0.0;
        return WeatherModel(
          cityName: data['city']?['name']?.toString() ?? 'Unknown',
          temperature: avgTemp,
          minTemperature: day['minTemp'] as double,
          maxTemperature: day['maxTemp'] as double,
          description: day['description'] as String,
          icon: day['icon'] as String,
          humidity: day['humidity'] as int,
          windSpeed: day['windSpeed'] as double,
          date: day['date'] as String,
          alerts: null,
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> loadCachedAlerts(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    final timestamp = prefs.getInt('${key}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && (now - timestamp) < 3600000) {
      final data = json.decode(cached);
      return (data['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    }
    return [];
  }
}
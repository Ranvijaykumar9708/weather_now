import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_now/models/weather_controller.dart';
import 'package:intl/intl.dart';

class WeatherController extends GetxController {
  final String apiKey = 'abd9a29ed1bbbc42691ee78be3d9882a';
  var currentWeather = Rxn<WeatherModel>();
  var forecastList = <WeatherModel>[].obs;
  var hourlyForecastList = <WeatherModel>[].obs;
  var isLoading = false.obs;
  var isCelsius = true.obs;
  var currentCity = 'Delhi'.obs;
  var weatherAlerts = <Map<String, dynamic>>[].obs;
  var searchHistory = <String>[].obs;
  var errorMessage = ''.obs;
  var isDarkMode = false.obs;
  var citySuggestions = <String>[].obs;
  var widgetOrder = ['current', 'alerts', 'hourly', 'forecast'].obs;
  var currentLat = 0.0.obs;
  var currentLon = 0.0.obs;
  Timer? _debounceTimer;
  final Map<String, List<String>> _suggestionCache = {};

  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
    _loadThemePreference();
    _loadWidgetOrder();
    fetchAll(currentCity.value);
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    searchHistory.value = prefs.getStringList('searchHistory') ?? [];
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', searchHistory.toList());
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _loadWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    widgetOrder.value = prefs.getStringList('widgetOrder') ?? ['current', 'alerts', 'hourly', 'forecast'];
  }

  Future<void> _saveWidgetOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('widgetOrder', widgetOrder.toList());
  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    _saveThemePreference(isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  void reorderWidgets(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = widgetOrder.removeAt(oldIndex);
    widgetOrder.insert(newIndex, item);
    _saveWidgetOrder();
  }

  void updateCity(String city) async {
    if (city.trim().isEmpty) {
      errorMessage.value = 'please_enter_valid_city'.tr;
      Get.snackbar(
        'Error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    city = city.trim().replaceAll(RegExp(r'\s+'), ' ').capitalizeFirst!;
    if (!searchHistory.contains(city)) {
      searchHistory.add(city);
      _saveSearchHistory();
    }
    currentCity.value = city;
    citySuggestions.clear();
    await fetchAll(city);
  }

  void updateCitySuggestions(String query) {
    if (query.trim().isEmpty) {
      citySuggestions.clear();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final trimmedQuery = query.trim().toLowerCase();

      if (_suggestionCache.containsKey(trimmedQuery)) {
        citySuggestions.value = _suggestionCache[trimmedQuery]!;
        return;
      }

      try {
        final url = Uri.parse(
          'http://api.openweathermap.org/geo/1.0/direct?q=$trimmedQuery&limit=5&appid=$apiKey',
        );
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
          citySuggestions.value = suggestions;
        } else {
          citySuggestions.clear();
          String errorMsg;
          if (response.statusCode == 401) {
            errorMsg = 'invalid_api_key_suggestions'.tr;
          } else if (response.statusCode == 429) {
            errorMsg = 'api_rate_limit_exceeded'.tr;
          } else {
            errorMsg = 'failed_fetch_suggestions'.trParams({'code': response.statusCode.toString()});
          }
          errorMessage.value = errorMsg;
          Get.snackbar(
            'Error'.tr,
            errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      } catch (e) {
        citySuggestions.clear();
        errorMessage.value = 'network_error_suggestions'.trParams({'error': e.toString()});
        Get.snackbar(
          'Error'.tr,
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    });
  }

  Future<void> fetchAll(String city) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([
        fetchWeather(city),
        fetchCombinedForecast(city),
        fetchWeatherAlerts(city),
      ]);
    } catch (e) {
      errorMessage.value = 'failed_fetch_weather'.trParams({'error': e.toString()});
      Get.snackbar(
        'Error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWeather(String city) async {
    final units = isCelsius.value ? 'metric' : 'imperial';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$units');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentWeather.value = WeatherModel.fromCurrentJson(data);
        currentLat.value = data['coord']['lat']?.toDouble() ?? 0.0;
        currentLon.value = data['coord']['lon']?.toDouble() ?? 0.0;
        _cacheWeather(data, 'current_$city');
      } else {
        currentWeather.value = null;
        await _loadCachedWeather('current_$city');
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
          errorMsg = 'city_not_found'.trParams({'city': city});
        } else if (response.statusCode == 429) {
          errorMsg = 'api_rate_limit_exceeded'.tr;
        } else {
          errorMsg = 'api_error'.trParams({
            'code': response.statusCode.toString(),
            'reason': response.reasonPhrase ?? 'Unknown'
          });
        }
        errorMessage.value = errorMsg;
        Get.snackbar(
          'Error'.tr,
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      currentWeather.value = null;
      await _loadCachedWeather('current_$city');
      errorMessage.value = 'network_error'.trParams({'error': e.toString()});
      Get.snackbar(
        'Error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> fetchCombinedForecast(String city) async {
    final units = isCelsius.value ? 'metric' : 'imperial';
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

        forecastList.value = dailyData.entries.map((entry) {
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

        hourlyForecastList.value = list
            .take(12)
            .map<WeatherModel>((e) => WeatherModel.fromForecastJson({...e, 'city': data['city']}))
            .toList();

        _cacheWeather(data, 'forecast_$city');
      } else {
        forecastList.clear();
        hourlyForecastList.clear();
        await _loadCachedWeather('forecast_$city');
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
        errorMessage.value = errorMsg;
        Get.snackbar(
          'Error'.tr,
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      forecastList.clear();
      hourlyForecastList.clear();
      await _loadCachedWeather('forecast_$city');
      errorMessage.value = 'network_error'.trParams({'error': e.toString()});
      Get.snackbar(
        'Error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> fetchWeatherAlerts(String city) async {
    final units = isCelsius.value ? 'metric' : 'imperial';
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$units');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        weatherAlerts.value = (data['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _cacheWeather(data, 'alerts_$city');
      } else {
        weatherAlerts.clear();
        await _loadCachedWeather('alerts_$city');
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
        errorMessage.value = errorMsg;
        Get.snackbar(
          'Error'.tr,
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      weatherAlerts.clear();
      await _loadCachedWeather('alerts_$city');
      errorMessage.value = 'network_error_alerts'.trParams({'error': e.toString()});
      Get.snackbar(
        'Error'.tr,
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _cacheWeather(Map<String, dynamic> data, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadCachedWeather(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    final timestamp = prefs.getInt('${key}_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (cached != null && (now - timestamp) < 3600000) {
      final data = json.decode(cached);
      if (key.startsWith('current_')) {
        currentWeather.value = WeatherModel.fromCurrentJson(data);
        currentLat.value = data['coord']['lat']?.toDouble() ?? 0.0;
        currentLon.value = data['coord']['lon']?.toDouble() ?? 0.0;
      } else if (key.startsWith('forecast_')) {
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

        forecastList.value = dailyData.entries.map((entry) {
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

        hourlyForecastList.value = list
            .take(12)
            .map<WeatherModel>((e) => WeatherModel.fromForecastJson({...e, 'city': data['city'] ?? {}}))
            .toList();
      } else if (key.startsWith('alerts_')) {
        weatherAlerts.value = (data['alerts'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      }
    }
  }

  void toggleUnit() {
    isCelsius.value = !isCelsius.value;
    fetchAll(currentCity.value);
  }

  void clearSearchHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_now/models/weather_controller.dart';
import 'package:weather_now/repositories/weather_repository.dart';

class WeatherController extends GetxController {
  final WeatherRepository weatherRepository;
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

  WeatherController({required this.weatherRepository});

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
      try {
        citySuggestions.value = await weatherRepository.fetchCitySuggestions(query);
      } catch (e) {
        citySuggestions.clear();
        errorMessage.value = e.toString();
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
      final results = await Future.wait([
        weatherRepository.fetchWeather(city, isCelsius: isCelsius.value),
        weatherRepository.fetchForecast(city, isCelsius: isCelsius.value),
        weatherRepository.fetchHourlyForecast(city, isCelsius: isCelsius.value),
        weatherRepository.fetchWeatherAlerts(city, isCelsius: isCelsius.value),
      ]);

      currentWeather.value = results[0] as WeatherModel?;
      forecastList.value = results[1] as List<WeatherModel>;
      hourlyForecastList.value = results[2] as List<WeatherModel>;
      weatherAlerts.value = results[3] as List<Map<String, dynamic>>;

      if (currentWeather.value != null) {
        currentLat.value = currentWeather.value!.lat ?? 0.0;
        currentLon.value = currentWeather.value!.lon ?? 0.0;
      }
    } catch (e) {
      errorMessage.value = e.toString();
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

  void toggleUnit() {
    isCelsius.value = !isCelsius.value;
    fetchAll(currentCity.value);
  }

  void clearSearchHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }
}
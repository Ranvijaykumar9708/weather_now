
import 'package:weather_now/models/weather_controller.dart';

abstract class WeatherRepository {
  Future<WeatherModel?> fetchWeather(String city, {required bool isCelsius});
  Future<List<WeatherModel>> fetchForecast(String city, {required bool isCelsius});
  Future<List<WeatherModel>> fetchHourlyForecast(String city, {required bool isCelsius});
  Future<List<Map<String, dynamic>>> fetchWeatherAlerts(String city, {required bool isCelsius});
  Future<List<String>> fetchCitySuggestions(String query);
  Future<WeatherModel?> fetchWeatherAndCache(String url);
  Future<void> cacheWeatherData(Map<String, dynamic> data, String key);
  Future<WeatherModel?> loadCachedWeather(String key);
  Future<List<WeatherModel>> loadCachedForecast(String key);
  Future<List<Map<String, dynamic>>> loadCachedAlerts(String key);
}
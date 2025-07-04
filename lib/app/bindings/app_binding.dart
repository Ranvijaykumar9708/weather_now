import 'package:get/get.dart';
import 'package:weather_now/app/controllers/weather_Controller.dart';
import 'package:weather_now/repositories/weather_repository.dart';
import 'package:weather_now/repositories/weather_repository_impl.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherRepository>(() => WeatherRepositoryImpl());
    Get.lazyPut<WeatherController>(
      () => WeatherController(weatherRepository: Get.find<WeatherRepository>()),
      fenix: true, // Ensures the controller persists across navigation
    );
  }
}
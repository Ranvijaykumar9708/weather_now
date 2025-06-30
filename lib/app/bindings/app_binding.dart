import 'package:get/get.dart';
import 'package:weather_now/app/controllers/weather_model.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherController>(() => WeatherController());
  }
}
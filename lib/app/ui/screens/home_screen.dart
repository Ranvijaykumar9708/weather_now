import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:weather_now/app/controllers/weather_model.dart';
import 'package:weather_now/app/ui/widgets/circular_particle.dart';
import 'package:weather_now/app/ui/widgets/current_weather_widget.dart';
import 'package:weather_now/app/ui/widgets/forecast_card.dart';
import 'package:weather_now/app/ui/widgets/hourly_forecast_widget.dart';
import 'package:weather_now/app/ui/widgets/weather_alerts_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WeatherController>();
    final TextEditingController textController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final SpeechToText speech = SpeechToText();

    void startListening() async {
      bool available = await speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => Get.snackbar(
          'Error'.tr,
          'speech_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        ),
      );
      if (available) {
        speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              textController.text = result.recognizedWords;
              controller.updateCitySuggestions(result.recognizedWords.trim());
              if (result.recognizedWords.trim().isNotEmpty) {
                controller.updateCity(result.recognizedWords.trim());
                textController.clear();
                controller.updateCitySuggestions('');
                speech.stop();
              }
            }
          },
          localeId: Get.locale?.languageCode ?? 'en_US',
        );
      }
    }

    return GetBuilder<WeatherController>(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: () async {
            try {
              await controller.fetchAll(controller.currentCity.value);
            } catch (e) {
              Get.snackbar(
                'Error'.tr,
                'failed_refresh'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.shade700,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
              );
            }
          },
          child: Obx(() {
            final weather = controller.currentWeather.value;

            return Stack(
              children: [
                _buildBackgroundGradient(weather?.description, isDarkMode),
                SafeArea(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildAppBar(controller, isDarkMode, context),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(
                                controller,
                                textController,
                                context,
                                isDarkMode,
                                startListening,
                              ),
                              const SizedBox(height: 16),
                              if (controller.searchHistory.isNotEmpty)
                                _buildSearchHistory(controller, isDarkMode),
                              const SizedBox(height: 16),
                              if (controller.isLoading.value)
                                _buildLoadingShimmer(isDarkMode),
                              if (controller.errorMessage.isNotEmpty)
                                _buildErrorCard(controller, isDarkMode),
                              if (weather != null)
                                CurrentWeatherWidget(
                                  weather: weather,
                                  isCelsius: controller.isCelsius.value,
                                ).animate().fadeIn(duration: 400.ms).scale(),
                              if (weather == null &&
                                  controller.errorMessage.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'no_data'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                  ),
                                ),
                              WeatherAlertsWidget(
                                alerts: controller.weatherAlerts,
                              ),
                              const SizedBox(height: 16),
                              HourlyForecastWidget(
                                forecastList: controller.hourlyForecastList,
                                isCelsius: controller.isCelsius.value,
                                isLoading: controller.isLoading.value,
                              ),
                              const SizedBox(height: 16),
                              _buildFiveDayForecast(controller, isDarkMode),
                              const SizedBox(height: 16),
                              if (weather != null)
                                _buildWeatherMap(controller, isDarkMode),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAppBar(
    WeatherController controller,
    bool isDarkMode,
    BuildContext context,
  ) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'weather_app'.tr,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          fontSize: 24,
          shadows: const [
            Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 1)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'menu'.tr,
          icon: Icon(
            Icons.more_vert,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onSelected: (String value) {
            switch (value) {
              case 'toggle_unit':
                controller.toggleUnit();
                break;
              case 'toggle_theme':
                Get.changeThemeMode(
                  isDarkMode ? ThemeMode.light : ThemeMode.dark,
                );
                controller.update();
                break;
              case 'share':
                final weather = controller.currentWeather.value;
                if (weather != null) {
                  Share.share(
                    '${'current_weather'.tr}: ${weather.cityName} - ${weather.temperature}°${controller.isCelsius.value ? 'C' : 'F'}, ${weather.description}',
                    subject: 'weather_app'.tr,
                  );
                } else {
                  Get.snackbar(
                    'Error'.tr,
                    'no_weather_data'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade700,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                }
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'language',
              enabled: false,
              child: PopupMenuButton<Locale>(
                tooltip: 'change_language'.tr,
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<Locale>(
                    value: const Locale('en', 'US'),
                    child: Text('English'),
                  ),
                  PopupMenuItem<Locale>(
                    value: const Locale('es', 'ES'),
                    child: Text('Español'),
                  ),
                  PopupMenuItem<Locale>(
                    value: const Locale('fr', 'FR'),
                    child: Text('Français'),
                  ),
                  PopupMenuItem<Locale>(
                    value: const Locale('hi', 'IN'),
                    child: Text('हिन्दी'),
                  ),
                ],
                onSelected: (Locale locale) {
                  Get.updateLocale(locale);
                  controller.update();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text('change_language'.tr),
                  ],
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_unit',
              child: Row(
                children: [
                  Icon(
                    controller.isCelsius.value
                        ? Icons.thermostat
                        : Icons.ac_unit,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text('toggle_unit'.tr),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_theme',
              child: Row(
                children: [
                  Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(isDarkMode ? 'light_mode'.tr : 'dark_mode'.tr),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  Icon(
                    Icons.share,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text('share_weather'.tr),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(
    WeatherController controller,
    TextEditingController textController,
    BuildContext context,
    bool isDarkMode,
    VoidCallback startListening,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: textController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'search_city'.tr,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: startListening,
                  tooltip: 'voice_search'.tr,
                ),
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    textController.clear();
                    controller.errorMessage.value = '';
                    controller.updateCitySuggestions('');
                  },
                  tooltip: 'clear_search'.tr,
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.grey[900]
                : Colors.white.withOpacity(0.95),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onChanged: (value) {
            controller.updateCitySuggestions(value.trim());
          },
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              controller.updateCity(trimmed);
              textController.clear();
              controller.updateCitySuggestions('');
            } else {
              Get.snackbar(
                'Error'.tr,
                'enter_city'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.shade700,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
              );
            }
          },
        ),
        Obx(
          () => controller.citySuggestions.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]!.withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.citySuggestions.length,
                    itemBuilder: (context, index) {
                      final city = controller.citySuggestions[index];
                      return ListTile(
                        title: Text(
                          city,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          controller.updateCity(city);
                          textController.clear();
                          controller.updateCitySuggestions('');
                        },
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 200.ms)
              : const SizedBox.shrink(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildSearchHistory(WeatherController controller, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.searchHistory.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final city = controller.searchHistory[index];
                return ActionChip(
                  label: Text(
                    city,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onPressed: () => controller.updateCity(city),
                  backgroundColor: isDarkMode
                      ? Colors.grey[700]!.withOpacity(0.5)
                      : Colors.blue.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  elevation: 2,
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              size: 22,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              controller.clearSearchHistory();
              Get.snackbar(
                'Info'.tr,
                'history_cleared'.tr,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blue.shade700,
                colorText: Colors.white,
                margin: const EdgeInsets.all(16),
              );
            },
            tooltip: 'clear_history'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildFiveDayForecast(WeatherController controller, bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.white70,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black26 : Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '5_day_forecast'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDarkMode ? Colors.white : Colors.indigo,
                  fontFamily: 'Roboto',
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 180,
                child: Obx(
                  () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.forecastList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final weather = controller.forecastList[index];
                      final date =
                          DateTime.tryParse(weather.date) ?? DateTime.now();
                      final hour = date.hour;
                      final isNight = hour < 6 || hour > 18;

                      return ForecastCard(
                        weather: weather,
                        isCelsius: controller.isCelsius.value,
                        isNight: isNight,
                      ).animate().fadeIn(duration: 300.ms).slideX();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(WeatherController controller, bool isDarkMode) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade700),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () =>
                  controller.fetchAll(controller.currentCity.value),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingShimmer(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate().shimmer(duration: 1200.ms, color: Colors.white24);
  }

  Widget _buildWeatherMap(WeatherController controller, bool isDarkMode) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              controller.currentLat.value,
              controller.currentLon.value,
            ),
            initialZoom: 10,
          ),
          children: [
            // Base OSM map layer
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),

            // Weather overlay layer from OpenWeatherMap
            TileLayer(
              urlTemplate:
                  'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid={apiKey}',
              additionalOptions: const {
                'apiKey': 'abd9a29ed1bbbc42691ee78be3d9882a',
              },
              tileBuilder: (context, widget, tile) {
                // Add transparency to weather layer
                return Opacity(opacity: 0.5, child: widget);
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBackgroundGradient(String? description, bool isDarkMode) {
    final colors = switch (description?.toLowerCase()) {
      'clear' =>
        isDarkMode
            ? [Colors.blue[900]!, Colors.black]
            : [Colors.blue.shade300, Colors.lightBlueAccent],
      'clouds' =>
        isDarkMode
            ? [Colors.grey[800]!, Colors.black54]
            : [Colors.grey.shade400, Colors.blueGrey.shade200],
      'rain' =>
        isDarkMode
            ? [Colors.blueGrey[700]!, Colors.black87]
            : [Colors.blueGrey.shade600, Colors.indigo.shade300],
      'snow' =>
        isDarkMode
            ? [Colors.grey[700]!, Colors.black54]
            : [Colors.white, Colors.blueGrey.shade100],
      _ =>
        isDarkMode
            ? [Colors.grey[800]!, Colors.black38]
            : [Colors.grey.shade500, Colors.blueAccent.shade100],
    };

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.8],
            ),
          ),
        ),
        if (description != null)
          _buildParticleEffect(
            description,
            isDarkMode,
          ).animate().fadeIn(duration: 600.ms),
      ],
    );
  }

  Widget _buildParticleEffect(String description, bool isDarkMode) {
    switch (description.toLowerCase()) {
      case 'rain':
        return CircularParticle(
          key: const ValueKey('rain_particle'),
          awayRadius: 100,
          numberOfParticles: 100,
          speedOfParticles: 1.5,
          height: Get.height,
          width: Get.width,
          particleColor: isDarkMode
              ? Colors.blue.withOpacity(0.6)
              : Colors.blueAccent,
          maxParticleSize: 5,
          awayAnimationDuration: const Duration(seconds: 3),
          isRandomColor: false,
        );
      case 'snow':
        return CircularParticle(
          key: const ValueKey('snow_particle'),
          awayRadius: 80,
          numberOfParticles: 80,
          speedOfParticles: 1.0,
          height: Get.height,
          width: Get.width,
          particleColor: Colors.white.withOpacity(isDarkMode ? 0.7 : 0.9),
          maxParticleSize: 6,
          awayAnimationDuration: const Duration(seconds: 4),
          isRandomColor: false,
        );
      case 'clouds':
        return CircularParticle(
          key: const ValueKey('cloud_particle'),
          awayRadius: 50,
          numberOfParticles: 30,
          speedOfParticles: 0.8,
          height: Get.height,
          width: Get.width,
          particleColor: Colors.grey.withOpacity(isDarkMode ? 0.5 : 0.7),
          maxParticleSize: 10,
          awayAnimationDuration: const Duration(seconds: 5),
          isRandomColor: false,
        );
      default:
        return const SizedBox.shrink(key: ValueKey('no_particle'));
    }
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherAlertsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> alerts;

  const WeatherAlertsWidget({super.key, required this.alerts});

  @override
  State<WeatherAlertsWidget> createState() => _WeatherAlertsWidgetState();
}

class _WeatherAlertsWidgetState extends State<WeatherAlertsWidget> {
  Set<String> dismissedAlerts = {};

  @override
  void initState() {
    super.initState();
    _loadAndCleanDismissedAlerts();
  }

  Future<void> _loadAndCleanDismissedAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('dismissed_alerts') ?? [];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    dismissedAlerts = stored
        .where((entry) {
          final parts = entry.split('|');
          if (parts.length != 2) return false;
          final endTime = int.tryParse(parts[1]) ?? 0;
          return endTime > now;
        })
        .map((e) => e.split('|')[0])
        .toSet();

    final cleanedList = stored.where((entry) {
      final parts = entry.split('|');
      if (parts.length != 2) return false;
      final endTime = int.tryParse(parts[1]) ?? 0;
      return endTime > now;
    }).toList();
    await prefs.setStringList('dismissed_alerts', cleanedList);

    setState(() {});
  }

  Future<void> _dismissAlert(String id, int? endTime) async {
    final prefs = await SharedPreferences.getInstance();
    final endTimestamp =
        endTime ?? DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;

    dismissedAlerts.add(id);
    final updated = prefs.getStringList('dismissed_alerts') ?? [];
    updated.add('$id|$endTimestamp');
    await prefs.setStringList('dismissed_alerts', updated);

    setState(() {});
  }

  Future<void> _dismissAllAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (var alert in widget.alerts) {
      final eventId = alert['event']?.toString() ?? 'Unknown';
      final endTime = alert['end'] as int? ?? now + 86400; // Default 1 day
      dismissedAlerts.add(eventId);
      final updated = prefs.getStringList('dismissed_alerts') ?? [];
      updated.add('$eventId|$endTime');
      await prefs.setStringList('dismissed_alerts', updated);
    }

    Get.snackbar(
      'Info'.tr,
      'all_alerts_dismissed'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final visibleAlerts = widget.alerts.where((a) => !dismissedAlerts.contains(a['event']?.toString())).toList();

    if (visibleAlerts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Text(
          'no_alerts'.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? Colors.white12 : Colors.white70),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'weather_alerts'.tr,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontFamily: 'Roboto',
                          ),
                    ),
                    if (visibleAlerts.length > 1)
                      TextButton(
                        onPressed: _dismissAllAlerts,
                        child: Text(
                          'dismiss_all'.tr,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: SingleChildScrollView(
                    child: Column(
                      children: visibleAlerts.map((alert) {
                        final eventId = alert['event']?.toString() ?? 'Unknown';
                        final endTime = alert['end'] as int?;

                        return Card(
                          elevation: 4,
                          color: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                  semanticLabel: 'alert_warning'.tr,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              eventId,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 18),
                                            onPressed: () => _dismissAlert(eventId, endTime),
                                            tooltip: 'dismiss_alert'.tr,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        alert['description']?.toString() ?? 'no_description'.tr,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: isDarkMode ? Colors.black87 : Colors.black87,
                                            ),
                                      ),
                                      if (alert['start'] != null)
                                        Text(
                                          'start'.tr +
                                              ': ${DateTime.fromMillisecondsSinceEpoch(alert['start'] * 1000).toLocal()}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isDarkMode ? Colors.grey[600] : Colors.grey,
                                              ),
                                        ),
                                      if (endTime != null)
                                        Text(
                                          'end'.tr +
                                              ': ${DateTime.fromMillisecondsSinceEpoch(endTime * 1000).toLocal()}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isDarkMode ? Colors.grey[600] : Colors.grey,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
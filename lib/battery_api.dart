import 'package:flutter/services.dart';

class BatteryComplianceStatus {
  final int sdkInt;
  final bool backgroundRestricted;
  final bool ignoringOptimizations;
  final bool powerSaveMode;
  final String manufacturer;
  final String brand;
  final String model;

  BatteryComplianceStatus({
    required this.sdkInt,
    required this.backgroundRestricted,
    required this.ignoringOptimizations,
    required this.powerSaveMode,
    required this.manufacturer,
    required this.brand,
    required this.model,
  });

  factory BatteryComplianceStatus.fromMap(Map<dynamic, dynamic> m) {
    return BatteryComplianceStatus(
      sdkInt: (m['sdkInt'] ?? 0) as int,
      backgroundRestricted: (m['backgroundRestricted'] ?? false) as bool,
      ignoringOptimizations: (m['ignoringOptimizations'] ?? false) as bool,
      powerSaveMode: (m['powerSaveMode'] ?? false) as bool,
      manufacturer: (m['manufacturer'] ?? '').toString(),
      brand: (m['brand'] ?? '').toString(),
      model: (m['model'] ?? '').toString(),
    );
  }
}

class BatteryComplianceApi {
  static const _ch = MethodChannel('battery_compliance');

  static Future<BatteryComplianceStatus> status() async {
    final map = await _ch.invokeMethod('status');
    return BatteryComplianceStatus.fromMap(Map<dynamic, dynamic>.from(map));
  }

  static Future<void> openAppDetails() => _ch.invokeMethod('openAppDetails');
  static Future<void> requestIgnoreOptimizations() =>
      _ch.invokeMethod('requestIgnoreOptimizations');
  static Future<void> openOptimizationSettings() =>
      _ch.invokeMethod('openOptimizationSettings');
}

// ===============================
// OEM PROFILE
// ===============================

import 'dart:convert';

import 'package:flutter/services.dart';

class OemProfile {
  final String id;
  final List<String> manufacturerAny;
  final List<String> keywordsAny;
  final String title;
  final bool requiresUserConfirmation;
  final List<Map<String, String>> userConfirmations;
  final List<String> steps;

  OemProfile({
    required this.id,
    required this.manufacturerAny,
    required this.keywordsAny,
    required this.title,
    required this.requiresUserConfirmation,
    required this.userConfirmations,
    required this.steps,
  });

  factory OemProfile.fromJson(Map<String, dynamic> j) {
    final match = (j['match'] ?? {}) as Map<String, dynamic>;

    return OemProfile(
      id: j['id'],
      manufacturerAny: List<String>.from(match['manufacturer_any'] ?? const []),
      keywordsAny: List<String>.from(match['keywords_any'] ?? const []),
      title: j['title'],
      requiresUserConfirmation: j['requires_user_confirmation'] == true,
      userConfirmations: List<Map<String, String>>.from(
        (j['user_confirmations'] ?? const [])
            .map((e) => Map<String, String>.from(e)),
      ),
      steps: List<String>.from(j['steps'] ?? const []),
    );
  }

  // 🔥 MATCH FLEXIBLE (SOPORTA manufacturer_any + keywords_any)
  bool matchesFlexible({
    required String manufacturer,
    required String brand,
    required String model,
  }) {
    final m = manufacturer.toLowerCase();
    final b = brand.toLowerCase();
    final mo = model.toLowerCase();

    // 1️⃣ Compatibilidad vieja (manufacturer_any)
    if (manufacturerAny.isNotEmpty) {
      if (manufacturerAny.contains('*')) return true;
      if (manufacturerAny.map((e) => e.toLowerCase()).contains(m)) {
        return true;
      }
    }

    // 2️⃣ NUEVO MATCH por keywords_any (HONOR/Xiaomi/OPPO/etc)
    for (final kw in keywordsAny) {
      final k = kw.toLowerCase();
      if (m.contains(k) || b.contains(k) || mo.contains(k)) {
        return true;
      }
    }

    return false;
  }
}

// ===============================
// CONFIG
// ===============================

class ComplianceConfig {
  final int version;
  final List<OemProfile> profiles;

  ComplianceConfig({
    required this.version,
    required this.profiles,
  });

  factory ComplianceConfig.fromJson(Map<String, dynamic> j) {
    return ComplianceConfig(
      version: j['version'] ?? 1,
      profiles: List<Map<String, dynamic>>.from(j['oem_profiles'] ?? const [])
          .map(OemProfile.fromJson)
          .toList(),
    );
  }

  // 🔥 RESOLVER FLEXIBLE (NO NECESITAS TOCARLO NUNCA MÁS)
  OemProfile resolveForFlexible({
    required String manufacturer,
    required String brand,
    required String model,
  }) {
    // 1️⃣ Busca perfiles específicos primero
    for (final p in profiles) {
      final isGeneric =
          p.manufacturerAny.contains('*') && p.keywordsAny.isEmpty;

      if (!isGeneric &&
          p.matchesFlexible(
            manufacturer: manufacturer,
            brand: brand,
            model: model,
          )) {
        return p;
      }
    }

    // 2️⃣ Fallback genérico
    return profiles.firstWhere(
      (p) => p.manufacturerAny.contains('*'),
      orElse: () => profiles.first,
    );
  }

    // 👇 ESTA ES LA QUE ESTÁS USANDO
  static Future<ComplianceConfig> loadAsset() async {
    final raw =
    await rootBundle.loadString('assets/compliance_config.json');

    final jsonMap = json.decode(raw) as Map<String, dynamic>;

    return ComplianceConfig.fromJson(jsonMap);
  }
}
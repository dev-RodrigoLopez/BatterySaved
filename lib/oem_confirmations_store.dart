import 'package:shared_preferences/shared_preferences.dart';

class OemConfirmationsStore {
  static String _k(String configVersion, String profileId) =>
      'compliance:$configVersion:$profileId:confirmed';

  static Future<Set<String>> getConfirmedIds({
    required int configVersion,
    required String profileId,
  }) async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList(_k('$configVersion', profileId)) ?? const [])
        .toSet();
  }

  static Future<void> setConfirmedIds({
    required int configVersion,
    required String profileId,
    required Set<String> ids,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_k('$configVersion', profileId), ids.toList());
  }
}

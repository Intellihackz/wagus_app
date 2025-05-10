import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConfigService {
  final _doc =
      FirebaseFirestore.instance.collection('app_config').doc('global');

  Future<bool> isKillSwitchEnabled() async {
    final docSnap = await _doc.get();
    final killSwitch = docSnap.data()?['kill_switch'] == true;

    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    final killBelow = docSnap.data()?['kill_below_version'];

    if (killBelow != null && _compareVersions(current, killBelow) < 0) {
      return true;
    }

    return killSwitch;
  }

  Future<bool> isAppOutdated() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      final docSnap = await _doc.get();
      final minVersion = docSnap.data()?['min_supported_version'];

      if (minVersion == null) return false;
      return _compareVersions(current, minVersion) < 0;
    } catch (e) {
      print('❌ Error checking version: $e');
      return false; // Or return true to block app if you want extra safety
    }
  }

  int _compareVersions(String a, String b) {
    try {
      final aParts = a.split('.').map(int.parse).toList();
      final bParts = b.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final diff = aParts[i] - bParts[i];
        if (diff != 0) return diff;
      }
      return 0;
    } catch (e) {
      return -1; // Assume outdated if comparison fails
    }
  }
}

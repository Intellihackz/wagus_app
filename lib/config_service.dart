import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ConfigService {
  final _doc =
      FirebaseFirestore.instance.collection('app_config').doc('global');

  Future<bool> isKillSwitchEnabled() async {
    final docSnap = await _doc.get();
    return docSnap.data()?['kill_switch'] == true;
  }

  Future<bool> isAppOutdated() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;

    final docSnap = await _doc.get();
    final minVersion = docSnap.data()?['min_supported_version'];

    if (minVersion == null) return false;
    return _compareVersions(current, minVersion) < 0;
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final diff = aParts[i] - bParts[i];
      if (diff != 0) return diff;
    }
    return 0;
  }
}

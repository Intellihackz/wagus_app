import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';

void useAsyncEffect({
  required FutureOr<dynamic> Function() effect,
  FutureOr<dynamic> Function()? cleanup,
  List<Object?>? keys,
}) {
  useEffect(() {
    Future.microtask(effect);
    return () {
      if (cleanup != null) {
        Future.microtask(cleanup);
      }
    };
  }, keys);
}

extension StringManipulation on String {
  String get trimmed => trim();
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String pluralize(int number) => number == 1 ? this : '${this}s';
}

extension NumberFormatter on num {
  String toCompact() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed((this % 1000000 == 0) ? 0 : 1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed((this % 1000 == 0) ? 0 : 1)}K';
    } else {
      return toStringAsFixed(0);
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Entry point for the Yomu application.
void main() {
  runApp(const ProviderScope(child: YomuApp()));
}

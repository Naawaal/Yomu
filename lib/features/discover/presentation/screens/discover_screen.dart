import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extensions/presentation/screens/extensions_store_screen.dart';

/// Discover screen wrapper for top-level extensions browsing.
class DiscoverScreen extends StatelessWidget {
  /// Creates the discover screen.
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: ExtensionsStoreScreen());
  }
}

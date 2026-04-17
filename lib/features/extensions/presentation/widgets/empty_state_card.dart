import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/widgets.dart';

/// Empty state card shown when no extensions are available.
class EmptyStateCard extends StatelessWidget {
  /// Creates an empty state card.
  const EmptyStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: AppStrings.noExtensionsTitle,
      description: AppStrings.noExtensionsBody,
      icon: Ionicons.search_outline,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/library/presentation/screens/library_screen.dart';
import 'package:yomu/features/library/presentation/widgets/library_entry_card.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('renders app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Library'), findsWidgets);
    });

    testWidgets('renders library entries after initial fetch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LibraryEntryCard), findsWidgets);
    });
  });
}

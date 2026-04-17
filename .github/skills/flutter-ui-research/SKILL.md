---
name: flutter-ui-research
description: >
  Material 3 UI patterns, component selection, theming, animations, and responsive design 
  for Flutter. Use this skill when designing screens, selecting M3 components, setting up 
  a theme, implementing animations, building responsive layouts, or creating empty/error/loading states.
argument-hint: "[screen type or UI pattern to research]"
---

# Flutter Material 3 UI Skill

## M3 Theme Setup (The Only Correct Way)

```dart
// shared/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ONE seed color. M3 generates the entire palette from this.
  static const Color _seedColor = Color(0xFF6750A4); // Replace with brand color

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    // Typography — override only if using a custom font
    textTheme: _textTheme,
    // Component themes
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: _textTheme,
  );

  static const TextTheme _textTheme = TextTheme(
    // Only needed if using custom fonts:
    // displayLarge: TextStyle(fontFamily: 'YourFont'),
  );
}
```

## M3 Color Roles — Reference Card

| Role | Use Case |
|------|----------|
| `primary` | Primary actions, FAB, key UI elements |
| `onPrimary` | Text/icons on primary color |
| `primaryContainer` | Tonal buttons, selected states |
| `onPrimaryContainer` | Text on primary container |
| `secondary` | Less prominent UI elements |
| `tertiary` | Contrasting accents, complementary |
| `surface` | Default background (cards, sheets) |
| `surfaceVariant` | Alternative surface (chips, menus) |
| `surfaceContainerLowest` | Very subtle backgrounds |
| `surfaceContainerLow` | Slightly elevated surfaces |
| `surfaceContainer` | Cards, dialogs |
| `surfaceContainerHigh` | Elevated cards |
| `surfaceContainerHighest` | Highest elevation surfaces |
| `outline` | Borders, dividers |
| `outlineVariant` | Subtle borders |
| `error` | Error states |
| `onError` | Text on error |

```dart
// CORRECT usage:
color: Theme.of(context).colorScheme.primary
color: Theme.of(context).colorScheme.surfaceContainer

// NEVER:
color: Colors.blue  // ❌
color: Color(0xFF6750A4)  // ❌ (even your own colors)
```

## M3 Typography Scale

```dart
// Use these exact tokens:
Theme.of(context).textTheme.displayLarge   // 57sp, headlines
Theme.of(context).textTheme.displayMedium  // 45sp
Theme.of(context).textTheme.displaySmall   // 36sp
Theme.of(context).textTheme.headlineLarge  // 32sp, screen titles
Theme.of(context).textTheme.headlineMedium // 28sp
Theme.of(context).textTheme.headlineSmall  // 24sp
Theme.of(context).textTheme.titleLarge     // 22sp, app bars, dialogs
Theme.of(context).textTheme.titleMedium    // 16sp, list items
Theme.of(context).textTheme.titleSmall     // 14sp, small titles
Theme.of(context).textTheme.bodyLarge      // 16sp, primary body text
Theme.of(context).textTheme.bodyMedium     // 14sp, secondary body text
Theme.of(context).textTheme.bodySmall      // 12sp, captions
Theme.of(context).textTheme.labelLarge     // 14sp, buttons
Theme.of(context).textTheme.labelMedium    // 12sp, chips, tabs
Theme.of(context).textTheme.labelSmall     // 11sp, badges
```

## M3 Component Selection Guide

### Buttons
```dart
// Primary action — filled
FilledButton(onPressed: () {}, child: Text('Submit'))
FilledButton.icon(onPressed: () {}, icon: Icon(Icons.add), label: Text('Add'))

// Secondary — outlined  
OutlinedButton(onPressed: () {}, child: Text('Cancel'))

// Tertiary — text
TextButton(onPressed: () {}, child: Text('Learn more'))

// Floating action
FloatingActionButton(onPressed: () {}, child: Icon(Icons.add))
FloatingActionButton.extended(onPressed: () {}, icon: Icon(Icons.add), label: Text('New Item'))
```

### Navigation
```dart
// Bottom navigation (3-5 destinations)
NavigationBar(  // NOT BottomNavigationBar
  destinations: [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
  ],
  selectedIndex: _index,
  onDestinationSelected: (i) => setState(() => _index = i),
)

// Side navigation (tablet/desktop or drawer)
NavigationDrawer(
  children: [
    NavigationDrawerDestination(icon: Icon(Icons.home), label: Text('Home')),
  ],
)

// Tabs
TabBar(tabs: [...])  // Use with DefaultTabController
```

### App Bars
```dart
// Standard scrollable screen — use sliver variants
CustomScrollView(
  slivers: [
    SliverAppBar.medium(    // Collapses on scroll, medium size
      title: Text('Screen Title'),
      actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})],
    ),
    // or SliverAppBar.large() for more prominent headers
    SliverList(...),
  ],
)

// Modal / dialog screens — standard AppBar
AppBar(title: Text('Details'))
```

### Cards & Surfaces
```dart
// Content card
Card(
  elevation: 0,  // M3 cards use 0 elevation + color for depth
  color: Theme.of(context).colorScheme.surfaceContainer,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: content,
  ),
)

// Elevated card (use sparingly)
Card(elevation: 2, child: ...)

// Surface for modals / bottom sheets
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
)
```

### Lists
```dart
// Standard list tile
ListTile(
  leading: CircleAvatar(child: Icon(Icons.person)),
  title: Text('Title', style: Theme.of(context).textTheme.titleMedium),
  subtitle: Text('Subtitle', style: Theme.of(context).textTheme.bodyMedium),
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)

// Dismissible list item
Dismissible(
  key: Key(item.id),
  background: Container(color: Theme.of(context).colorScheme.errorContainer),
  child: ListTile(...),
)
```

## Animation Patterns

### Page Transitions (M3)
```dart
// In GoRouter:
import 'package:animations/animations.dart';

// Shared axis (recommended for navigation flows)
CustomTransitionPage(
  child: const TargetPage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      child: child,
    );
  },
)

// Container transform (for hero-like transitions from a card)
OpenContainer(
  transitionType: ContainerTransitionType.fadeThrough,
  openBuilder: (context, _) => const DetailPage(),
  closedBuilder: (context, openContainer) => Card(
    child: InkWell(onTap: openContainer, child: content),
  ),
)
```

### List Animations
```dart
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

AnimationLimiter(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(child: ItemWidget(items[index])),
        ),
      );
    },
  ),
)
```

### State Transitions
```dart
// Switching between loading/error/data
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _buildContent(key: ValueKey(state.runtimeType)),
)

// Number/value changes
AnimatedDefaultTextStyle(...)
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: newValue),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  builder: (context, value, _) => Text(value.toStringAsFixed(0)),
)
```

## Loading / Skeleton States

```dart
import 'package:shimmer/shimmer.dart';

// Always match the shape of the real content
Shimmer.fromColors(
  baseColor: Theme.of(context).colorScheme.surfaceContainer,
  highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  child: Column(
    children: [
      // Mimic the real layout with placeholder containers
      Container(width: double.infinity, height: 200, color: Colors.white),
      const SizedBox(height: 12),
      Container(width: 200, height: 20, color: Colors.white),
      const SizedBox(height: 8),
      Container(width: 150, height: 16, color: Colors.white),
    ],
  ),
)
```

## Empty State Pattern

```dart
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Error State Pattern

```dart
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 72, color: colorScheme.error),
            const SizedBox(height: 24),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Responsive Layout Pattern

```dart
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  final Widget mobile;
  final Widget tablet;

  // M3 breakpoints
  static const double _tabletBreakpoint = 600;
  static const double _desktopBreakpoint = 840;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _tabletBreakpoint) {
          return tablet;
        }
        return mobile;
      },
    );
  }
}

// Usage in a screen:
ResponsiveLayout(
  mobile: _MobileProductsView(products: products),
  tablet: _TabletProductsView(products: products),
)
```

## Custom Font Setup

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: YourFont
      fonts:
        - asset: assets/fonts/YourFont-Regular.ttf
        - asset: assets/fonts/YourFont-Medium.ttf
          weight: 500
        - asset: assets/fonts/YourFont-Bold.ttf
          weight: 700
```

```dart
// In ThemeData:
ThemeData(
  textTheme: GoogleFonts.interTextTheme(),  // Example with google_fonts package
  // or for custom fonts:
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'YourFont'),
    // Apply to all relevant styles...
  ),
)
```

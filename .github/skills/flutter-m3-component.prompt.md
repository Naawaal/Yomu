---
name: flutter-m3-component
description: Generate a single Material 3 Flutter widget or component with full state handling. Use for atomic components like cards, tiles, buttons, dialogs, and custom widgets.
---

# Flutter M3 Component Skill

Generate a **single, self-contained Material 3 Flutter component**. This skill is for atomic widgets, not full screens.

## Required Input
Provide:
1. Component name (e.g., `AudioTrackTile`, `RecordingCard`, `WaveformSlider`)
2. What data it displays (props/parameters)
3. What interactions it supports (tap, swipe, long-press, etc.)
4. Any special behavior (animated, expandable, selectable, etc.)

## Component Output Checklist

Every component you generate must have:

- `const` constructor
- Named parameters with types (no positional params for components)
- Callbacks typed as `VoidCallback` or `ValueChanged<T>` (never anonymous inline logic)
- Colors from `Theme.of(context).colorScheme`
- Text styles from `Theme.of(context).textTheme`
- `Semantics` wrapper if the widget is interactive and not using a built-in M3 component
- `tooltip` on all `IconButton` widgets

## Template

```dart
class ${ComponentName} extends StatelessWidget {
  const ${ComponentName}({
    super.key,
    required this.${primaryData},
    this.onTap,
    // other params
  });

  final ${DataType} ${primaryData};
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      label: '${Component description for screen readers}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: /* content */,
      ),
    );
  }
}
```

## Animation Variant
If the component has animated state, use `StatefulWidget` with `SingleTickerProviderStateMixin`:

```dart
class ${AnimatedComponentName} extends StatefulWidget {
  const ${AnimatedComponentName}({super.key, required this.isSelected, this.onTap});

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<${AnimatedComponentName}> createState() => _${AnimatedComponentName}State();
}

class _${AnimatedComponentName}State extends State<${AnimatedComponentName}>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: /* content */,
    );
  }
}
```

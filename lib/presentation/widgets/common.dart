import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';

/// "Recent Reports ........ See all"
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

/// Summary tile: icon well, big number, label.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.card,
              child: Icon(icon, size: 20, color: foreground),
            ),
            const SizedBox(height: 6),
            Text(value, style: t.titleLarge),
            Text(label,
                style: t.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Soft tinted message box with an icon.
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.message, this.warning = false});

  final IconData icon;
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning ? c.submittedBg : c.iceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: warning ? c.submitted : c.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.navy))),
        ],
      ),
    );
  }
}

/// Circle with the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.radius = 24});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.ice,
      child: Text(initials,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: c.navy, fontSize: radius * 0.65)),
    );
  }
}

/// Centered spinner for loading lists/screens.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
}

/// Icon + title + message (+ optional action), for empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  const MessageView.error({super.key, required this.message, this.onAction})
      : icon = Symbols.cloud_off_rounded,
        title = 'Something went wrong',
        actionLabel = 'Try again';

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 36, backgroundColor: c.iceSoft, child: Icon(icon, size: 34, color: c.primary)),
            const SizedBox(height: 16),
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, style: t.bodyMedium?.copyWith(color: c.textMuted), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating snackbar; [error] uses the error colours.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Symbols.error_rounded : Symbols.check_circle_rounded,
            color: error ? c.errorBg : c.onHero, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: error ? c.error : null,
    ));
}

/// Primary button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final child = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onPrimary))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label),
          ]);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}

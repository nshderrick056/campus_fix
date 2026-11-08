import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/theme_toggle_button.dart';

/// ALU campus photo behind the top of the login/register screens.
const authHeroAsset = 'assets/images/auth_hero.webp';

/// Login/register frame: gradient backdrop, illustration on top and a
/// rounded translucent card holding the title and form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.leading,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shown top-left over the illustration (e.g. a back button).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark ? [c.surface, c.deep] : [c.surface, c.iceSoft],
          ),
        ),
        child: Stack(children: [
          // Soft glow under the card, like the reference's light blobs.
          _Glow(color: c.primary, size: 260, bottom: -90, left: -100),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(children: [
                  const _Hero(),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 4,
                    // White icons over the photo's darkened top edge.
                    child: IconTheme(
                      data: IconThemeData(color: c.onHero),
                      child: Row(children: [
                        leading ?? const Padding(padding: EdgeInsets.all(8), child: BrandLogo(size: 40)),
                        const Spacer(),
                        const ThemeToggleButton(),
                      ]),
                    ),
                  ),
                ]),
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    decoration: BoxDecoration(
                      color: c.card.withValues(alpha: dark ? 0.82 : 0.92),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: c.border),
                      boxShadow: [
                        BoxShadow(color: c.deep.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: t.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(subtitle, style: t.bodyMedium?.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, this.left, this.bottom});

  final Color color;
  final double size;
  final double? left, bottom;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        bottom: bottom,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
            ),
          ),
        ),
      );
}

/// Full-width campus photo that fades into the page; falls back to a
/// built-in icon scene if the asset is missing.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(
          authHeroAsset,
          fit: BoxFit.cover,
          // The building sits in the lower half of the photo.
          alignment: const Alignment(0, 0.45),
          semanticLabel: 'ALU campus',
          errorBuilder: (_, _, _) => const _FallbackHero(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.35, 0.75, 1],
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                c.surface.withValues(alpha: 0.35),
                c.surface,
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _FallbackHero extends StatelessWidget {
  const _FallbackHero();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget bubble(IconData icon, double size, Color bg, Color fg) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.deep.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Icon(icon, size: size * 0.5, color: fg, fill: 1),
        );
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [c.primary, c.sky], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.45), blurRadius: 40, offset: const Offset(0, 14))],
          ),
          child: Icon(Symbols.apartment_rounded, size: 80, color: c.onPrimary, fill: 1),
        ),
        Positioned(left: 62, top: 46, child: bubble(Symbols.water_drop_rounded, 46, c.card, c.inProgress)),
        Positioned(right: 58, top: 30, child: bubble(Symbols.bolt_rounded, 54, c.card, c.submitted)),
        Positioned(right: 70, bottom: 34, child: bubble(Symbols.check_circle_rounded, 44, c.card, c.resolved)),
        Positioned(left: 78, bottom: 30, child: bubble(Symbols.chair_rounded, 40, c.card, c.primary)),
      ],
    );
  }
}

/// Label shown above a field, as in the reference design.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

/// Full-width gradient primary button with a loading state.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Light: navy→primary with white text; dark: light blues with navy text.
    final colors = dark ? [c.primary, c.sky] : [c.navy, c.primary];
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled || loading ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              child: Center(
                child: loading
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onPrimary))
                    : Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.onPrimary, fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "—— Or continue with ——" divider plus the Google button.
class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key, required this.caption, required this.onGoogle});

  final String caption;
  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Row(children: [
        const Expanded(child: Divider()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(caption, style: t.bodySmall)),
        const Expanded(child: Divider()),
      ]),
      const SizedBox(height: 14),
      Material(
        color: c.iceSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onGoogle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('G', style: t.titleLarge?.copyWith(color: const Color(0xFF4285F4), fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(width: 10),
              Flexible(child: Text('Google (ALU account)', style: t.labelLarge, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

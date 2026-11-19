import 'package:flutter/material.dart';

import '../theme/pace_tokens.dart';
import 'pace_wordmark.dart';
import 'tuck.dart';

/// The hand-off from the native splash on a cold start. It opens on exactly
/// what the native splash shows (Tuck peeking from the shell, the wordmark
/// near the bottom), then Tuck comes out and says hello, the wordmark rises
/// under Tuck, the tagline fades in, and the whole layer fades away.
///
/// The app is built underneath the whole time, so nothing waits on this.
/// A tap skips to the fade. Reduced motion keeps only fades; low-energy
/// mode skips straight to the fade.
class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key});

  /// Native splash geometry (res/drawable/launch_background.xml).
  static const peekSize = 240.0;
  static const wordmarkHeight = 30.0; // 120 dp wide
  static const wordmarkNativeCenterFromBottom = 48.0 + 40.0;

  static const peekAsset = 'assets/mascot/splash_tuck.png';

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _done = false;
  bool _exiting = false;
  bool _reduced = false;

  // Timeline in ms (full motion); the reduced one is set in _start.
  static const _full = 1240.0;
  static const _exitAt = 1000.0;
  static const _reducedTotal = 440.0;
  static const _reducedExitAt = 240.0;

  double get _total => _reduced ? _reducedTotal : _full;
  double get _exitStart => _reduced ? _reducedExitAt : _exitAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.duration != null) return;
    final motion = PaceMotion.of(context);
    _reduced = motion.reduced;
    _c.duration = Duration(milliseconds: _total.round());
    if (motion.calm) {
      // Low-energy: no show, just let the app through.
      _c.value = _exitStart / _total;
      _exiting = true;
    }
    precacheImage(const AssetImage(SplashIntro.peekAsset), context);
    // A status listener, not the forward() future: a skip restarts the
    // controller, which cancels that future.
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    _c.forward();
  }

  void _skip() {
    if (_exiting || _done) return;
    _exiting = true;
    final at = _exitStart / _total;
    if (_c.value < at) {
      _c.value = at;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0..1 progress of the window [start, start + length] (ms).
  double _window(double ms, double start, double length, [Curve? curve]) {
    final p = ((ms - start) / length).clamp(0.0, 1.0);
    return curve == null ? p : curve.transform(p);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      key: const ValueKey('splash-intro'),
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: Semantics(
        label: 'PACE. Progress Always Comes Eventually',
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * _total;
            final exit = _window(ms, _exitStart, _total - _exitStart);
            return Opacity(
              opacity: 1 - Curves.easeIn.transform(exit),
              child: Transform.scale(
                scale: _reduced ? 1 : 1 - .02 * exit,
                child: ColoredBox(
                  color: scheme.surface,
                  child: LayoutBuilder(
                    builder: (context, box) => _stage(context, box, ms),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _stage(BuildContext context, BoxConstraints box, double ms) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final h = box.maxHeight;
    final center = h / 2;

    // Lead: the peek art hands over to Tuck, out of the shell.
    final peekOut = _reduced
        ? _window(ms, 0, 200)
        : _window(ms, 0, 240, PaceMotion.easeOut);
    // Support: the wordmark rises from the native spot to under Tuck.
    final rise = _reduced ? 1.0 : _window(ms, 120, 560, PaceMotion.easeOut);
    final wordmarkIn = _reduced ? _window(ms, 0, 200) : 1.0;
    // Decoration: the tagline only fades.
    final tagline = _reduced
        ? _window(ms, 0, 200)
        : _window(ms, 420, 360, Curves.easeOut);

    const tuckSize = 180.0; // body about as wide as the peek art
    final wordmarkFrom = h - SplashIntro.wordmarkNativeCenterFromBottom;
    final wordmarkTo = center + tuckSize / 2 + 28;
    final wordmarkY = wordmarkFrom + (wordmarkTo - wordmarkFrom) * rise;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: center - tuckSize / 2,
          height: tuckSize,
          // Tuck fades itself in as it settles; only a still Tuck (reduced
          // motion) needs the cross-fade here.
          child: Opacity(
            opacity: _reduced ? peekOut : 1,
            child: Center(
              child: Tuck(
                key: const ValueKey('splash-tuck'),
                size: tuckSize,
                greet: !_reduced,
              ),
            ),
          ),
        ),
        if (peekOut < 1)
          Positioned(
            left: 0,
            right: 0,
            top: center - SplashIntro.peekSize / 2,
            height: SplashIntro.peekSize,
            child: Opacity(
              opacity: 1 - peekOut,
              child: Transform.scale(
                scale: _reduced ? 1 : 1 - .04 * peekOut,
                child: Image.asset(
                  SplashIntro.peekAsset,
                  width: SplashIntro.peekSize,
                  height: SplashIntro.peekSize,
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: wordmarkY - SplashIntro.wordmarkHeight / 2,
          child: Opacity(
            opacity: wordmarkIn,
            child: Center(
              child: PaceWordmark(
                height: SplashIntro.wordmarkHeight,
                color: scheme.secondary,
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: wordmarkY + SplashIntro.wordmarkHeight / 2 + 14,
          child: Opacity(
            opacity: tagline,
            child: Text(
              'Progress Always Comes Eventually',
              key: const ValueKey('splash-tagline'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

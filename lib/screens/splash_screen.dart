// Launch splash: game logo + name, animated loading line,
// "Credits: WAJIHA" with the official company logo.
// Pre-warms audio and applies the saved theme while it shows.
import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/prefs.dart';
import '../services/iap_service.dart';
import '../theme/face_styles.dart';
import '../theme/garden_themes.dart';
import '../ui/zen.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;
  const SplashScreen(
      {super.key,
      required this.audio,
      required this.prefs,
      required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _run();
  }

  Future<void> _run() async {
    // Apply the saved look before the first frame of real UI.
    GardenThemes.apply(widget.prefs.themeId,
        custom: widget.prefs.customTheme);
    FaceStyles.apply(widget.prefs.faceStyleId);
    // Pre-warm audio while the splash shows, then start menu music.
    await widget.audio.prewarm();
    await widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          prefs: widget.prefs,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Zen.sand,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Zen.cedar, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Zen.sumiInk.withValues(alpha: 0.35),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/tilesolitaire_logo.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 22),
            Text('Tile Solitaire', style: Zen.heading(40)),
            const SizedBox(height: 6),
            Text(
              'A QUIET GARDEN OF MATCHING TILES',
              style: Zen.chipLabel.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Zen.sandGroove.withValues(alpha: 0.6),
                        border: Border.all(
                            color: Zen.darkCedar.withValues(alpha: 0.4)),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Zen.deepMoss,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _loader.value < 1 ? 'Raking the sand…' : 'Ready!',
                      style: Zen.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Zen.chipLabel.copyWith(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

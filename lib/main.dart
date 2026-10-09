// Tile Solitaire - a calm zen-garden tile-matching game by Wajiha.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/audio_service.dart';
import 'game/prefs.dart';
import 'screens/menu_screen.dart';
import 'ui/zen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = GamePrefs();
  await prefs.load();

  final audio = AudioService();
  audio.musicEnabled = prefs.musicOn;
  audio.sfxEnabled = prefs.sfxOn;
  audio.musicVolume = prefs.musicVol;
  audio.sfxVolume = prefs.sfxVol;
  await audio.init();

  runApp(TileSolitaireApp(audio: audio, prefs: prefs));
}

class TileSolitaireApp extends StatelessWidget {
  const TileSolitaireApp(
      {super.key, required this.audio, required this.prefs});
  final AudioService audio;
  final GamePrefs prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Solitaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Zen.sand,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Zen.moss,
          surface: Zen.paperWhite,
        ),
        textTheme: const TextTheme(
          bodyMedium: Zen.body,
          bodyLarge: Zen.body,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Zen.deepMoss),
        ),
      ),
      home: MenuScreen(audio: audio, prefs: prefs),
    );
  }
}

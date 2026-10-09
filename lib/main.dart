// Tile Solitaire - a calm zen-garden tile-matching game by Wajiha.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/audio_service.dart';
import 'game/prefs.dart';
import 'services/iap_service.dart';
import 'screens/splash_screen.dart';
import 'theme/garden_themes.dart';
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

  final store = StoreService();
  await store.init();

  runApp(TileSolitaireApp(audio: audio, prefs: prefs, store: store));
}

class TileSolitaireApp extends StatelessWidget {
  const TileSolitaireApp(
      {super.key,
      required this.audio,
      required this.prefs,
      required this.store});
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Solitaire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Zen.sand,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GardenThemes.current.deepMoss,
          surface: GardenThemes.current.paperWhite,
        ),
        textTheme: TextTheme(
          bodyMedium: Zen.body,
          bodyLarge: Zen.body,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: GardenThemes.current.deepMoss),
        ),
      ),
      home: SplashScreen(audio: audio, prefs: prefs, store: store),
    );
  }
}

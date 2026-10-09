// Local persistence via shared_preferences: settings, profile, theme,
// face style, best records, layout progress, daily garden, and the
// in-progress game (for backgrounding / continue).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme/garden_themes.dart';

class GamePrefs {
  bool musicOn = true;
  bool sfxOn = true;
  double musicVol = 0.7;
  double sfxVol = 0.8;
  int bestScore = 0;
  int bestTimeSec = 0; // fastest win, 0 = none yet
  String? savedGame;

  // Player profile.
  String playerName = 'Gardener';

  // Look & feel.
  String themeId = 'classic';
  String? customThemeJson; // GardenPalette JSON when themeId == 'custom'
  String faceStyleId = 'classic';
  int difficultyIdx = 1; // Difficulty.classic
  int layoutIdx = 0;

  // Pro unlock (persisted; also re-armed from the purchase stream).
  bool pro = false;

  // Per-layout progress: best score + cleared flag.
  final Map<int, int> layoutBest = {};
  final Set<int> layoutsCleared = {};

  // Daily garden: best score per date + streak of days played.
  final Map<String, int> dailyBest = {};
  int dailyStreak = 0;
  String? lastDailyDate;

  GardenPalette? get customTheme => customThemeJson == null
      ? null
      : GardenPalette.fromJson(
          (jsonDecode(customThemeJson!) as Map).cast<String, dynamic>());

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool('ts_music') ?? true;
    sfxOn = p.getBool('ts_sfx') ?? true;
    musicVol = p.getDouble('ts_music_vol') ?? 0.7;
    sfxVol = p.getDouble('ts_sfx_vol') ?? 0.8;
    bestScore = p.getInt('ts_best_score') ?? 0;
    bestTimeSec = p.getInt('ts_best_time') ?? 0;
    savedGame = p.getString('ts_saved_game');
    playerName = p.getString('ts_player_name') ?? 'Gardener';
    themeId = p.getString('ts_theme') ?? 'classic';
    customThemeJson = p.getString('ts_custom_theme');
    faceStyleId = p.getString('ts_face_style') ?? 'classic';
    difficultyIdx = p.getInt('ts_difficulty') ?? 1;
    layoutIdx = p.getInt('ts_layout') ?? 0;
    pro = p.getBool('ts_pro') ?? false;
    final lb = p.getString('ts_layout_best');
    if (lb != null) {
      for (final e in (jsonDecode(lb) as Map).entries) {
        layoutBest[int.parse(e.key as String)] = (e.value as num).toInt();
      }
    }
    layoutsCleared.addAll((p.getStringList('ts_layouts_cleared') ?? [])
        .map(int.parse)
        .where((i) => i >= 0));
    final db = p.getString('ts_daily_best');
    if (db != null) {
      for (final e in (jsonDecode(db) as Map).entries) {
        dailyBest[e.key as String] = (e.value as num).toInt();
      }
    }
    dailyStreak = p.getInt('ts_daily_streak') ?? 0;
    lastDailyDate = p.getString('ts_last_daily');
  }

  Future<void> saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ts_music', musicOn);
    await p.setBool('ts_sfx', sfxOn);
    await p.setDouble('ts_music_vol', musicVol);
    await p.setDouble('ts_sfx_vol', sfxVol);
  }

  Future<void> saveRecords() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('ts_best_score', bestScore);
    await p.setInt('ts_best_time', bestTimeSec);
  }

  Future<void> saveProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ts_player_name', playerName);
  }

  Future<void> saveLook() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ts_theme', themeId);
    if (customThemeJson == null) {
      await p.remove('ts_custom_theme');
    } else {
      await p.setString('ts_custom_theme', customThemeJson!);
    }
    await p.setString('ts_face_style', faceStyleId);
    await p.setInt('ts_difficulty', difficultyIdx);
    await p.setInt('ts_layout', layoutIdx);
  }

  Future<void> savePro() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ts_pro', pro);
  }

  Future<void> saveProgress() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'ts_layout_best',
        jsonEncode(
            {for (final e in layoutBest.entries) '${e.key}': e.value}));
    await p.setStringList(
        'ts_layouts_cleared', layoutsCleared.map((i) => '$i').toList());
    await p.setString(
        'ts_daily_best', jsonEncode(dailyBest));
    await p.setInt('ts_daily_streak', dailyStreak);
    if (lastDailyDate == null) {
      await p.remove('ts_last_daily');
    } else {
      await p.setString('ts_last_daily', lastDailyDate!);
    }
  }

  Future<void> saveGame(String json) async {
    savedGame = json;
    final p = await SharedPreferences.getInstance();
    await p.setString('ts_saved_game', json);
  }

  Future<void> clearGame() async {
    savedGame = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('ts_saved_game');
  }
}

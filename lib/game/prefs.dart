// Local persistence via shared_preferences: settings, best records,
// and the in-progress game (for backgrounding / continue).
import 'package:shared_preferences/shared_preferences.dart';

class GamePrefs {
  bool musicOn = true;
  bool sfxOn = true;
  double musicVol = 0.7;
  double sfxVol = 0.8;
  int bestScore = 0;
  int bestTimeSec = 0; // fastest win, 0 = none yet
  String? savedGame;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool('ts_music') ?? true;
    sfxOn = p.getBool('ts_sfx') ?? true;
    musicVol = p.getDouble('ts_music_vol') ?? 0.7;
    sfxVol = p.getDouble('ts_sfx_vol') ?? 0.8;
    bestScore = p.getInt('ts_best_score') ?? 0;
    bestTimeSec = p.getInt('ts_best_time') ?? 0;
    savedGame = p.getString('ts_saved_game');
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

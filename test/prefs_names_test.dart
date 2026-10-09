import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilesolitaire/game/prefs.dart';

/// Regression tests for the player-name persistence bug found in batch-1
/// (2026-10-09): names stored with SharedPreferences.setStringList are backed
/// by an UNORDERED StringSet on Android, so order scrambled on every restart.
///
/// Tile Solitaire stores its single player name with a plain order-preserving
/// setString key ('ts_player_name') — these tests lock that in: a rename must
/// survive an exact save/load round-trip (simulated app restart), and a
/// missing/corrupt value must fall back to the default.
void main() {
  test('player name survives save/load round-trip exactly', () async {
    SharedPreferences.setMockInitialValues({'ts_player_name': 'Wajiha'});
    final a = GamePrefs();
    await a.load();
    expect(a.playerName, 'Wajiha');

    a.playerName = 'Nova Gardener';
    await a.saveProfile();

    // Fresh instance simulates an app restart.
    final b = GamePrefs();
    await b.load();
    expect(b.playerName, 'Nova Gardener');
  });

  test('missing name falls back to the default', () async {
    SharedPreferences.setMockInitialValues({});
    final p = GamePrefs();
    await p.load();
    expect(p.playerName, 'Gardener');
  });

  test('name with unicode/emoji round-trips without mangling', () async {
    SharedPreferences.setMockInitialValues({});
    final a = GamePrefs();
    await a.load();
    a.playerName = 'زهرة 🌸';
    await a.saveProfile();

    final b = GamePrefs();
    await b.load();
    expect(b.playerName, 'زهرة 🌸');
  });
}

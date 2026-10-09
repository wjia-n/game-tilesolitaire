// AudioService: plays procedurally generated sounds via audioplayers.
// Music toggle / SFX toggle / volume sliders are all honored here.
//
// Reliability rules (exemplar pattern):
// - All clips are synthesized once and cached.
// - Music start/stop is serialized with a busy guard; never overlaps.
// - pause()/resume() for app-lifecycle changes (never silently dies).
// - prewarm() runs on the splash so menu music starts instantly.
// - Audio must never crash the app: every call is guarded.
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'audio_gen.dart';

class AudioService {
  AudioPlayer? _musicPlayer;
  final List<AudioPlayer> _sfxPool = [];
  int _sfxCursor = 0;
  final Map<String, Uint8List> _sfxCache = {};
  Uint8List? _menuMusic;
  Uint8List? _gameMusic;
  bool _ready = false;
  bool _musicBusy = false;
  String? _musicMode; // 'menu' | 'game' | null

  bool musicEnabled = true;
  bool sfxEnabled = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;

  /// Generate the small SFX buffers. Music loops are generated lazily on
  /// first use because they are larger.
  Future<void> init() async {
    try {
      _sfxCache['tap'] = ZenSounds.tap();
      _sfxCache['select'] = ZenSounds.select();
      _sfxCache['match'] = ZenSounds.match();
      _sfxCache['invalid'] = ZenSounds.invalid();
      _sfxCache['shuffle'] = ZenSounds.shuffle();
      _sfxCache['hint'] = ZenSounds.hint();
      _sfxCache['undo'] = ZenSounds.undo();
      _sfxCache['start'] = ZenSounds.gameStart();
      _sfxCache['win'] = ZenSounds.win();
      _sfxCache['lose'] = ZenSounds.lose();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Pre-warm music buffers + players while the splash shows, so the first
  /// startMenuMusic() call is instant.
  Future<void> prewarm() async {
    try {
      _menuMusic ??= ZenSounds.musicMenu();
      _gameMusic ??= ZenSounds.musicGame();
      _musicPlayer ??= AudioPlayer();
    } catch (_) {}
  }

  Future<void> playSfx(String name) async {
    if (!_ready || !sfxEnabled) return;
    final bytes = _sfxCache[name];
    if (bytes == null) return;
    final AudioPlayer player;
    if (_sfxPool.length < 4) {
      player = AudioPlayer();
      _sfxPool.add(player);
    } else {
      player = _sfxPool[_sfxCursor];
      _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    }
    try {
      await player.stop();
      await player.setVolume(sfxVolume);
      await player.play(BytesSource(bytes));
    } catch (_) {
      // Audio must never crash the game.
    }
  }

  Future<void> startMenuMusic() => _startMusic('menu');
  Future<void> startGameMusic() => _startMusic('game');

  Future<void> _startMusic(String mode) async {
    if (!_ready || _musicBusy) return;
    _musicBusy = true;
    try {
      _musicMode = mode;
      if (!musicEnabled) return;
      _menuMusic ??= ZenSounds.musicMenu();
      _gameMusic ??= ZenSounds.musicGame();
      _musicPlayer ??= AudioPlayer();
      final player = _musicPlayer!;
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(musicVolume);
      await player.play(BytesSource(mode == 'menu' ? _menuMusic! : _gameMusic!));
    } catch (_) {
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> stopMusic() async {
    _musicMode = null;
    try {
      await _musicPlayer?.stop();
    } catch (_) {}
  }

  /// Pause the music loop (app backgrounding). Keeps [_musicMode] so
  /// resumeMusic() can bring it back.
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  /// Resume after pauseMusic(), honoring the music toggle.
  Future<void> resumeMusic() async {
    final mode = _musicMode;
    if (mode == null || !musicEnabled) return;
    try {
      final player = _musicPlayer;
      if (player == null) return;
      if (player.state == PlayerState.paused) {
        await player.setVolume(musicVolume);
        await player.resume();
      } else {
        await refreshMusic();
      }
    } catch (_) {}
  }

  /// Re-apply toggles/volumes (called from settings).
  Future<void> applySettings() async {
    final player = _musicPlayer;
    if (player == null) return;
    try {
      if (!musicEnabled) {
        await player.setVolume(0);
      } else {
        await player.setVolume(musicVolume);
        if (_musicMode != null && player.state == PlayerState.paused) {
          await player.resume();
        }
      }
    } catch (_) {}
  }

  /// Re-assert the desired music state (e.g. after returning to a screen).
  Future<void> refreshMusic() async {
    final mode = _musicMode;
    if (mode == null || !musicEnabled) return;
    try {
      final player = _musicPlayer;
      if (player == null) return;
      final state = player.state;
      if (state != PlayerState.playing) {
        await _startMusic(mode);
      } else {
        await player.setVolume(musicVolume);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _musicPlayer?.dispose();
      for (final p in _sfxPool) {
        await p.dispose();
      }
    } catch (_) {}
  }
}

// GameController: bridges the pure-Dart engine with the Flutter UI.
// Owns the clock, animations locks, toasts, pause/resume and persistence.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_service.dart';
import 'engine.dart';
import 'prefs.dart';

enum PlayPhase { playing, paused, won, lost }

class GameController extends ChangeNotifier {
  GameController({required this.audio, required this.prefs});

  final AudioService audio;
  final GamePrefs prefs;

  late TileSolitaireEngine engine;
  PlayPhase phase = PlayPhase.playing;

  /// Input lock while the removal animation settles (~250 ms).
  bool busy = false;
  Set<int> popping = {};
  List<int> hintIds = [];
  int hintFlashSeq = 0;

  /// Shake feedback for invalid taps.
  int shakeId = -1;
  int shakeSeq = 0;

  final ValueNotifier<String?> toast = ValueNotifier<String?>(null);
  final ValueNotifier<int> clockTick = ValueNotifier<int>(0);
  Timer? _toastTimer;
  Timer? _clock;

  bool _disposed = false;

  // ---- derived -----------------------------------------------------------
  int get score => engine.score;
  int get timeSec => engine.elapsedSeconds;
  int get pairsDone => engine.pairsDone;
  int get pairsTotal => engine.pairsTotal;
  int get hintsLeft => engine.hintsLeft;
  int get shufflesLeft => engine.shufflesLeft;
  bool get canUndo => engine.undoStack.isNotEmpty && !busy;
  bool get needShuffle => engine.needShuffle;
  String get layoutName => kLayouts[engine.layoutIndex].name;

  // ---- lifecycle ----------------------------------------------------------
  void newGame(int layoutIndex) {
    engine = TileSolitaireEngine.newGame(layoutIndex: layoutIndex);
    _resetRoundState();
    audio.playSfx('start');
    unawaited(audio.startGameMusic());
    _persist();
  }

  void restore(String json) {
    engine = TileSolitaireEngine.decode(json);
    _resetRoundState();
    phase = PlayPhase.paused; // resume explicitly via the pause overlay
    notifyListeners();
  }

  void _resetRoundState() {
    phase = PlayPhase.playing;
    busy = false;
    popping = {};
    hintIds = [];
    toast.value = null;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (phase == PlayPhase.playing) {
        engine.elapsedSeconds++;
        clockTick.value = engine.elapsedSeconds;
        if (engine.elapsedSeconds % 15 == 0) _persist();
      }
    });
    notifyListeners();
  }

  void _persist() {
    if (phase == PlayPhase.playing || phase == PlayPhase.paused) {
      unawaited(prefs.saveGame(engine.encode()));
    }
  }

  // ---- input --------------------------------------------------------------
  void tap(int tileId) {
    if (phase != PlayPhase.playing || busy || engine.over) return;
    final event = engine.tap(tileId);
    switch (event) {
      case TapEvent.invalidTile:
        unawaited(audio.playSfx('invalid'));
        shakeId = tileId;
        shakeSeq++;
        break;
      case TapEvent.selected:
        unawaited(audio.playSfx('select'));
        hintIds = [];
        break;
      case TapEvent.deselected:
        unawaited(audio.playSfx('tap'));
        break;
      case TapEvent.mismatch:
        unawaited(audio.playSfx('invalid'));
        _showToast('Those tiles do not match.');
        break;
      case TapEvent.captured:
        final rec = engine.undoStack.last;
        unawaited(audio.playSfx('match'));
        hintIds = [];
        busy = true;
        popping = {rec.aId, rec.bId};
        Future.delayed(const Duration(milliseconds: 260), () {
          if (_disposed) return;
          popping = {};
          busy = false;
          engine.checkDeadlock();
          _afterResolution();
          notifyListeners();
        });
        break;
    }
    notifyListeners();
  }

  void useHint() {
    if (phase != PlayPhase.playing || busy || engine.over) return;
    if (engine.hintsLeft <= 0) {
      unawaited(audio.playSfx('invalid'));
      _showToast('No hints left.');
      return;
    }
    final pair = engine.useHint();
    if (pair == null) {
      unawaited(audio.playSfx('invalid'));
      return;
    }
    unawaited(audio.playSfx('hint'));
    hintIds = pair;
    hintFlashSeq++;
    notifyListeners();
  }

  void useShuffle() {
    if (phase != PlayPhase.playing || busy || engine.over) return;
    if (engine.shufflesLeft <= 0) {
      unawaited(audio.playSfx('invalid'));
      _showToast('No shuffles left.');
      return;
    }
    busy = true;
    unawaited(audio.playSfx('shuffle'));
    _showToast('Raking the sand...');
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (_disposed) return;
      engine.useShuffle();
      busy = false;
      hintIds = [];
      _afterResolution();
      notifyListeners();
    });
  }

  void undo() {
    if (phase != PlayPhase.playing || busy) return;
    if (engine.undo()) {
      unawaited(audio.playSfx('undo'));
      _showToast('Pair restored.');
    } else {
      unawaited(audio.playSfx('invalid'));
    }
    notifyListeners();
  }

  void _afterResolution() {
    _persist();
    if (engine.won) {
      _onWin();
    } else if (engine.over) {
      _onLose();
    } else if (engine.needShuffle) {
      _showToast('No pairs left — shuffle the garden.', long: true);
      unawaited(audio.playSfx('hint'));
    }
  }

  void _onWin() {
    phase = PlayPhase.won;
    _clock?.cancel();
    unawaited(audio.playSfx('win'));
    var record = false;
    if (engine.score > prefs.bestScore) {
      prefs.bestScore = engine.score;
      record = true;
    }
    if (prefs.bestTimeSec == 0 || engine.elapsedSeconds < prefs.bestTimeSec) {
      prefs.bestTimeSec = engine.elapsedSeconds;
      record = true;
    }
    if (record) unawaited(prefs.saveRecords());
    unawaited(prefs.clearGame());
    notifyListeners();
  }

  void _onLose() {
    phase = PlayPhase.lost;
    _clock?.cancel();
    unawaited(audio.playSfx('lose'));
    unawaited(prefs.clearGame());
    notifyListeners();
  }

  // ---- pause / resume / quit ------------------------------------------------
  void pause() {
    if (phase != PlayPhase.playing) return;
    phase = PlayPhase.paused;
    _persist();
    unawaited(audio.playSfx('tap'));
    notifyListeners();
  }

  void resume() {
    if (phase != PlayPhase.paused) return;
    phase = PlayPhase.playing;
    unawaited(audio.playSfx('tap'));
    notifyListeners();
  }

  /// Auto-pause when the app goes to the background (timer stops, state saved).
  void autoPause() {
    if (phase == PlayPhase.playing) {
      phase = PlayPhase.paused;
      _persist();
      notifyListeners();
    }
  }

  void restart() {
    newGame(engine.layoutIndex);
  }

  /// Quitting mid-game counts as a loss (score kept as-is).
  void resign() {
    engine.resigned = true;
    engine.over = true;
    _clock?.cancel();
    unawaited(prefs.clearGame());
    notifyListeners();
  }

  // ---- toast -----------------------------------------------------------------
  void _showToast(String message, {bool long = false}) {
    toast.value = message;
    _toastTimer?.cancel();
    _toastTimer = Timer(Duration(milliseconds: long ? 3200 : 1800), () {
      if (!_disposed) toast.value = null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _toastTimer?.cancel();
    toast.dispose();
    clockTick.dispose();
    super.dispose();
  }
}

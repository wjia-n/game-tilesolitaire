// GameController: bridges the pure-Dart engine with the Flutter UI.
// Owns the clock, animation locks, toasts, pause/resume, persistence,
// and the watchdog that guarantees no stuck states.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_service.dart';
import 'engine.dart';
import 'prefs.dart';

enum PlayPhase { playing, paused, won, lost }

/// The engine (not UI timers) owns all game state. The controller only
/// bridges to Flutter. A watchdog recovers the input lock if any async
/// animation callback ever fails to release it — stuck states are
/// impossible by construction.
class GameController extends ChangeNotifier {
  GameController({required this.audio, required this.prefs});

  final AudioService audio;
  final GamePrefs prefs;

  late TileSolitaireEngine engine;
  PlayPhase phase = PlayPhase.playing;

  /// Input lock while the removal/shuffle animation settles.
  bool busy = false;
  bool shuffling = false;
  Set<int> popping = {};
  List<int> hintIds = [];
  int hintFlashSeq = 0;

  /// Shake feedback for invalid taps.
  int shakeId = -1;
  int shakeSeq = 0;

  /// Daily garden bookkeeping.
  bool isDaily = false;
  String dailyDate = '';

  final ValueNotifier<String?> toast = ValueNotifier<String?>(null);
  final ValueNotifier<int> clockTick = ValueNotifier<int>(0);
  Timer? _toastTimer;
  Timer? _clock;
  Timer? _watchdog;
  DateTime? _busySince;
  int _watchdogRecoveries = 0;

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
  int get watchdogRecoveries => _watchdogRecoveries;

  Difficulty get _difficulty =>
      Difficulty.values[prefs.difficultyIdx.clamp(0, 2)];

  // ---- lifecycle ----------------------------------------------------------
  void newGame(int layoutIndex,
      {Difficulty? difficulty, int? seed, bool daily = false}) {
    final diff = difficulty ?? _difficulty;
    engine = TileSolitaireEngine.newGame(
      layoutIndex: layoutIndex,
      difficulty: diff,
      seed: seed,
      // Pro gardeners rake with a fuller toolkit.
      hintBonus: prefs.pro ? 2 : 0,
      shuffleBonus: prefs.pro ? 2 : 0,
    );
    isDaily = daily;
    dailyDate = daily ? todayKey() : '';
    _resetRoundState();
    audio.playSfx('start');
    unawaited(audio.startGameMusic());
    _persist();
  }

  /// Daily garden: one shared layout+seed per calendar day.
  void newDaily() {
    final now = DateTime.now();
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays;
    final seed = now.year * 1000 + dayOfYear;
    final layout = dayOfYear % kLayouts.length;
    newGame(layout, seed: seed, daily: true);
  }

  static String todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
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
    shuffling = false;
    _busySince = null;
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
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      _runWatchdog();
    });
    notifyListeners();
  }

  /// Watchdog: if the input lock has been held for more than 2.5 seconds
  /// without a live resolution path, release it and tell the player.
  /// This can only trigger if an animation callback was lost; normal play
  /// never trips it.
  void _runWatchdog() {
    if (!busy || phase != PlayPhase.playing) return;
    final since = _busySince;
    if (since == null) {
      _busySince = DateTime.now();
      return;
    }
    if (DateTime.now().difference(since) >
        const Duration(milliseconds: 2500)) {
      busy = false;
      shuffling = false;
      popping = {};
      _busySince = null;
      _watchdogRecoveries++;
      _showToast('The garden steadied itself — carry on.');
      engine.checkDeadlock();
      _afterResolution();
      notifyListeners();
    }
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
        _busySince = DateTime.now();
        popping = {rec.aId, rec.bId};
        Future.delayed(const Duration(milliseconds: 260), () {
          if (_disposed) return;
          popping = {};
          busy = false;
          _busySince = null;
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
    shuffling = true;
    _busySince = DateTime.now();
    unawaited(audio.playSfx('shuffle'));
    _showToast('Raking the sand...');
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (_disposed) return;
      engine.useShuffle();
      busy = false;
      shuffling = false;
      _busySince = null;
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
    // Per-layout progress.
    final li = engine.layoutIndex;
    final prevBest = prefs.layoutBest[li] ?? 0;
    if (engine.score > prevBest) {
      prefs.layoutBest[li] = engine.score;
      record = true;
    }
    prefs.layoutsCleared.add(li);
    // Daily garden records + streak.
    if (isDaily && dailyDate.isNotEmpty) {
      final prev = prefs.dailyBest[dailyDate] ?? 0;
      if (engine.score > prev) {
        prefs.dailyBest[dailyDate] = engine.score;
        record = true;
      }
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey = '${yesterday.year.toString().padLeft(4, '0')}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';
      if (prefs.lastDailyDate == yKey) {
        prefs.dailyStreak++;
      } else if (prefs.lastDailyDate != dailyDate) {
        prefs.dailyStreak = 1;
      }
      prefs.lastDailyDate = dailyDate;
    }
    if (record) {
      unawaited(prefs.saveRecords());
    }
    unawaited(prefs.saveProgress());
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

  /// Auto-pause when the app goes to the background (timer stops, state
  /// saved, music paused).
  void autoPause() {
    if (phase == PlayPhase.playing) {
      phase = PlayPhase.paused;
      _persist();
      unawaited(audio.pauseMusic());
      notifyListeners();
    }
  }

  void restart() {
    newGame(engine.layoutIndex,
        difficulty: engine.difficulty, daily: isDaily);
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
    _watchdog?.cancel();
    _toastTimer?.cancel();
    toast.dispose();
    clockTick.dispose();
    super.dispose();
  }
}

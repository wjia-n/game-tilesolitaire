// Game board screen: the sand bed, bamboo tiles, tally chips,
// pebble actions, captured tray, pause overlay and toasts.
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../game/engine.dart';
import '../theme/face_styles.dart';
import '../ui/zen.dart';
import 'game_over_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameController get c => widget.controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c.addListener(_onPhase);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.removeListener(_onPhase);
    // The game-over screen takes over the controller for stats; otherwise
    // this screen owns it.
    if (c.phase != PlayPhase.won && c.phase != PlayPhase.lost) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      c.autoPause(); // timer stops, state persisted, music paused
    } else if (state == AppLifecycleState.resumed) {
      c.audio.resumeMusic();
    }
  }

  void _onPhase() {
    if (_navigated) return;
    if (c.phase == PlayPhase.won || c.phase == PlayPhase.lost) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameOverScreen(
              controller: c,
              onPlayAgain: () {
                final next = GameController(
                    audio: c.audio, prefs: c.prefs)
                  ..newGame(c.engine.layoutIndex,
                      difficulty: c.engine.difficulty,
                      daily: c.isDaily);
                c.dispose();
                navigator.pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => GameScreen(controller: next)),
                );
              },
              onMenu: () {
                c.dispose();
                navigator.pop();
              },
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) {
              final engine = c.engine;
              return Stack(
                children: [
                  Column(
                    children: [
                      _topBar(),
                      _chipsRow(engine),
                      Expanded(child: _board(engine)),
                      if (c.needShuffle) _shuffleBanner(),
                      _actionRow(),
                      _tray(engine),
                      const SizedBox(height: 10),
                    ],
                  ),
                  if (c.phase == PlayPhase.paused) _pauseOverlay(),
                  ValueListenableBuilder<String?>(
                    valueListenable: c.toast,
                    builder: (context, msg, _) => msg == null
                        ? const SizedBox.shrink()
                        : ToastBanner(message: msg),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          PebbleButton(
            label: 'Pause',
            icon: Icons.pause,
            kind: PebbleKind.secondary,
            onTap: c.pause,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  c.isDaily ? 'Daily garden' : '${c.layoutName} garden',
                  style: Zen.heading(19),
                  textAlign: TextAlign.center,
                ),
                Text(
                  c.engine.difficulty.title,
                  style: Zen.chipLabel.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          PebbleButton(
            label: 'New',
            icon: Icons.refresh,
            kind: PebbleKind.wood,
            onTap: () {
              c.audio.playSfx('tap');
              c.restart();
            },
          ),
        ],
      ),
    );
  }

  Widget _chipsRow(TileSolitaireEngine engine) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TallyChip(label: 'SCORE', value: '${engine.score}'),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: c.clockTick,
            builder: (context, tick, _) =>
                TallyChip(label: 'TIME', value: Zen.clock(tick)),
          ),
          const SizedBox(width: 8),
          TallyChip(
              label: 'PAIRS',
              value: '${engine.pairsDone}/${engine.pairsTotal}'),
          if (engine.chain >= 2) ...[
            const SizedBox(width: 8),
            TallyChip(
                label: 'CHAIN', value: 'x${engine.chain + 1}'),
          ],
        ],
      ),
    );
  }

  Widget _board(TileSolitaireEngine engine) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth, constraints.maxHeight);
        final maxX = engine.maxX, maxY = engine.maxY, maxZ = engine.maxZ;
        const shiftX = 9.0, shiftY = 11.0;
        var tw = (area.width - 20 - maxZ * shiftX) / (maxX + 1);
        tw = tw.clamp(18.0, 58.0);
        final th = tw * 1.3;
        final totalW = (maxX + 1) * tw + maxZ * shiftX;
        final totalH = (maxY + 1) * th + maxZ * shiftY;
        final ox = (area.width - totalW) / 2;
        final oy = (area.height - totalH) / 2 + maxZ * shiftY;

        final ordered = [...engine.tiles]
          ..sort((a, b) {
            final zc = a.z.compareTo(b.z);
            return zc != 0 ? zc : a.y.compareTo(b.y);
          });

        return Stack(
          children: [
            for (final tile in ordered)
              if (!tile.cleared || c.popping.contains(tile.id))
                Positioned(
                  left: ox + tile.x * tw + tile.z * shiftX,
                  top: oy + tile.y * th - tile.z * shiftY,
                  child: _tileCell(tile, tw, engine),
                ),
          ],
        );
      },
    );
  }

  Widget _tileCell(Tile tile, double tw, TileSolitaireEngine engine) {
    final popping = c.popping.contains(tile.id);
    final playable = engine.isFree(tile);
    final glyph = FaceStyles.current.faces[tile.face];
    Widget cell = GestureDetector(
      onTap: () => c.tap(tile.id),
      child: BambooTile(
        glyph: glyph.glyph,
        size: tw,
        selected: engine.selectedId == tile.id,
        hinted: c.hintIds.contains(tile.id),
        covered: engine.isCovered(tile),
        dimmed: !playable && !popping,
        lift: engine.selectedId == tile.id ? 4 : tile.z * 1.5,
        semanticsLabel: '${glyph.label} tile${playable ? ', free' : ''}',
      ),
    );

    // Hinted tiles breathe gently until tapped (the natural moss rim).
    if (c.hintIds.contains(tile.id) && !popping) {
      cell = _HintPulse(
        key: ValueKey('hint${c.hintFlashSeq}_${tile.id}'),
        child: cell,
      );
    }

    // During a shuffle every tile trembles as the sand is raked.
    if (c.shuffling && !popping) {
      cell = _ShuffleJitter(
        key: ValueKey('shuf${tile.id}'),
        seed: tile.id * 7919,
        child: cell,
      );
    }

    if (popping) {
      // Lift and fade to mist.
      cell = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, v, child) => Opacity(
          opacity: 1 - v,
          child: Transform.translate(
            offset: Offset(0, -16 * v),
            child: Transform.scale(scale: 1 + 0.08 * v, child: child),
          ),
        ),
        child: cell,
      );
    }

    // Shake on invalid taps (weight / physicality, no glow).
    // Only the shaken tile gets a ticker.
    if (c.shakeId == tile.id && c.shakeSeq > 0) {
      cell = _ShakeOnce(key: ValueKey('shake${c.shakeSeq}'), child: cell);
    }
    return cell;
  }

  Widget _shuffleBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: CedarPlaque(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No pairs left. Rake the sand to begin anew.',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Zen.sumiInk),
              ),
            ),
            PebbleButton(
              label: 'Shuffle',
              icon: Icons.autorenew,
              badge: '${c.shufflesLeft}',
              onTap: c.useShuffle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          PebbleButton(
            label: 'Hint',
            icon: Icons.lightbulb_outline,
            kind: PebbleKind.secondary,
            badge: '${c.hintsLeft}',
            enabled: c.hintsLeft > 0,
            onTap: c.useHint,
          ),
          PebbleButton(
            label: 'Shuffle',
            icon: Icons.autorenew,
            kind: PebbleKind.secondary,
            badge: '${c.shufflesLeft}',
            enabled: c.shufflesLeft > 0,
            onTap: c.useShuffle,
          ),
          PebbleButton(
            label: 'Undo',
            icon: Icons.undo,
            kind: PebbleKind.wood,
            enabled: c.canUndo,
            onTap: c.undo,
          ),
        ],
      ),
    );
  }

  Widget _tray(TileSolitaireEngine engine) {
    final faces = engine.capturedFaces;
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Zen.tray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Zen.darkCedar, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Zen.sumiInk.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: faces.isEmpty
          ? Center(
              child: Text(
                'Captured pairs rest here',
                style: TextStyle(
                    color: Zen.paperWhite,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: faces.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, i) {
                final g = FaceStyles.current.faces[faces[i]];
                return Center(
                  child: BambooTile(
                    glyph: g.glyph,
                    size: 24,
                    semanticsLabel: g.label,
                  ),
                );
              },
            ),
    );
  }

  Widget _pauseOverlay() {
    return Container(
      color: Zen.sumiInk.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: CedarPlaque(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Paused', style: Zen.heading(28)),
                const SizedBox(height: 6),
                Text('The garden waits for you.',
                    style: Zen.body),
                const SizedBox(height: 18),
                PebbleButton(
                  label: 'Resume',
                  icon: Icons.play_arrow,
                  big: true,
                  onTap: c.resume,
                ),
                const SizedBox(height: 10),
                PebbleButton(
                  label: 'Restart garden',
                  icon: Icons.refresh,
                  kind: PebbleKind.secondary,
                  onTap: () {
                    c.restart();
                  },
                ),
                const SizedBox(height: 10),
                PebbleButton(
                  label: 'Settings',
                  icon: Icons.settings,
                  kind: PebbleKind.wood,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                            audio: c.audio, prefs: c.prefs),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    c.resign();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Leave garden',
                    style: TextStyle(
                        color: Zen.darkCedar,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Brief horizontal shake for invalid taps. Mounted only on the shaken tile.
class _ShakeOnce extends StatefulWidget {
  const _ShakeOnce({super.key, required this.child});
  final Widget child;

  @override
  State<_ShakeOnce> createState() => _ShakeOnceState();
}

class _ShakeOnceState extends State<_ShakeOnce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320))
      ..forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        final v = _ac.value;
        final dx = v == 0 ? 0.0 : sin(v * pi * 5) * 5 * (1 - v);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Gentle breathing pulse around hinted tiles (moss rim, no glow).
class _HintPulse extends StatefulWidget {
  const _HintPulse({super.key, required this.child});
  final Widget child;

  @override
  State<_HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<_HintPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        final v = _ac.value;
        return Transform.scale(
          scale: 1 + 0.05 * v,
          child: Transform.translate(
            offset: Offset(0, -3 * v),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Tiles tremble while the sand is being raked (shuffle animation).
class _ShuffleJitter extends StatelessWidget {
  const _ShuffleJitter({super.key, required this.child, required this.seed});
  final Widget child;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed);
    final dx = (rng.nextDouble() - 0.5) * 14;
    final dy = (rng.nextDouble() - 0.5) * 10;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, v, child) {
        final w = sin(v * pi * 4);
        return Transform.translate(
          offset: Offset(dx * w * (1 - v), dy * w * (1 - v)),
          child: child,
        );
      },
      child: child,
    );
  }
}

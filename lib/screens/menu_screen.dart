// Main menu: title plaque, layout choice, start / continue / settings.
import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../game/prefs.dart';
import '../ui/zen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.audio, required this.prefs});
  final AudioService audio;
  final GamePrefs prefs;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int layoutIdx = 0;
  bool showHowTo = false;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  List<List<int>> _cellsOf(int idx) {
    final cells = <List<int>>[];
    final def = kLayouts[idx];
    for (var z = 0; z < def.layers.length; z++) {
      final layer = def.layers[z];
      for (var y = 0; y < layer.rows.length; y++) {
        final row = layer.rows[y];
        for (var x = 0; x < row.length; x++) {
          if (row.codeUnitAt(x) == 0x58) {
            cells.add([layer.ox + x, layer.oy + y, z]);
          }
        }
      }
    }
    return cells;
  }

  void _begin({String? savedJson}) {
    widget.audio.playSfx('tap');
    final controller =
        GameController(audio: widget.audio, prefs: widget.prefs);
    if (savedJson != null) {
      controller.restore(savedJson);
    } else {
      controller.newGame(layoutIdx);
    }
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (_) => GameScreen(controller: controller)),
    )
        .then((_) {
      widget.audio.startMenuMusic();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(child: Cairn(size: 84)),
                const SizedBox(height: 10),
                Text('Tile Solitaire', style: Zen.heading(34),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text(
                  'A quiet garden of matching tiles.\nClear the sand, one pair at a time.',
                  style: Zen.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (widget.prefs.bestScore > 0)
                  Center(
                    child: TallyChip(
                      label: 'BEST SCORE',
                      value: '${widget.prefs.bestScore}',
                    ),
                  ),
                if (widget.prefs.savedGame != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: PebbleButton(
                      label: 'Continue garden',
                      icon: Icons.play_arrow,
                      kind: PebbleKind.wood,
                      onTap: () => _begin(savedJson: widget.prefs.savedGame),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text('CHOOSE A GARDEN', style: Zen.chipLabel,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                for (var i = 0; i < kLayouts.length; i++)
                  _layoutCard(i),
                const SizedBox(height: 18),
                Center(
                  child: PebbleButton(
                    label: 'Begin raking',
                    icon: Icons.spa,
                    big: true,
                    onTap: () => _begin(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PebbleButton(
                      label: 'Settings',
                      icon: Icons.settings,
                      kind: PebbleKind.secondary,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                                audio: widget.audio, prefs: widget.prefs),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    PebbleButton(
                      label: 'How to play',
                      icon: Icons.menu_book,
                      kind: PebbleKind.wood,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        setState(() => showHowTo = !showHowTo);
                      },
                    ),
                  ],
                ),
                if (showHowTo) ...[
                  const SizedBox(height: 14),
                  const CedarPlaque(
                    child: Text(
                      'Tap two FREE tiles with matching faces to clear them.\n\n'
                      'A tile is free when nothing rests on top of it and at '
                      'least one side is open.\n\n'
                      'Flower and season tiles are wild: any two match.\n\n'
                      'Chain pairs without a miss for bonus points. '
                      'Stuck with no pairs? Spend a shuffle to rake the '
                      'sand anew. Undo restores your last pair.\n\n'
                      'Clear all 144 tiles to win the garden.',
                      style: Zen.body,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _layoutCard(int i) {
    final def = kLayouts[i];
    final selected = layoutIdx == i;
    final cells = _cellsOf(i);
    var mx = 0, my = 0;
    for (final c in cells) {
      if (c[0] > mx) mx = c[0];
      if (c[1] > my) my = c[1];
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          widget.audio.playSfx('tap');
          setState(() => layoutIdx = i);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Zen.cedar,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Zen.deepMoss : Zen.darkCedar,
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Zen.sumiInk.withValues(alpha: 0.25),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Zen.paperWhite : Zen.bambooIvory,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                LayoutPreview(cells: cells, maxX: mx, maxY: my),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Zen.sumiInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(def.blurb,
                          style: Zen.body.copyWith(fontSize: 13)),
                      const SizedBox(height: 6),
                      const TallyChip(label: 'TILES', value: '144'),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: Zen.deepMoss, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

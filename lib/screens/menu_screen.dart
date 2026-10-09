// Main menu: gardener profile, layout choice, difficulty,
// daily garden, themes, tile faces, Pro, settings.
import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/controller.dart';
import '../game/engine.dart';
import '../game/prefs.dart';
import '../services/iap_service.dart';
import '../theme/face_styles.dart';
import '../theme/garden_themes.dart';
import '../ui/zen.dart';
import 'face_style_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen(
      {super.key,
      required this.audio,
      required this.prefs,
      required this.store});
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  int layoutIdx = 0;
  bool showHowTo = false;

  GamePrefs get prefs => widget.prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    layoutIdx = prefs.layoutIdx.clamp(0, kLayouts.length - 1);
    widget.audio.startMenuMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      widget.audio.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.resumeMusic();
    }
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

  void _begin({String? savedJson, bool daily = false}) {
    widget.audio.playSfx('tap');
    final controller =
        GameController(audio: widget.audio, prefs: prefs);
    if (savedJson != null) {
      controller.restore(savedJson);
    } else if (daily) {
      controller.newDaily();
    } else {
      prefs.layoutIdx = layoutIdx;
      prefs.saveLook();
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

  void _editName() {
    widget.audio.playSfx('tap');
    final ctl = TextEditingController(text: prefs.playerName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Zen.paperWhite,
        title: Text('Gardener name', style: Zen.heading(20)),
        content: TextField(
          controller: ctl,
          maxLength: 18,
          decoration: const InputDecoration(
            hintText: 'What shall the garden call you?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = ctl.text.trim();
              if (name.isNotEmpty) {
                prefs.playerName = name;
                prefs.saveProfile();
              }
              widget.audio.playSfx('tap');
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeDef = GardenThemes.byId(prefs.themeId);    final faceDef = FaceStyles.byId(prefs.faceStyleId);
    final diff =
        Difficulty.values[prefs.difficultyIdx.clamp(0, 2)];
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile row.
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _editName,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Zen.bambooIvory,
                                border: Border.all(
                                    color: Zen.sandGroove, width: 1.5),
                              ),
                              child: Icon(Icons.person,
                                  color: Zen.deepMoss, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('GARDENER',
                                      style: Zen.chipLabel),
                                  Text(
                                    prefs.playerName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Zen.sumiInk,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit,
                                size: 16, color: Zen.sandGroove),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        widget.audio.playSfx('tap');
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (_) => ProScreen(
                                audio: widget.audio,
                                prefs: prefs,
                                store: widget.store),
                          ),
                        )
                            .then((_) => setState(() {}));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: prefs.pro
                              ? Zen.deepMoss
                              : Zen.bambooIvory,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: prefs.pro
                                  ? Zen.deepMoss
                                  : Zen.sandGroove,
                              width: 1.5),
                        ),
                        child: Text(
                          prefs.pro ? 'PRO' : 'Go PRO',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: prefs.pro
                                ? Zen.paperWhite
                                : Zen.deepMoss,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border:
                          Border.all(color: Zen.cedar, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Zen.sumiInk.withValues(alpha: 0.3),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                        'assets/tilesolitaire_logo.png',
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Tile Solitaire',
                    style: Zen.heading(34),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(
                  'A quiet garden of matching tiles.\nClear the sand, one pair at a time.',
                  style: Zen.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (prefs.bestScore > 0)
                      TallyChip(
                        label: 'BEST SCORE',
                        value: '${prefs.bestScore}',
                      ),
                    if (prefs.bestTimeSec > 0)
                      TallyChip(
                        label: 'FASTEST WIN',
                        value: Zen.clock(prefs.bestTimeSec),
                      ),
                    if (prefs.layoutsCleared.isNotEmpty)
                      TallyChip(
                        label: 'GARDENS CLEARED',
                        value:
                            '${prefs.layoutsCleared.length}/${kLayouts.length}',
                      ),
                  ],
                ),
                if (prefs.savedGame != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: PebbleButton(
                      label: 'Continue garden',
                      icon: Icons.play_arrow,
                      kind: PebbleKind.wood,
                      onTap: () =>
                          _begin(savedJson: prefs.savedGame),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _dailyCard(),
                const SizedBox(height: 18),
                Text('CHOOSE A GARDEN', style: Zen.chipLabel,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                for (var i = 0; i < kLayouts.length; i++)
                  _layoutCard(i),
                const SizedBox(height: 6),
                Text('DIFFICULTY', style: Zen.chipLabel,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                _difficultyRow(diff),
                const SizedBox(height: 18),
                Center(
                  child: PebbleButton(
                    label: 'Begin raking',
                    icon: Icons.spa,
                    big: true,
                    onTap: () => _begin(),
                  ),
                ),
                const SizedBox(height: 18),
                Text('THE LOOK', style: Zen.chipLabel,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _lookCard(
                        icon: Icons.palette,
                        title: 'Themes',
                        subtitle: prefs.themeId == 'custom'
                            ? 'Custom garden'
                            : themeDef.name,
                        onTap: () {
                          widget.audio.playSfx('tap');
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (_) => ThemeScreen(
                                  audio: widget.audio,
                                  prefs: prefs,
                                  store: widget.store),
                            ),
                          )
                              .then((_) => setState(() {}));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _lookCard(
                        icon: Icons.grid_on,
                        title: 'Tile faces',
                        subtitle: faceDef.name,
                        onTap: () {
                          widget.audio.playSfx('tap');
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (_) => FaceStyleScreen(
                                  audio: widget.audio,
                                  prefs: prefs,
                                  store: widget.store),
                            ),
                          )
                              .then((_) => setState(() {}));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PebbleButton(
                      label: 'Settings',
                      icon: Icons.settings,
                      kind: PebbleKind.secondary,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                                audio: widget.audio,
                                prefs: prefs),
                          ),
                        )
                            .then((_) => setState(() {}));
                      },
                    ),
                    const SizedBox(width: 12),
                    PebbleButton(
                      label: 'How to play',
                      icon: Icons.menu_book,
                      kind: PebbleKind.wood,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        setState(
                            () => showHowTo = !showHowTo);
                      },
                    ),
                  ],
                ),
                if (showHowTo) ...[
                  const SizedBox(height: 14),
                  CedarPlaque(
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

  Widget _dailyCard() {
    final today = GameController.todayKey();
    final best = prefs.dailyBest[today];
    final streak = prefs.dailyStreak;
    return GestureDetector(
      onTap: () => _begin(daily: true),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Zen.deepMoss,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Zen.darkCedar, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Zen.sumiInk.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Zen.paperWhite,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(Icons.wb_sunny,
                  color: Zen.deepMoss, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily garden',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Zen.sumiInk,
                      ),
                    ),
                    Text(
                      best != null
                          ? 'Today’s best: $best'
                          : 'One shared garden, new every day.',
                      style: Zen.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                TallyChip(
                    label: 'DAY STREAK', value: '$streak')
              else
                Icon(Icons.arrow_forward,
                    color: Zen.deepMoss),
            ],
          ),
        ),
      ),
    );
  }

  Widget _difficultyRow(Difficulty diff) {
    return Row(
      children: [
        for (final d in Difficulty.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  widget.audio.playSfx('tap');
                  setState(() {
                    prefs.difficultyIdx = d.index;
                    prefs.saveLook();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: d == diff
                        ? Zen.deepMoss
                        : Zen.bambooIvory,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: d == diff
                          ? Zen.deepMoss
                          : Zen.sandGroove,
                      width: d == diff ? 2.5 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        d.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: d == diff
                              ? Zen.paperWhite
                              : Zen.sumiInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.hints} hints · ${d.shuffles} shuffles',
                        style: TextStyle(
                          fontSize: 10,
                          color: d == diff
                              ? Zen.paperWhite
                                  .withValues(alpha: 0.85)
                              : Zen.sumiInk.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _lookCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Zen.bambooIvory,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Zen.sandGroove, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Zen.sumiInk.withValues(alpha: 0.15),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Zen.deepMoss, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Zen.chipLabel),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Zen.sumiInk,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Zen.sandGroove),
          ],
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
    final best = prefs.layoutBest[i];
    final cleared = prefs.layoutsCleared.contains(i);
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              def.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Zen.sumiInk,
                              ),
                            ),
                          ),
                          if (cleared)
                            Icon(Icons.spa,
                                color: Zen.deepMoss, size: 20),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(def.blurb,
                          style: Zen.body.copyWith(fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const TallyChip(
                              label: 'TILES', value: '144'),
                          if (best != null) ...[
                            const SizedBox(width: 8),
                            TallyChip(
                                label: 'BEST', value: '$best'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle,
                      color: Zen.deepMoss, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

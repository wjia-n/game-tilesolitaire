import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Tile Solitaire — mahjong-style matching. Three layered layouts,
/// free-tile rules, shuffle rescue, hints, win/lose flow.
class TileSolitaireScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const TileSolitaireScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<TileSolitaireScreen> createState() => _TileSolitaireScreenState();
}

class _Tile {
  final int id, x, y, z;
  String face;
  bool cleared = false;
  _Tile(this.id, this.x, this.y, this.z, this.face);
}

class _TileSolitaireScreenState extends State<TileSolitaireScreen> {
  bool started = false;
  int layoutIdx = 0;
  final List<_Tile> tiles = [];
  _Tile? selected;
  final Set<int> popping = {};
  List<int> hintPair = [];
  int shufflesLeft = 3;
  bool needShuffle = false;
  bool over = false;
  int maxX = 0, maxY = 0, maxZ = 0;

  static const _faces = [
    '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵',
    '🐔','🐧','🐦','🦄','🐝','🦋','🐌','🐞','🦀','🐙','🦑','🐳','🐬','🐠','🐡',
  ];

  static const _layouts = [
    {
      'name': 'Turtle', 'emoji': '🐢', 'blurb': 'Slow and steady wins the match!',
      'layers': [
        {'ox': 0, 'oy': 0, 'rows': ['..XXXX..', '.XXXXXX.', 'XXXXXXXX', 'XXXXXXXX', '.XXXXXX.']},
        {'ox': 2, 'oy': 1, 'rows': ['XXXX', 'XXXX']},
        {'ox': 3, 'oy': 2, 'rows': ['XX']},
      ],
    },
    {
      'name': 'Pyramid', 'emoji': '🔺', 'blurb': 'Climb to the top, one pair at a time!',
      'layers': [
        {'ox': 0, 'oy': 0, 'rows': ['XXXXXX', 'XXXXXX', 'XXXXXX', 'XXXXXX', 'XXXXXX', 'XXXXXX']},
        {'ox': 1, 'oy': 1, 'rows': ['XXXX', 'XXXX', 'XXXX', 'XXXX']},
        {'ox': 2, 'oy': 2, 'rows': ['XX', 'XX']},
      ],
    },
    {
      'name': 'Bridge', 'emoji': '🌉', 'blurb': 'Two towers, one deck, zero mercy!',
      'layers': [
        {'ox': 0, 'oy': 0, 'rows': ['XX....XX', 'XX....XX', 'XX....XX', 'XX....XX']},
        {'ox': 1, 'oy': 1, 'rows': ['XXXXXX']},
      ],
    },
  ];

  int get pairsTotal => tiles.length ~/ 2;
  int get pairsDone => tiles.where((t) => t.cleared).length ~/ 2;

  void _startGame() {
    Sfx.click();
    tiles.clear();
    selected = null;
    popping.clear();
    hintPair = [];
    shufflesLeft = 3;
    needShuffle = false;
    over = false;
    final layers = _layouts[layoutIdx]['layers'] as List;
    var id = 0;
    maxX = 0; maxY = 0; maxZ = 0;
    for (int z = 0; z < layers.length; z++) {
      final layer = layers[z] as Map;
      final ox = layer['ox'] as int, oy = layer['oy'] as int;
      final rows = layer['rows'] as List;
      for (int y = 0; y < rows.length; y++) {
        final row = rows[y] as String;
        for (int x = 0; x < row.length; x++) {
          if (row[x] != 'X') continue;
          tiles.add(_Tile(id++, ox + x, oy + y, z, ''));
          maxX = max(maxX, ox + x);
          maxY = max(maxY, oy + y);
          maxZ = max(maxZ, z);
        }
      }
    }
    assert(tiles.length.isEven, 'layout must have even tile count');
    _deal();
    setState(() => started = true);
  }

  void _deal() {
    final rng = Random();
    for (int attempt = 0; attempt < 80; attempt++) {
      final faces = [..._faces]..shuffle(rng);
      final need = tiles.length ~/ 2;
      final bag = [for (int i = 0; i < need; i++) ...[faces[i], faces[i]]]
        ..shuffle(rng);
      for (int i = 0; i < tiles.length; i++) {
        tiles[i].face = bag[i];
        tiles[i].cleared = false;
      }
      if (_hasMoves()) return;
    }
  }

  bool _covered(_Tile t) => tiles.any(
      (o) => !o.cleared && o.z == t.z + 1 && o.x == t.x && o.y == t.y);

  bool _sideFree(_Tile t, int dx) => !tiles.any(
      (o) => !o.cleared && o.z == t.z && o.x == t.x + dx && o.y == t.y);

  bool _playable(_Tile t) =>
      !t.cleared && !_covered(t) && (_sideFree(t, -1) || _sideFree(t, 1));

  bool _hasMoves() {
    final free = tiles.where(_playable).toList();
    for (int i = 0; i < free.length; i++) {
      for (int j = i + 1; j < free.length; j++) {
        if (free[i].face == free[j].face) return true;
      }
    }
    return false;
  }

  void _tap(_Tile t) {
    if (over || popping.isNotEmpty) return;
    if (!_playable(t)) {
      Sfx.tap();
      return;
    }
    hintPair = [];
    if (selected == null) {
      Sfx.click();
      setState(() => selected = t);
    } else if (selected!.id == t.id) {
      Sfx.tap();
      setState(() => selected = null);
    } else if (selected!.face == t.face) {
      final a = selected!;
      setState(() {
        selected = null;
        popping.add(a.id);
        popping.add(t.id);
      });
      Sfx.move();
      Future.delayed(const Duration(milliseconds: 280), () {
        if (!mounted) return;
        setState(() {
          a.cleared = true;
          t.cleared = true;
          popping.clear();
          widget.players.first.score += 10;
          widget.callbacks.refreshHud();
          _afterMove();
        });
      });
    } else {
      Sfx.click();
      setState(() => selected = t);
    }
  }

  void _afterMove() {
    if (tiles.every((t) => t.cleared)) {
      _win();
      return;
    }
    if (!_hasMoves()) {
      if (shufflesLeft > 0) {
        setState(() => needShuffle = true);
      } else {
        _lose();
      }
    }
  }

  void _shuffleRescue() {
    if (over || shufflesLeft <= 0) return;
    Sfx.click();
    final rng = Random();
    final rest = tiles.where((t) => !t.cleared).toList();
    for (int attempt = 0; attempt < 100; attempt++) {
      final faces = rest.map((t) => t.face).toList()..shuffle(rng);
      for (int i = 0; i < rest.length; i++) {
        rest[i].face = faces[i];
      }
      if (_hasMoves()) break;
    }
    setState(() {
      shufflesLeft--;
      needShuffle = false;
      selected = null;
      widget.players.first.score =
          max(0, widget.players.first.score - 20);
      widget.callbacks.refreshHud();
    });
    if (!_hasMoves()) {
      if (shufflesLeft > 0) {
        setState(() => needShuffle = true);
      } else {
        _lose();
      }
    }
  }

  void _hint() {
    if (over) return;
    Sfx.tap();
    final free = tiles.where(_playable).toList();
    for (int i = 0; i < free.length; i++) {
      for (int j = i + 1; j < free.length; j++) {
        if (free[i].face == free[j].face) {
          setState(() => hintPair = [free[i].id, free[j].id]);
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => hintPair = []);
          });
          return;
        }
      }
    }
  }

  void _win() {
    if (over) return;
    over = true;
    Sfx.win();
    widget.players.first.score += 50;
    widget.callbacks.refreshHud();
    final name = (_layouts[layoutIdx]['name'] as String).toLowerCase();
    widget.callbacks.finish(
      headline: 'Board cleared! 🀄🎉',
      subline:
          'The $name layout is spotless. +50 pts — tile-matching royalty!',
    );
  }

  void _lose() {
    if (over) return;
    over = true;
    Sfx.lose();
    widget.callbacks.finish(
      headline: 'Out of moves! 🀄😅',
      subline:
          'No pairs left and no shuffles remaining. The tiles win this round — rematch?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (!started) return _setup(t);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('$pairsDone/$pairsTotal pairs',
                  style: TextStyle(
                      color: t.text, fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              _miniBtn(t, '💡', 'Hint', _hint),
              const SizedBox(width: 8),
              _miniBtn(t, '🌀 $shufflesLeft', 'Shuffle', _shuffleRescue),
              IconButton(
                tooltip: 'New layout',
                icon: const Icon(Icons.refresh),
                color: t.muted,
                onPressed: () {
                  Sfx.tap();
                  setState(() => started = false);
                },
              ),
            ],
          ),
        ),
        if (needShuffle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.secondary.withValues(alpha: 0.2),
                borderRadius: t.radius,
                border: Border.all(
                    color: t.secondary.withValues(alpha: 0.5)),
              ),
              child: Text(
                'No moves left! Tap 🌀 Shuffle to rescue the board ($shufflesLeft left).',
                style: TextStyle(
                    color: t.text, fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final area =
                  Size(constraints.maxWidth, constraints.maxHeight);
              final tw = min(54.0,
                  (area.width - 24 - maxZ * 8) / (maxX + 1));
              final th = tw * 1.28;
              final totalW = (maxX + 1) * tw + maxZ * 8;
              final totalH = (maxY + 1) * th + maxZ * 10;
              final ox = (area.width - totalW) / 2;
              final oy = (area.height - totalH) / 2;
              final ordered = [...tiles]..sort((a, b) {
                  final c = a.z.compareTo(b.z);
                  return c != 0 ? c : a.y.compareTo(b.y);
                });
              return Stack(
                children: [
                  for (final tile in ordered)
                    if (!tile.cleared)
                      Positioned(
                        left: ox + tile.x * tw + tile.z * 8,
                        top: oy + tile.y * th - tile.z * 10,
                        child: _tileWidget(tile, tw, th, t),
                      ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Tap two FREE tiles (not covered, open on at least one side) with matching faces 🀄',
            style: TextStyle(color: t.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _miniBtn(GameTheme t, String label, String tip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tip,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(99),
            border:
                Border.all(color: t.primary.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _tileWidget(_Tile tile, double w, double h, GameTheme t) {
    final playable = _playable(tile);
    final isSel = selected?.id == tile.id;
    final isHint = hintPair.contains(tile.id);
    final isPopping = popping.contains(tile.id);
    return GestureDetector(
      onTap: () => _tap(tile),
      child: AnimatedScale(
        scale: isPopping ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 260),
        child: AnimatedOpacity(
          opacity: playable ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: w,
            height: h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSel || isHint
                    ? [t.primary, t.secondary]
                    : [t.surface, t.surface],
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSel
                    ? t.accent
                    : isHint
                        ? const Color(0xFFFFD93D)
                        : t.primary.withValues(alpha: 0.35 + tile.z * 0.15),
                width: isSel || isHint ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              tile.face,
              style: TextStyle(fontSize: w * 0.52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setup(GameTheme t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your battlefield 🀄',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 12),
          for (int i = 0; i < _layouts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  Sfx.tap();
                  setState(() => layoutIdx = i);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: t.radius,
                    border: Border.all(
                      color: layoutIdx == i
                          ? t.primary
                          : t.primary.withValues(alpha: 0.2),
                      width: layoutIdx == i ? 3 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_layouts[i]['emoji'] as String,
                          style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_layouts[i]['name'] as String,
                                style: TextStyle(
                                    color: t.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(_layouts[i]['blurb'] as String,
                                style: TextStyle(
                                    color: t.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (layoutIdx == i)
                        Text('✅',
                            style: TextStyle(
                                fontSize: 20, color: t.primary)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          WajihaButton(label: 'Start matching', emoji: '🀄', onTap: _startGame),
          const SizedBox(height: 12),
          Text(
            'Match pairs of FREE tiles to clear the board. A tile is free when nothing sits on top of it and at least one side is open. Stuck? You get 3 shuffle rescues! 🌀',
            style: TextStyle(color: t.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

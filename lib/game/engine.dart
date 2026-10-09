// Pure-Dart game engine for Tile Solitaire. No Flutter imports.
// Implements ~/workspace/game-factory/stitch-batch3/tilesolitaire/RULES.md
// as the authoritative rules source of truth.
import 'dart:convert';
import 'dart:math';

/// One tile face. 36 unique faces x 4 copies = 144 tiles.
class TileFace {
  const TileFace(this.id, this.glyph, this.label, {this.honor = false});
  final int id;
  final String glyph;
  final String label;
  final bool honor;
}

const List<TileFace> kFaces = [
  // 28 standard faces (animals & nature).
  TileFace(0, '🐶', 'dog'),
  TileFace(1, '🐱', 'cat'),
  TileFace(2, '🐭', 'mouse'),
  TileFace(3, '🐹', 'hamster'),
  TileFace(4, '🐰', 'rabbit'),
  TileFace(5, '🦊', 'fox'),
  TileFace(6, '🐻', 'bear'),
  TileFace(7, '🐼', 'panda'),
  TileFace(8, '🐨', 'koala'),
  TileFace(9, '🐯', 'tiger'),
  TileFace(10, '🦁', 'lion'),
  TileFace(11, '🐮', 'cow'),
  TileFace(12, '🐷', 'pig'),
  TileFace(13, '🐸', 'frog'),
  TileFace(14, '🐵', 'monkey'),
  TileFace(15, '🐔', 'chicken'),
  TileFace(16, '🐧', 'penguin'),
  TileFace(17, '🐦', 'bird'),
  TileFace(18, '🐝', 'bee'),
  TileFace(19, '🦋', 'butterfly'),
  TileFace(20, '🐌', 'snail'),
  TileFace(21, '🐞', 'ladybug'),
  TileFace(22, '🦀', 'crab'),
  TileFace(23, '🐙', 'octopus'),
  TileFace(24, '🦑', 'squid'),
  TileFace(25, '🐳', 'whale'),
  TileFace(26, '🐬', 'dolphin'),
  TileFace(27, '🐠', 'fish'),
  // 8 honor faces: flowers & seasons (match any other honor tile).
  TileFace(28, '🌸', 'blossom', honor: true),
  TileFace(29, '🌼', 'daisy', honor: true),
  TileFace(30, '🌻', 'sunflower', honor: true),
  TileFace(31, '🌷', 'tulip', honor: true),
  TileFace(32, '🌱', 'spring sprout', honor: true),
  TileFace(33, '☀️', 'summer sun', honor: true),
  TileFace(34, '🍁', 'autumn maple', honor: true),
  TileFace(35, '❄️', 'winter snow', honor: true),
];

/// One ASCII layer of a layout. 'X' = tile cell, anything else = empty.
class LayoutLayer {
  const LayoutLayer(this.ox, this.oy, this.rows);
  final int ox;
  final int oy;
  final List<String> rows;
}

class LayoutDef {
  const LayoutDef({
    required this.name,
    required this.blurb,
    required this.layers,
  });
  final String name;
  final String blurb;
  final List<LayoutLayer> layers;
}

/// All layouts deal exactly 144 tiles (36 faces x 4 copies).
const List<LayoutDef> kLayouts = [
  LayoutDef(
    name: 'Turtle',
    blurb: 'Slow and steady clears the garden.',
    layers: [
      LayoutLayer(0, 0, [
        '.XXXXXXXXXXXX.',
        '.XXXXXXXXXXXX.',
        '.XXXXXXXXXXXX.',
        '.XXXXXXXXXXXXX',
        '.XXXXXXXXXXXX.',
        'XXXXXXXXXXXX..',
        '.XXXXXXXXXXXX.',
        '.XXXXXXXXXXXX.',
      ]),
      LayoutLayer(4, 1, [
        'XXXXXX',
        'XXXXXX',
        'XXXXXX',
        'XXXXXX',
        'XXXXXX',
        'XXXXXX',
      ]),
      LayoutLayer(6, 2, [
        'XXX',
        'XXX',
        'XXX',
      ]),
      LayoutLayer(7, 3, [
        'XX',
      ]),
    ],
  ),
  LayoutDef(
    name: 'Pagoda',
    blurb: 'Rise through the quiet tower.',
    layers: [
      LayoutLayer(0, 0, [
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
        'XXXXXXXXXXXX',
      ]),
      LayoutLayer(4, 0, [
        'XXXX',
        'XXXX',
        'XXXX',
        'XXXX',
        'XXXX',
        'XXXX',
        'XXXX',
        'XXXX',
      ]),
      LayoutLayer(5, 1, [
        'XX',
        'XX',
        'XX',
        'XX',
        'XX',
        'XX',
      ]),
      LayoutLayer(5, 3, [
        'XX',
        'XX',
      ]),
    ],
  ),
  LayoutDef(
    name: 'Bridge',
    blurb: 'Two towers, one deck, calm crossing.',
    layers: [
      LayoutLayer(0, 0, [
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
        'XXXXXX....XXXXXX',
      ]),
      LayoutLayer(3, 0, [
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
        '...XXXXXX...',
      ]),
    ],
  ),
];

class Tile {
  Tile({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.face,
  });
  final int id;
  final int x;
  final int y;
  final int z;
  int face;
  bool cleared = false;
}

class CaptureRecord {
  CaptureRecord({
    required this.aId,
    required this.bId,
    required this.faceA,
    required this.faceB,
    required this.points,
  });
  final int aId;
  final int bId;
  final int faceA;
  final int faceB;
  final int points;

  Map<String, dynamic> toJson() => {
        'a': aId,
        'b': bId,
        'fa': faceA,
        'fb': faceB,
        'p': points,
      };

  factory CaptureRecord.fromJson(Map<String, dynamic> j) => CaptureRecord(
        aId: j['a'] as int,
        bId: j['b'] as int,
        faceA: j['fa'] as int,
        faceB: j['fb'] as int,
        points: j['p'] as int,
      );
}

enum TapEvent { invalidTile, selected, deselected, mismatch, captured }

class TileSolitaireEngine {
  TileSolitaireEngine._({required this.tiles, required this.layoutIndex});

  static const int parTimeSeconds = 300;
  static const bool honorTilesMatchAny = true;
  static const int startingHints = 3;
  static const int startingShuffles = 3;
  static const int dealAttempts = 100;
  static const int shuffleAttempts = 50;

  final List<Tile> tiles;
  int layoutIndex;
  int? selectedId;
  int score = 0;
  int chain = 0;
  int hintsLeft = startingHints;
  int shufflesLeft = startingShuffles;
  int hintsUsed = 0;
  int shufflesUsed = 0;
  int moves = 0;
  int elapsedSeconds = 0;
  final List<CaptureRecord> undoStack = [];
  final List<int> capturedFaces = [];
  bool needShuffle = false;
  bool over = false;
  bool won = false;
  bool resigned = false;
  int winBonus = 0;

  factory TileSolitaireEngine.newGame({required int layoutIndex, int? seed}) {
    final def = kLayouts[layoutIndex];
    final tiles = <Tile>[];
    var id = 0;
    for (var z = 0; z < def.layers.length; z++) {
      final layer = def.layers[z];
      for (var y = 0; y < layer.rows.length; y++) {
        final row = layer.rows[y];
        for (var x = 0; x < row.length; x++) {
          if (row.codeUnitAt(x) == 0x58 /* X */) {
            tiles.add(Tile(
                id: id++, x: layer.ox + x, y: layer.oy + y, z: z, face: 0));
          }
        }
      }
    }
    assert(tiles.length == 144, 'layout must deal exactly 144 tiles');
    final engine = TileSolitaireEngine._(tiles: tiles, layoutIndex: layoutIndex);
    engine._deal(Random(seed ?? DateTime.now().microsecondsSinceEpoch));
    return engine;
  }

  void _deal(Random rng) {
    for (var attempt = 0; attempt < dealAttempts; attempt++) {
      final bag = <int>[
        for (var f = 0; f < kFaces.length; f++) ...[f, f, f, f]
      ]..shuffle(rng);
      for (var i = 0; i < tiles.length; i++) {
        tiles[i].face = bag[i];
        tiles[i].cleared = false;
      }
      if (findLegalPairs().isNotEmpty) return;
    }
    // Best-effort: keep the final deal even if it starts deadlocked.
  }

  int get remaining => tiles.where((t) => !t.cleared).length;
  int get pairsTotal => tiles.length ~/ 2;
  int get pairsDone => tiles.where((t) => t.cleared).length ~/ 2;
  int get maxX => tiles.fold(0, (m, t) => max(m, t.x));
  int get maxY => tiles.fold(0, (m, t) => max(m, t.y));
  int get maxZ => tiles.fold(0, (m, t) => max(m, t.z));

  bool _covered(Tile t) => tiles.any((o) =>
      o.id != t.id &&
      !o.cleared &&
      o.z == t.z + 1 &&
      o.x == t.x &&
      o.y == t.y);

  bool _sideBlocked(Tile t, int dx) => tiles.any((o) =>
      o.id != t.id &&
      !o.cleared &&
      o.z == t.z &&
      o.x == t.x + dx &&
      o.y == t.y);

  /// A tile is free iff nothing covers it AND at least one long side is open.
  bool isFree(Tile t) =>
      !t.cleared &&
      !_covered(t) &&
      (!_sideBlocked(t, -1) || !_sideBlocked(t, 1));

  /// Whether any tile rests directly above [t] (for the dusk-tint overlay).
  bool isCovered(Tile t) => _covered(t);

  bool facesMatch(Tile a, Tile b) {
    if (a.face == b.face) return true;
    if (honorTilesMatchAny &&
        kFaces[a.face].honor &&
        kFaces[b.face].honor) {
      return true;
    }
    return false;
  }

  /// All legal matching free pairs on the board.
  List<List<int>> findLegalPairs() {
    final free = tiles.where(isFree).toList();
    final pairs = <List<int>>[];
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (facesMatch(free[i], free[j])) {
          pairs.add([free[i].id, free[j].id]);
        }
      }
    }
    return pairs;
  }

  /// Hint: the legal pair whose removal frees the most tiles (1-ply
  /// lookahead); ties broken toward higher layers. Returns tile ids.
  List<int>? bestPair() {
    final free = tiles.where(isFree).toList();
    final before = <int>{for (final t in free) t.id};
    List<int>? best;
    var bestKey = -1;
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        final a = free[i], b = free[j];
        if (!facesMatch(a, b)) continue;
        a.cleared = true;
        b.cleared = true;
        var newlyFree = 0;
        try {
          for (final t in tiles) {
            if (t.cleared) continue;
            if (!before.contains(t.id) && isFree(t)) newlyFree++;
          }
        } finally {
          a.cleared = false;
          b.cleared = false;
        }
        final key = newlyFree * 100 + (a.z + b.z);
        if (key > bestKey) {
          bestKey = key;
          best = [a.id, b.id];
        }
      }
    }
    return best;
  }

  TapEvent tap(int tileId) {
    if (over) return TapEvent.invalidTile;
    final t = tiles[tileId];
    if (t.cleared) return TapEvent.invalidTile;
    if (!isFree(t)) {
      chain = 0;
      return TapEvent.invalidTile;
    }
    if (selectedId == null) {
      selectedId = tileId;
      return TapEvent.selected;
    }
    if (selectedId == tileId) {
      selectedId = null;
      chain = 0;
      return TapEvent.deselected;
    }
    final first = tiles[selectedId!];
    if (facesMatch(first, t)) {
      final points = 10 + 2 * chain;
      chain++;
      first.cleared = true;
      t.cleared = true;
      score += points;
      moves++;
      undoStack.add(CaptureRecord(
          aId: first.id, bId: t.id, faceA: first.face, faceB: t.face, points: points));
      capturedFaces.add(first.face);
      capturedFaces.add(t.face);
      selectedId = null;
      needShuffle = false;
      if (remaining == 0) {
        _win();
      }
      return TapEvent.captured;
    }
    // Mismatch: first selection is kept, second is rejected, chain resets.
    chain = 0;
    return TapEvent.mismatch;
  }

  void _win() {
    won = true;
    over = true;
    winBonus = max(0, parTimeSeconds - elapsedSeconds);
    score += winBonus;
  }

  /// Called after a capture resolves: detect deadlock (no legal pairs).
  void checkDeadlock() {
    if (over || remaining == 0) return;
    if (findLegalPairs().isEmpty) {
      if (shufflesLeft > 0) {
        needShuffle = true;
      } else {
        over = true;
      }
    }
  }

  /// Hint: highlights one legal pair. Returns the pair's tile ids, or null.
  List<int>? useHint() {
    if (over || hintsLeft <= 0) return null;
    final pair = bestPair();
    if (pair == null) return null;
    hintsLeft--;
    hintsUsed++;
    score = max(0, score - 5);
    chain = 0;
    return pair;
  }

  /// Shuffle: redistribute faces among remaining tiles, keeping positions.
  /// Returns false when no shuffle tokens remain.
  bool useShuffle() {
    if (over || shufflesLeft <= 0) return false;
    final rng = Random();
    final rest = tiles.where((t) => !t.cleared).toList();
    for (var attempt = 0; attempt < shuffleAttempts; attempt++) {
      final faces = rest.map((t) => t.face).toList()..shuffle(rng);
      for (var i = 0; i < rest.length; i++) {
        rest[i].face = faces[i];
      }
      if (findLegalPairs().isNotEmpty) break;
    }
    shufflesLeft--;
    shufflesUsed++;
    score = max(0, score - 25);
    chain = 0;
    selectedId = null;
    // Faces were redistributed, so earlier captures can no longer be
    // restored to their original faces: the undo stack is cleared.
    undoStack.clear();
    needShuffle = false;
    checkDeadlock();
    return true;
  }

  /// Undo: restore the most recently captured pair to its original cells.
  bool undo() {
    if (over || undoStack.isEmpty) return false;
    final c = undoStack.removeLast();
    final a = tiles[c.aId];
    final b = tiles[c.bId];
    a.cleared = false;
    a.face = c.faceA;
    b.cleared = false;
    b.face = c.faceB;
    score = max(0, score - c.points);
    chain = 0;
    selectedId = null;
    needShuffle = false;
    if (capturedFaces.length >= 2) {
      capturedFaces.removeRange(capturedFaces.length - 2, capturedFaces.length);
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'layout': layoutIndex,
        'tiles': [
          for (final t in tiles) [t.x, t.y, t.z, t.face, t.cleared ? 1 : 0]
        ],
        'sel': selectedId,
        'score': score,
        'chain': chain,
        'hintsLeft': hintsLeft,
        'shufflesLeft': shufflesLeft,
        'hintsUsed': hintsUsed,
        'shufflesUsed': shufflesUsed,
        'moves': moves,
        'elapsed': elapsedSeconds,
        'undo': [for (final c in undoStack) c.toJson()],
        'tray': capturedFaces,
        'needShuffle': needShuffle,
        'over': over,
        'won': won,
        'winBonus': winBonus,
      };

  factory TileSolitaireEngine.fromJson(Map<String, dynamic> j) {
    final tiles = <Tile>[];
    final raw = j['tiles'] as List;
    for (var i = 0; i < raw.length; i++) {
      final r = raw[i] as List;
      final t = Tile(
          id: i, x: r[0] as int, y: r[1] as int, z: r[2] as int, face: r[3] as int);
      t.cleared = (r[4] as int) == 1;
      tiles.add(t);
    }
    final e = TileSolitaireEngine._(
        tiles: tiles, layoutIndex: j['layout'] as int? ?? 0);
    e.selectedId = j['sel'] as int?;
    e.score = j['score'] as int? ?? 0;
    e.chain = j['chain'] as int? ?? 0;
    e.hintsLeft = j['hintsLeft'] as int? ?? startingHints;
    e.shufflesLeft = j['shufflesLeft'] as int? ?? startingShuffles;
    e.hintsUsed = j['hintsUsed'] as int? ?? 0;
    e.shufflesUsed = j['shufflesUsed'] as int? ?? 0;
    e.moves = j['moves'] as int? ?? 0;
    e.elapsedSeconds = j['elapsed'] as int? ?? 0;
    for (final u in (j['undo'] as List? ?? [])) {
      e.undoStack.add(CaptureRecord.fromJson((u as Map).cast<String, dynamic>()));
    }
    e.capturedFaces.addAll((j['tray'] as List? ?? []).cast<int>());
    e.needShuffle = j['needShuffle'] as bool? ?? false;
    e.over = j['over'] as bool? ?? false;
    e.won = j['won'] as bool? ?? false;
    e.winBonus = j['winBonus'] as int? ?? 0;
    return e;
  }

  String encode() => jsonEncode(toJson());

  factory TileSolitaireEngine.decode(String s) =>
      TileSolitaireEngine.fromJson(
          (jsonDecode(s) as Map).cast<String, dynamic>());
}

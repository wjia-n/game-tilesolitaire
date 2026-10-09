// Engine unit tests: RULES.md §13 test cases (pure Dart, cheap).
import 'package:flutter_test/flutter_test.dart';
import 'package:tilesolitaire/game/engine.dart';

TileSolitaireEngine seededGame(int layout, int seed) =>
    TileSolitaireEngine.newGame(layoutIndex: layout, seed: seed);

void main() {
  group('setup', () {
    test('TC-SETUP-01: every layout deals exactly 144 tiles, 4x each face',
        () {
      for (var l = 0; l < kLayouts.length; l++) {
        final e = seededGame(l, 42);
        expect(e.tiles.length, 144, reason: kLayouts[l].name);
        final counts = <int, int>{};
        for (final t in e.tiles) {
          counts[t.face] = (counts[t.face] ?? 0) + 1;
        }
        expect(counts.length, 36);
        for (final c in counts.values) {
          expect(c, 4);
        }
      }
    });

    test('TC-SETUP-02: a legal pair exists at game start', () {
      for (var l = 0; l < kLayouts.length; l++) {
        for (var seed = 1; seed <= 5; seed++) {
          final e = seededGame(l, seed);
          expect(e.findLegalPairs(), isNotEmpty,
              reason: '${kLayouts[l].name} seed $seed');
        }
      }
    });
  });

  group('free detection', () {
    test('TC-FREE-02/03: side-blocked vs side-open tiles', () {
      final e = seededGame(0, 7);
      // Find a tile blocked on both sides and one open on a side.
      Tile? blockedBoth, openOne;
      for (final t in e.tiles.where((t) => !e.isCovered(t))) {
        final left = e.tiles.any((o) =>
            o.id != t.id &&
            !o.cleared &&
            o.z == t.z &&
            o.x == t.x - 1 &&
            o.y == t.y);
        final right = e.tiles.any((o) =>
            o.id != t.id &&
            !o.cleared &&
            o.z == t.z &&
            o.x == t.x + 1 &&
            o.y == t.y);
        if (left && right && blockedBoth == null) blockedBoth = t;
        if ((!left || !right) && openOne == null) openOne = t;
      }
      expect(blockedBoth, isNotNull);
      expect(e.isFree(blockedBoth!), isFalse);
      expect(openOne, isNotNull);
      expect(e.isFree(openOne!), isTrue);
    });

    test('TC-FREE-01: a covered tile is not free', () {
      // Layout 3 (Zen Garden) has stacked layers.
      final e = seededGame(3, 11);
      final covered =
          e.tiles.firstWhere((t) => e.isCovered(t));
      expect(e.isFree(covered), isFalse);
      expect(e.tap(covered.id), TapEvent.invalidTile);
    });
  });

  group('matching & scoring', () {
    test('TC-MATCH-01: identical free faces capture, +10, tray +2', () {
      final e = seededGame(0, 21);
      final pair = e.findLegalPairs().first;
      final before = e.score;
      expect(e.tap(pair[0]), TapEvent.selected);
      expect(e.tap(pair[1]), TapEvent.captured);
      expect(e.score, before + 10);
      expect(e.capturedFaces.length, 2);
      expect(e.moves, 1);
    });

    test('TC-MATCH-02: flower + season honor tiles match', () {
      final e = seededGame(0, 21);
      final a = e.tiles.firstWhere((t) => t.face == 28);
      final b = e.tiles.firstWhere((t) => t.face == 33);
      expect(kFaces[a.face].honor, isTrue);
      expect(kFaces[b.face].honor, isTrue);
      expect(e.facesMatch(a, b), isTrue);
    });

    test('TC-MATCH-03: mismatch rejected, chain reset, board unchanged', () {
      final e = seededGame(0, 21);
      final free = e.tiles.where(e.isFree).toList();
      final a = free[0];
      final b = free.firstWhere((t) => !e.facesMatch(a, t));
      expect(e.tap(a.id), TapEvent.selected);
      expect(e.tap(b.id), TapEvent.mismatch);
      expect(e.chain, 0);
      expect(e.score, 0);
      expect(e.tiles.where((t) => t.cleared), isEmpty);
      // First selection is kept: tapping a match for `a` still works.
      expect(e.selectedId, a.id);
    });

    test('TC-CHAIN-01: consecutive pairs score 10, 12, 14', () {
      final e = seededGame(0, 21);
      var expected = 0;
      for (var step = 0; step < 3; step++) {
        final pair = e.findLegalPairs().first;
        e.tap(pair[0]);
        e.tap(pair[1]);
        expected += 10 + 2 * step;
        expect(e.score, expected);
      }
    });

    test('invalid tap on a covered tile does not reset the chain', () {
      final e = seededGame(3, 11);
      final pair = e.findLegalPairs().first;
      e.tap(pair[0]);
      e.tap(pair[1]);
      expect(e.chain, 1);
      final covered =
          e.tiles.firstWhere((t) => e.isCovered(t));
      e.tap(covered.id);
      expect(e.chain, 1, reason: 'chain survives non-miss taps');
    });
  });

  group('hint / shuffle / undo', () {
    test('TC-HINT-01: hint highlights a genuine legal pair', () {
      final e = seededGame(0, 21);
      final before = e.score;
      final pair = e.useHint();
      expect(pair, isNotNull);
      final a = e.tiles[pair![0]];
      final b = e.tiles[pair[1]];
      expect(e.isFree(a), isTrue);
      expect(e.isFree(b), isTrue);
      expect(e.facesMatch(a, b), isTrue);
      expect(e.hintsLeft, Difficulty.classic.hints - 1);
      expect(e.score, before); // score was 0, floor holds
    });

    test('TC-SHUFFLE-01: shuffle keeps positions, yields a legal pair',
        () {
      final e = seededGame(0, 21);
      final positions = {
        for (final t in e.tiles) t.id: [t.x, t.y, t.z]
      };
      expect(e.useShuffle(), isTrue);
      for (final t in e.tiles) {
        expect([t.x, t.y, t.z], positions[t.id]);
      }
      expect(e.findLegalPairs(), isNotEmpty);
      expect(e.shufflesLeft, Difficulty.classic.shuffles - 1);
    });

    test('TC-UNDO-01: undo restores the pair and refunds score', () {
      final e = seededGame(0, 21);
      final pair = e.findLegalPairs().first;
      e.tap(pair[0]);
      e.tap(pair[1]);
      expect(e.score, 10);
      expect(e.undo(), isTrue);
      expect(e.score, 0);
      expect(e.tiles[pair[0]].cleared, isFalse);
      expect(e.tiles[pair[1]].cleared, isFalse);
      expect(e.capturedFaces, isEmpty);
    });

    test('undo with empty history is a no-op', () {
      final e = seededGame(0, 21);
      expect(e.undo(), isFalse);
    });
  });

  group('persistence', () {
    test('encode/decode round-trips the full board state', () {
      final e = seededGame(0, 21);
      final pair = e.findLegalPairs().first;
      e.tap(pair[0]);
      e.tap(pair[1]);
      e.selectedId = e.findLegalPairs().first[0];
      e.elapsedSeconds = 77;
      final d = TileSolitaireEngine.decode(e.encode());
      expect(d.tiles.length, 144);
      for (var i = 0; i < 144; i++) {
        expect(d.tiles[i].face, e.tiles[i].face);
        expect(d.tiles[i].cleared, e.tiles[i].cleared);
      }
      expect(d.score, e.score);
      expect(d.selectedId, e.selectedId);
      expect(d.elapsedSeconds, 77);
      expect(d.undoStack.length, 1);
    });
  });

  group('win / deadlock', () {
    test('TC-WIN-01: clearing the last pair wins with time bonus', () {
      final e = TileSolitaireEngine.newGame(
          layoutIndex: 0,
          difficulty: Difficulty.gentle,
          seed: 21);
      // Remove every pair via the engine until one pair remains.
      while (e.remaining > 2) {
        final pairs = e.findLegalPairs();
        if (pairs.isEmpty) {
          expect(e.shufflesLeft, greaterThan(0),
              reason: 'ran out of shuffles mid-test');
          expect(e.useShuffle(), isTrue);
          continue;
        }
        e.tap(pairs.first[0]);
        e.tap(pairs.first[1]);
      }
      e.elapsedSeconds = 60;
      final before = e.score;
      final chainBefore = e.chain;
      final last = e.findLegalPairs().first;
      e.tap(last[0]);
      e.tap(last[1]);
      expect(e.won, isTrue);
      expect(e.over, isTrue);
      expect(e.remaining, 0);
      expect(e.winBonus, 240);
      expect(e.score, before + (10 + 2 * chainBefore) + 240);
    });
  });
}

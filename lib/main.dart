import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const TileSolitaireApp());

class TileSolitaireApp extends StatelessWidget {
  const TileSolitaireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Tile Solitaire',
      tagline: 'Match pairs of tiles to clear the beautiful layouts.',
      emoji: '🀄',
      slug: 'tilesolitaire',
      howToPlay:
          '• Pick a layout: Turtle, Pyramid or Bridge — tiles stack in layers.\n• Tap two FREE tiles with matching faces to clear them.\n• A tile is free when nothing covers it AND at least one side is open.\n• No moves left? Use a shuffle rescue (3 per game, −20 pts each).\n• Clear every tile to win. Out of moves and shuffles = game over! 🀄',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          TileSolitaireScreen(players: players, callbacks: cb),
    );
  }
}

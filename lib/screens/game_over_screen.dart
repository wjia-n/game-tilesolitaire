// Game over: "Garden Cleared" win screen and "No Moves Left" screen.
// Meditative, uncluttered: stone cairn, one ema plaque, stats, actions.
import 'package:flutter/material.dart';

import '../game/controller.dart';
import '../ui/zen.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.controller,
    required this.onPlayAgain,
    required this.onMenu,
  });
  final GameController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;

  bool get won => controller.phase == PlayPhase.won;

  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Cairn(size: won ? 130 : 96),
                  const SizedBox(height: 16),
                  Text(
                    won ? 'Garden Cleared' : 'No Moves Left',
                    style: Zen.heading(32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? 'Every tile rests in the tray.\nThe sand is still.'
                        : 'The tiles keep their secrets this time.\nRake the sand and try again.',
                    style: Zen.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  CedarPlaque(
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TallyChip(
                                label: 'SCORE', value: '${e.score}'),
                            TallyChip(
                                label: 'TIME',
                                value: Zen.clock(e.elapsedSeconds)),
                            TallyChip(
                                label: 'MOVES', value: '${e.moves}'),
                            TallyChip(
                                label: 'HINTS USED',
                                value: '${e.hintsUsed}'),
                          ],
                        ),
                        if (won && e.winBonus > 0) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Time bonus +${e.winBonus}',
                            style: const TextStyle(
                              color: Zen.deepMoss,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (won &&
                            controller.prefs.bestScore > 0 &&
                            e.score >= controller.prefs.bestScore) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'A new best score.',
                            style: TextStyle(
                              color: Zen.cedar,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  PebbleButton(
                    label: won ? 'Rake again' : 'Try again',
                    icon: Icons.spa,
                    big: true,
                    onTap: () {
                      controller.audio.playSfx('tap');
                      onPlayAgain();
                    },
                  ),
                  const SizedBox(height: 12),
                  PebbleButton(
                    label: 'Main menu',
                    icon: Icons.home,
                    kind: PebbleKind.secondary,
                    onTap: () {
                      controller.audio.playSfx('tap');
                      onMenu();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

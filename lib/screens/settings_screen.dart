// Settings: go-stone toggles and carved sand-groove sliders
// inside one continuous ema plaque.
import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/prefs.dart';
import '../ui/zen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.audio, required this.prefs});
  final AudioService audio;
  final GamePrefs prefs;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AudioService get audio => widget.audio;
  GamePrefs get prefs => widget.prefs;

  Future<void> _syncAudio() async {
    audio.musicEnabled = prefs.musicOn;
    audio.sfxEnabled = prefs.sfxOn;
    audio.musicVolume = prefs.musicVol;
    audio.sfxVolume = prefs.sfxVol;
    await prefs.saveSettings();
    await audio.applySettings();
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
                Row(
                  children: [
                    PebbleButton(
                      label: 'Back',
                      icon: Icons.arrow_back,
                      kind: PebbleKind.secondary,
                      onTap: () {
                        audio.playSfx('tap');
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text('Settings',
                          style: Zen.heading(26),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
                const SizedBox(height: 18),
                CedarPlaque(
                  child: Column(
                    children: [
                      _row(
                        icon: Icons.music_note,
                        title: 'Music',
                        subtitle: 'Gentle garden ambience',
                        control: GoStoneToggle(
                          value: prefs.musicOn,
                          semanticsLabel: 'Music',
                          onChanged: (v) {
                            audio.playSfx('tap');
                            setState(() => prefs.musicOn = v);
                            _syncAudio();
                          },
                        ),
                      ),
                      _divider(),
                      _row(
                        icon: Icons.volume_up,
                        title: 'Music volume',
                        subtitle: null,
                        control: Expanded(
                          child: SandGrooveSlider(
                            value: prefs.musicVol,
                            semanticsLabel: 'Music volume',
                            onChanged: (v) {
                              setState(() => prefs.musicVol = v);
                              _syncAudio();
                            },
                          ),
                        ),
                      ),
                      _divider(),
                      _row(
                        icon: Icons.graphic_eq,
                        title: 'Sound effects',
                        subtitle: 'Bamboo taps and soft chimes',
                        control: GoStoneToggle(
                          value: prefs.sfxOn,
                          semanticsLabel: 'Sound effects',
                          onChanged: (v) {
                            setState(() => prefs.sfxOn = v);
                            _syncAudio();
                            audio.playSfx('tap');
                          },
                        ),
                      ),
                      _divider(),
                      _row(
                        icon: Icons.volume_down,
                        title: 'Effects volume',
                        subtitle: null,
                        control: Expanded(
                          child: SandGrooveSlider(
                            value: prefs.sfxVol,
                            semanticsLabel: 'Effects volume',
                            onChanged: (v) {
                              setState(() => prefs.sfxVol = v);
                              _syncAudio();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CedarPlaque(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE GARDEN', style: Zen.chipLabel),
                      const SizedBox(height: 8),
                      const Text(
                        'Tile Solitaire by Wajiha.\n'
                        'Match every pair of tiles to clear the sand.\n'
                        'Flowers and seasons are wild and match each other.',
                        style: Zen.body,
                      ),
                      if (prefs.bestScore > 0) ...[
                        const SizedBox(height: 10),
                        TallyChip(
                            label: 'BEST SCORE',
                            value: '${prefs.bestScore}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String? subtitle,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Zen.bambooIvory,
              border: Border.all(color: Zen.sandGroove, width: 1.5),
            ),
            child: Icon(icon, color: Zen.deepMoss, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Zen.sumiInk)),
                if (subtitle != null)
                  Text(subtitle,
                      style:
                          Zen.body.copyWith(fontSize: 12, color: const Color(0xFF8A7A5C))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          control,
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Zen.sandGroove.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

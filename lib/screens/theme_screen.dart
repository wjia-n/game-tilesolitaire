// Theme picker: 12 garden themes + the custom garden creator.
// Pro-only themes are locked for free players (tap opens the Pro screen).
import 'dart:convert';

import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/prefs.dart';
import '../services/iap_service.dart';
import '../theme/garden_themes.dart';
import '../ui/zen.dart';
import 'pro_screen.dart';

class ThemeScreen extends StatefulWidget {
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;
  const ThemeScreen(
      {super.key,
      required this.audio,
      required this.prefs,
      required this.store});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  GamePrefs get prefs => widget.prefs;

  void _pick(String id) {
    widget.audio.playSfx('tap');
    final def = GardenThemes.byId(id);
    if (def.proOnly && !prefs.pro) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProScreen(
              audio: widget.audio, prefs: prefs, store: widget.store),
        ),
      );
      return;
    }
    setState(() {
      prefs.themeId = id;
      prefs.saveLook();
      GardenThemes.apply(id, custom: prefs.customTheme);
    });
  }

  void _openCustom() {
    widget.audio.playSfx('tap');
    if (!prefs.pro) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProScreen(
              audio: widget.audio, prefs: prefs, store: widget.store),
        ),
      );
      return;
    }
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CustomThemeScreen(
            audio: widget.audio, prefs: prefs),
      ),
    )
        .then((_) {
      setState(() {
        GardenThemes.apply(prefs.themeId, custom: prefs.customTheme);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    PebbleButton(
                      label: 'Back',
                      icon: Icons.arrow_back,
                      kind: PebbleKind.secondary,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text('Garden themes',
                          style: Zen.heading(24),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: GardenThemes.all.length + 1,
                  itemBuilder: (context, i) {
                    if (i == GardenThemes.all.length) {
                      return _customCard();
                    }
                    final def = GardenThemes.all[i];
                    final selected =
                        prefs.themeId == def.id && def.id != 'custom';
                    final locked = def.proOnly && !prefs.pro;
                    return GestureDetector(
                      onTap: () => _pick(def.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: def.palette.paperWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Zen.deepMoss
                                : def.palette.sandGroove,
                            width: selected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Zen.sumiInk.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: def.palette.sand,
                                  border: Border.all(
                                      color: def.palette.darkCedar,
                                      width: 1.5),
                                ),
                                child: Center(
                                  child: _miniTile(def.palette),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 0, 10, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      def.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: def.palette.sumiInk,
                                      ),
                                    ),
                                  ),
                                  if (locked)
                                    Icon(Icons.lock,
                                        size: 16,
                                        color: def.palette.sandGroove),
                                  if (selected)
                                    Icon(Icons.check_circle,
                                        color: Zen.deepMoss, size: 18),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Text(
                                def.blurb,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: def.palette.sumiInk
                                      .withValues(alpha: 0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTile(GardenPalette p) {
    return Container(
      width: 44,
      height: 58,
      decoration: BoxDecoration(
        color: p.bambooIvory,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: p.darkCedar, width: 2),
        boxShadow: [
          BoxShadow(
            color: p.sumiInk.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.sumiInk, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _customCard() {
    final selected = prefs.themeId == 'custom';
    final locked = !prefs.pro;
    return GestureDetector(
      onTap: _openCustom,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Zen.paperWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Zen.deepMoss : Zen.sandGroove,
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Zen.sumiInk.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.palette,
                size: 40,
                color: locked ? Zen.sandGroove : Zen.deepMoss),
            const SizedBox(height: 8),
            Text(
              'Custom garden',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Zen.sumiInk),
            ),
            const SizedBox(height: 2),
            Text(
              locked ? 'PRO — rake your own colors' : 'Rake your own colors',
              style: Zen.body.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            if (locked)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.lock,
                    size: 16, color: Zen.sandGroove),
              ),
            if (selected)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.check_circle,
                    color: Zen.deepMoss, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom garden creator: pick natural tones for each material.
/// Pro-only.
class CustomThemeScreen extends StatefulWidget {
  final AudioService audio;
  final GamePrefs prefs;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.prefs});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late GardenPalette _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.prefs.customTheme ?? GardenThemes.byId('classic').palette;
  }

  void _save() {
    widget.audio.playSfx('tap');
    widget.prefs.themeId = 'custom';
    widget.prefs.customThemeJson = jsonEncode(_draft.toJson());
    widget.prefs.saveLook();
    GardenThemes.apply('custom', custom: _draft);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Sand', (GardenPalette p) => p.sand, (p, c) => _copy(p, sand: c)),
      ('Tile face', (GardenPalette p) => p.bambooIvory,
          (p, c) => _copy(p, bambooIvory: c)),
      ('Tile base', (GardenPalette p) => p.cedar, (p, c) => _copy(p, cedar: c)),
      ('Buttons', (GardenPalette p) => p.moss, (p, c) => _copy(p, moss: c)),
      ('Ink', (GardenPalette p) => p.sumiInk, (p, c) => _copy(p, sumiInk: c)),
      ('Stones', (GardenPalette p) => p.riverStone,
          (p, c) => _copy(p, riverStone: c)),
    ];
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    PebbleButton(
                      label: 'Back',
                      icon: Icons.arrow_back,
                      kind: PebbleKind.secondary,
                      onTap: () {
                        widget.audio.playSfx('tap');
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text('Custom garden',
                          style: Zen.heading(24),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: CedarPlaque(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in rows) ...[
                          Text(r.$1,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Zen.sumiInk)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final c in GardenThemes.swatches)
                                GestureDetector(
                                  onTap: () {
                                    widget.audio.playSfx('tap');
                                    setState(() =>
                                        _draft = r.$3(_draft, c));
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: r.$2(_draft) == c
                                            ? Zen.deepMoss
                                            : Zen.sandGroove,
                                        width:
                                            r.$2(_draft) == c ? 3 : 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Center(
                          child: PebbleButton(
                            label: 'Rake this garden',
                            icon: Icons.check,
                            big: true,
                            onTap: _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GardenPalette _copy(GardenPalette p,
      {Color? sand,
      Color? bambooIvory,
      Color? cedar,
      Color? moss,
      Color? sumiInk,
      Color? riverStone}) {
    return GardenPalette(
      sand: sand ?? p.sand,
      sandGroove: p.sandGroove,
      bambooIvory: bambooIvory ?? p.bambooIvory,
      paperWhite: p.paperWhite,
      sumiInk: sumiInk ?? p.sumiInk,
      moss: moss ?? p.moss,
      deepMoss: moss ?? p.deepMoss,
      cedar: cedar ?? p.cedar,
      darkCedar: p.darkCedar,
      riverStone: riverStone ?? p.riverStone,
      tray: cedar ?? p.tray,
      accent: moss ?? p.accent,
    );
  }
}

// Tile-face style picker: 9 engraved motif sets.
// Pro-only styles are locked for free players (tap opens the Pro screen).
import 'package:flutter/material.dart';

import '../game/audio_service.dart';
import '../game/prefs.dart';
import '../services/iap_service.dart';
import '../theme/face_styles.dart';
import '../ui/zen.dart';
import 'pro_screen.dart';

class FaceStyleScreen extends StatefulWidget {
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;
  const FaceStyleScreen(
      {super.key,
      required this.audio,
      required this.prefs,
      required this.store});

  @override
  State<FaceStyleScreen> createState() => _FaceStyleScreenState();
}

class _FaceStyleScreenState extends State<FaceStyleScreen> {
  GamePrefs get prefs => widget.prefs;

  void _pick(FaceStyleDef def) {
    widget.audio.playSfx('tap');
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
      prefs.faceStyleId = def.id;
      prefs.saveLook();
      FaceStyles.apply(def.id);
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
                      child: Text('Tile faces',
                          style: Zen.heading(24),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  itemCount: FaceStyles.all.length,
                  itemBuilder: (context, i) {
                    final def = FaceStyles.all[i];
                    final selected = prefs.faceStyleId == def.id;
                    final locked = def.proOnly && !prefs.pro;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _pick(def),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Zen.cedar,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Zen.deepMoss
                                  : Zen.darkCedar,
                              width: selected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Zen.sumiInk.withValues(alpha: 0.25),
                                blurRadius: selected ? 10 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Zen.paperWhite
                                  : Zen.bambooIvory,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              def.name,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: Zen.sumiInk,
                                              ),
                                            ),
                                          ),
                                          if (locked)
                                            Icon(Icons.lock,
                                                size: 16,
                                                color: Zen.sandGroove),
                                          if (selected)
                                            Icon(Icons.check_circle,
                                                color: Zen.deepMoss,
                                                size: 22),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(def.blurb,
                                          style: Zen.body
                                              .copyWith(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      // Motif strip: first 8 faces.
                                      Row(
                                        children: [
                                          for (var f = 0;
                                              f < 8;
                                              f++)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      right: 5),
                                              child: Container(
                                                width: 30,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: Zen.paperWhite,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5),
                                                  border: Border.all(
                                                      color: Zen.sandGroove),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    def.faces[f].glyph,
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

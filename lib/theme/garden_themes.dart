// Garden themes: 12 zen palettes + custom gardens, all persisted.
// Every palette keeps the Stitch art direction: natural materials,
// misty calm tones, zero neon. Widgets read colors via Zen getters,
// which delegate to GardenThemes.current.
import 'package:flutter/material.dart';

/// A full color palette for one garden.
class GardenPalette {
  const GardenPalette({
    required this.sand,
    required this.sandGroove,
    required this.bambooIvory,
    required this.paperWhite,
    required this.sumiInk,
    required this.moss,
    required this.deepMoss,
    required this.cedar,
    required this.darkCedar,
    required this.riverStone,
    required this.tray,
    required this.accent,
  });

  final Color sand;
  final Color sandGroove;
  final Color bambooIvory;
  final Color paperWhite;
  final Color sumiInk;
  final Color moss;
  final Color deepMoss;
  final Color cedar;
  final Color darkCedar;
  final Color riverStone;
  final Color tray;
  final Color accent;

  Map<String, int> toJson() => {
        'sand': sand.toARGB32(),
        'sandGroove': sandGroove.toARGB32(),
        'bambooIvory': bambooIvory.toARGB32(),
        'paperWhite': paperWhite.toARGB32(),
        'sumiInk': sumiInk.toARGB32(),
        'moss': moss.toARGB32(),
        'deepMoss': deepMoss.toARGB32(),
        'cedar': cedar.toARGB32(),
        'darkCedar': darkCedar.toARGB32(),
        'riverStone': riverStone.toARGB32(),
        'tray': tray.toARGB32(),
        'accent': accent.toARGB32(),
      };

  factory GardenPalette.fromJson(Map<String, dynamic> j) => GardenPalette(
        sand: Color(j['sand'] as int),
        sandGroove: Color(j['sandGroove'] as int),
        bambooIvory: Color(j['bambooIvory'] as int),
        paperWhite: Color(j['paperWhite'] as int),
        sumiInk: Color(j['sumiInk'] as int),
        moss: Color(j['moss'] as int),
        deepMoss: Color(j['deepMoss'] as int),
        cedar: Color(j['cedar'] as int),
        darkCedar: Color(j['darkCedar'] as int),
        riverStone: Color(j['riverStone'] as int),
        tray: Color(j['tray'] as int),
        accent: Color(j['accent'] as int),
      );
}

class GardenThemeDef {
  const GardenThemeDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.palette,
    this.proOnly = false,
  });

  final String id;
  final String name;
  final String blurb;
  final GardenPalette palette;
  final bool proOnly;
}

class GardenThemes {
  GardenThemes._();

  /// The palette every Zen widget reads. Set from the persisted theme id
  /// (or a custom garden) at startup and whenever the user picks one.
  static GardenPalette current = byId('classic').palette;

  static void apply(String id, {GardenPalette? custom}) {
    if (id == 'custom' && custom != null) {
      current = custom;
      return;
    }
    current = byId(id).palette;
  }

  static GardenThemeDef byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static const List<GardenThemeDef> all = [
    GardenThemeDef(
      id: 'classic',
      name: 'Classic Zen',
      blurb: 'Raked sand, bamboo and moss.',
      palette: GardenPalette(
        sand: Color(0xFFE8DCC3),
        sandGroove: Color(0xFFD2C2A3),
        bambooIvory: Color(0xFFF5EFDD),
        paperWhite: Color(0xFFFAF7F0),
        sumiInk: Color(0xFF2B2620),
        moss: Color(0xFF6B7F5E),
        deepMoss: Color(0xFF4E6143),
        cedar: Color(0xFF8C6D46),
        darkCedar: Color(0xFF5A432A),
        riverStone: Color(0xFF8A8D8F),
        tray: Color(0xFF8C6D46),
        accent: Color(0xFF6B7F5E),
      ),
    ),
    GardenThemeDef(
      id: 'morning',
      name: 'Morning Mist',
      blurb: 'Pale dawn light on cool sand.',
      palette: GardenPalette(
        sand: Color(0xFFEDE8DA),
        sandGroove: Color(0xFFD8D0BC),
        bambooIvory: Color(0xFFF8F4E8),
        paperWhite: Color(0xFFFFFFFF),
        sumiInk: Color(0xFF3A3733),
        moss: Color(0xFF8A9B7E),
        deepMoss: Color(0xFF64745A),
        cedar: Color(0xFFA68B62),
        darkCedar: Color(0xFF6E5738),
        riverStone: Color(0xFF9AA0A3),
        tray: Color(0xFFA68B62),
        accent: Color(0xFF8A9B7E),
      ),
    ),
    GardenThemeDef(
      id: 'dusk',
      name: 'Cedar Dusk',
      blurb: 'Warm evening wood and long shadows.',
      palette: GardenPalette(
        sand: Color(0xFFDDC9A8),
        sandGroove: Color(0xFFC2A87F),
        bambooIvory: Color(0xFFF1E4C8),
        paperWhite: Color(0xFFFBF3E2),
        sumiInk: Color(0xFF2E2418),
        moss: Color(0xFF7A8455),
        deepMoss: Color(0xFF585F3C),
        cedar: Color(0xFF9A6B3F),
        darkCedar: Color(0xFF5E3F22),
        riverStone: Color(0xFF8F8578),
        tray: Color(0xFF9A6B3F),
        accent: Color(0xFFB07A3F),
      ),
    ),
    GardenThemeDef(
      id: 'river',
      name: 'River Stone',
      blurb: 'Cool greys, water-worn and quiet.',
      palette: GardenPalette(
        sand: Color(0xFFE3DED4),
        sandGroove: Color(0xFFC6C0B1),
        bambooIvory: Color(0xFFF4F1E8),
        paperWhite: Color(0xFFFBFAF5),
        sumiInk: Color(0xFF2C2C2A),
        moss: Color(0xFF7D8B84),
        deepMoss: Color(0xFF59655E),
        cedar: Color(0xFF8D7B63),
        darkCedar: Color(0xFF57493A),
        riverStone: Color(0xFF7E8891),
        tray: Color(0xFF7E8891),
        accent: Color(0xFF5E7A8C),
      ),
    ),
    GardenThemeDef(
      id: 'maple',
      name: 'Autumn Maple',
      blurb: 'Falling leaves on golden sand.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFE9D3B4),
        sandGroove: Color(0xFFD3B489),
        bambooIvory: Color(0xFFF6EBD6),
        paperWhite: Color(0xFFFCF6E9),
        sumiInk: Color(0xFF33241A),
        moss: Color(0xFF8C7A4E),
        deepMoss: Color(0xFF65562F),
        cedar: Color(0xFF9C5F36),
        darkCedar: Color(0xFF5F3A1E),
        riverStone: Color(0xFF8F8578),
        tray: Color(0xFF9C5F36),
        accent: Color(0xFFB4552D),
      ),
    ),
    GardenThemeDef(
      id: 'bamboo',
      name: 'Bamboo Shoot',
      blurb: 'Fresh greens after the rain.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFE4DCC0),
        sandGroove: Color(0xFFC9BE97),
        bambooIvory: Color(0xFFF3EFDC),
        paperWhite: Color(0xFFFAF8EC),
        sumiInk: Color(0xFF27301F),
        moss: Color(0xFF5F7F4A),
        deepMoss: Color(0xFF425C30),
        cedar: Color(0xFF8A6B42),
        darkCedar: Color(0xFF55401F),
        riverStone: Color(0xFF8A8D84),
        tray: Color(0xFF8A6B42),
        accent: Color(0xFF5F7F4A),
      ),
    ),
    GardenThemeDef(
      id: 'moonlit',
      name: 'Moonlit Sand',
      blurb: 'Night garden under a paper moon.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFD9D5C6),
        sandGroove: Color(0xFFBDB8A4),
        bambooIvory: Color(0xFFEFEAD9),
        paperWhite: Color(0xFFF7F4E8),
        sumiInk: Color(0xFF23272B),
        moss: Color(0xFF6E7F76),
        deepMoss: Color(0xFF4C5A54),
        cedar: Color(0xFF7A6A52),
        darkCedar: Color(0xFF4A3E2C),
        riverStone: Color(0xFF7B8288),
        tray: Color(0xFF5A5E63),
        accent: Color(0xFF7A8BA0),
      ),
    ),
    GardenThemeDef(
      id: 'blossom',
      name: 'Cherry Blossom',
      blurb: 'Soft petals drifting on the rake lines.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFEDDCCB),
        sandGroove: Color(0xFFD9BFA8),
        bambooIvory: Color(0xFFF7EEE2),
        paperWhite: Color(0xFFFCF7F0),
        sumiInk: Color(0xFF33272A),
        moss: Color(0xFF8A7F6A),
        deepMoss: Color(0xFF645A49),
        cedar: Color(0xFF96755A),
        darkCedar: Color(0xFF5C4636),
        riverStone: Color(0xFF948B84),
        tray: Color(0xFF96755A),
        accent: Color(0xFFB47A7A),
      ),
    ),
    GardenThemeDef(
      id: 'dune',
      name: 'Desert Dune',
      blurb: 'Sun-baked sand and dark basalt.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFE3C99B),
        sandGroove: Color(0xFFCCA971),
        bambooIvory: Color(0xFFF2E3C4),
        paperWhite: Color(0xFFFAF0DA),
        sumiInk: Color(0xFF2E2318),
        moss: Color(0xFF8C7A4E),
        deepMoss: Color(0xFF65562F),
        cedar: Color(0xFF8A5A33),
        darkCedar: Color(0xFF523315),
        riverStone: Color(0xFF7D7268),
        tray: Color(0xFF8A5A33),
        accent: Color(0xFFA05A2C),
      ),
    ),
    GardenThemeDef(
      id: 'rain',
      name: 'Rainy Moss',
      blurb: 'Wet stones, deep greens, still air.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFD8D2BE),
        sandGroove: Color(0xFFB9B294),
        bambooIvory: Color(0xFFEEEAD8),
        paperWhite: Color(0xFFF6F3E6),
        sumiInk: Color(0xFF22281E),
        moss: Color(0xFF4F6B46),
        deepMoss: Color(0xFF35492E),
        cedar: Color(0xFF77644A),
        darkCedar: Color(0xFF463A26),
        riverStone: Color(0xFF6E7A72),
        tray: Color(0xFF6E7A72),
        accent: Color(0xFF4F6B46),
      ),
    ),
    GardenThemeDef(
      id: 'ember',
      name: 'Ember Hearth',
      blurb: 'Hearth-warm clay and quiet fire.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFE6CDAE),
        sandGroove: Color(0xFFCFAC84),
        bambooIvory: Color(0xFFF4E7D2),
        paperWhite: Color(0xFFFBF3E4),
        sumiInk: Color(0xFF2F2119),
        moss: Color(0xFF7C6B4A),
        deepMoss: Color(0xFF59492C),
        cedar: Color(0xFF9A5A34),
        darkCedar: Color(0xFF5B3419),
        riverStone: Color(0xFF8A7D70),
        tray: Color(0xFF9A5A34),
        accent: Color(0xFFB45A2E),
      ),
    ),
    GardenThemeDef(
      id: 'pine',
      name: 'Old Pine',
      blurb: 'Deep shade beneath ancient boughs.',
      proOnly: true,
      palette: GardenPalette(
        sand: Color(0xFFDCD2B8),
        sandGroove: Color(0xFFBFB393),
        bambooIvory: Color(0xFFF0E9D4),
        paperWhite: Color(0xFFF8F4E6),
        sumiInk: Color(0xFF20241C),
        moss: Color(0xFF55663F),
        deepMoss: Color(0xFF39452A),
        cedar: Color(0xFF7C5E3E),
        darkCedar: Color(0xFF483723),
        riverStone: Color(0xFF7C8078),
        tray: Color(0xFF7C5E3E),
        accent: Color(0xFF55663F),
      ),
    ),
  ];

  /// Swatch sets for the custom garden creator (natural tones only).
  static const List<Color> swatches = [
    Color(0xFFE8DCC3),
    Color(0xFFEDE8DA),
    Color(0xFFDDC9A8),
    Color(0xFFE3DED4),
    Color(0xFFE9D3B4),
    Color(0xFFD9D5C6),
    Color(0xFFF5EFDD),
    Color(0xFF2B2620),
    Color(0xFF6B7F5E),
    Color(0xFF4E6143),
    Color(0xFF8C6D46),
    Color(0xFF5A432A),
    Color(0xFF8A8D8F),
    Color(0xFFB4552D),
    Color(0xFF7A8BA0),
    Color(0xFFB47A7A),
  ];
}

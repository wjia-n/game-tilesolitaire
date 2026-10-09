// Tile-face styles: 9 engraved motif sets, persisted per player.
// Every style defines 36 faces: ids 0-27 standard, 28-35 honor
// (flowers/seasons — any-two-match, per RULES.md §7).
// The engine matches by face id; this file only changes the visible glyph.

class FaceGlyph {
  const FaceGlyph(this.glyph, this.label);
  final String glyph;
  final String label;
}

class FaceStyleDef {
  const FaceStyleDef({
    required this.id,
    required this.name,
    required this.blurb,
    required this.faces,
    this.proOnly = false,
  }); // 36-face invariant is checked by FaceStyles._checkFaces() below.

  final String id;
  final String name;
  final String blurb;
  final List<FaceGlyph> faces;
  final bool proOnly;
}

class FaceStyles {
  FaceStyles._();

  static FaceStyleDef current = byId('classic');

  static void apply(String id) {
    current = byId(id);
  }

  static FaceStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static const List<FaceStyleDef> _all = [
    FaceStyleDef(
      id: 'classic',
      name: 'Garden Animals',
      blurb: 'The original animal friends.',
      faces: [
        FaceGlyph('🐶', 'dog'), FaceGlyph('🐱', 'cat'),
        FaceGlyph('🐭', 'mouse'), FaceGlyph('🐹', 'hamster'),
        FaceGlyph('🐰', 'rabbit'), FaceGlyph('🦊', 'fox'),
        FaceGlyph('🐻', 'bear'), FaceGlyph('🐼', 'panda'),
        FaceGlyph('🐨', 'koala'), FaceGlyph('🐯', 'tiger'),
        FaceGlyph('🦁', 'lion'), FaceGlyph('🐮', 'cow'),
        FaceGlyph('🐷', 'pig'), FaceGlyph('🐸', 'frog'),
        FaceGlyph('🐵', 'monkey'), FaceGlyph('🐔', 'chicken'),
        FaceGlyph('🐧', 'penguin'), FaceGlyph('🐦', 'bird'),
        FaceGlyph('🐝', 'bee'), FaceGlyph('🦋', 'butterfly'),
        FaceGlyph('🐌', 'snail'), FaceGlyph('🐞', 'ladybug'),
        FaceGlyph('🦀', 'crab'), FaceGlyph('🐙', 'octopus'),
        FaceGlyph('🦑', 'squid'), FaceGlyph('🐳', 'whale'),
        FaceGlyph('🐬', 'dolphin'), FaceGlyph('🐠', 'fish'),
        FaceGlyph('🌸', 'blossom'), FaceGlyph('🌼', 'daisy'),
        FaceGlyph('🌻', 'sunflower'), FaceGlyph('🌷', 'tulip'),
        FaceGlyph('🌱', 'spring sprout'), FaceGlyph('☀️', 'summer sun'),
        FaceGlyph('🍁', 'autumn maple'), FaceGlyph('❄️', 'winter snow'),
      ],
    ),
    FaceStyleDef(
      id: 'flowers',
      name: 'Flower Garden',
      blurb: 'Petals, leaves and quiet blooms.',
      faces: [
        FaceGlyph('🌸', 'cherry blossom'), FaceGlyph('🌼', 'daisy'),
        FaceGlyph('🌻', 'sunflower'), FaceGlyph('🌷', 'tulip'),
        FaceGlyph('🌹', 'rose'), FaceGlyph('🌺', 'hibiscus'),
        FaceGlyph('💐', 'bouquet'), FaceGlyph('🪷', 'lotus'),
        FaceGlyph('🌱', 'sprout'), FaceGlyph('🌿', 'herb'),
        FaceGlyph('☘️', 'clover'), FaceGlyph('🍀', 'four-leaf clover'),
        FaceGlyph('🍁', 'maple leaf'), FaceGlyph('🍂', 'fallen leaf'),
        FaceGlyph('🍃', 'leaf flutter'), FaceGlyph('🌾', 'rice sheaf'),
        FaceGlyph('🌵', 'cactus'), FaceGlyph('🌴', 'palm'),
        FaceGlyph('🎍', 'pine decoration'), FaceGlyph('🎋', 'bamboo'),
        FaceGlyph('🪴', 'potted plant'), FaceGlyph('🌲', 'evergreen'),
        FaceGlyph('🌳', 'tree'), FaceGlyph('🍄', 'mushroom'),
        FaceGlyph('🌰', 'chestnut'), FaceGlyph('🐚', 'shell'),
        FaceGlyph('🪨', 'rock'), FaceGlyph('💧', 'dewdrop'),
        FaceGlyph('🏵️', 'rosette'), FaceGlyph('🌺', 'mallow'),
        FaceGlyph('🌷', 'wild tulip'), FaceGlyph('🪷', 'water lotus'),
        FaceGlyph('🍃', 'spring leaf'), FaceGlyph('☀️', 'summer sun'),
        FaceGlyph('🍁', 'autumn leaf'), FaceGlyph('❄️', 'winter snow'),
      ],
    ),
    FaceStyleDef(
      id: 'mahjong',
      name: 'Sumi Mahjong',
      blurb: 'Classic engraved characters and suits.',
      faces: [
        FaceGlyph('一萬', 'one of characters'), FaceGlyph('二萬', 'two of characters'),
        FaceGlyph('三萬', 'three of characters'), FaceGlyph('四萬', 'four of characters'),
        FaceGlyph('五萬', 'five of characters'), FaceGlyph('六萬', 'six of characters'),
        FaceGlyph('七萬', 'seven of characters'), FaceGlyph('八萬', 'eight of characters'),
        FaceGlyph('九萬', 'nine of characters'), FaceGlyph('①', 'one dot'),
        FaceGlyph('②', 'two dots'), FaceGlyph('③', 'three dots'),
        FaceGlyph('④', 'four dots'), FaceGlyph('⑤', 'five dots'),
        FaceGlyph('⑥', 'six dots'), FaceGlyph('⑦', 'seven dots'),
        FaceGlyph('⑧', 'eight dots'), FaceGlyph('⑨', 'nine dots'),
        FaceGlyph('一筒', 'one bamboo'), FaceGlyph('二筒', 'two bamboo'),
        FaceGlyph('三筒', 'three bamboo'), FaceGlyph('四筒', 'four bamboo'),
        FaceGlyph('五筒', 'five bamboo'), FaceGlyph('六筒', 'six bamboo'),
        FaceGlyph('七筒', 'seven bamboo'), FaceGlyph('八筒', 'eight bamboo'),
        FaceGlyph('九筒', 'nine bamboo'), FaceGlyph('中', 'red dragon'),
        FaceGlyph('東', 'east wind'), FaceGlyph('南', 'south wind'),
        FaceGlyph('西', 'west wind'), FaceGlyph('北', 'north wind'),
        FaceGlyph('春', 'spring'), FaceGlyph('夏', 'summer'),
        FaceGlyph('秋', 'autumn'), FaceGlyph('冬', 'winter'),
      ],
    ),
    FaceStyleDef(
      id: 'ocean',
      name: 'Quiet Ocean',
      blurb: 'Tide pools and deep-water friends.',
      proOnly: true,
      faces: [
        FaceGlyph('🐠', 'tropical fish'), FaceGlyph('🐟', 'fish'),
        FaceGlyph('🐡', 'pufferfish'), FaceGlyph('🦈', 'shark'),
        FaceGlyph('🐙', 'octopus'), FaceGlyph('🦑', 'squid'),
        FaceGlyph('🦀', 'crab'), FaceGlyph('🦞', 'lobster'),
        FaceGlyph('🦐', 'shrimp'), FaceGlyph('🐚', 'shell'),
        FaceGlyph('🪸', 'coral'), FaceGlyph('🐢', 'turtle'),
        FaceGlyph('🐬', 'dolphin'), FaceGlyph('🐳', 'whale'),
        FaceGlyph('🦭', 'seal'), FaceGlyph('🐧', 'penguin'),
        FaceGlyph('🦆', 'duck'), FaceGlyph('🪿', 'goose'),
        FaceGlyph('💧', 'droplet'), FaceGlyph('🌊', 'wave'),
        FaceGlyph('🫧', 'bubbles'), FaceGlyph('⚓', 'anchor'),
        FaceGlyph('⛵', 'sailboat'), FaceGlyph('🛟', 'lifebuoy'),
        FaceGlyph('🏝️', 'island'), FaceGlyph('🌅', 'sunrise'),
        FaceGlyph('🌇', 'sunset'), FaceGlyph('🌙', 'moon'),
        FaceGlyph('🪷', 'sea lotus'), FaceGlyph('🌸', 'sea blossom'),
        FaceGlyph('🐚', 'spiral shell'), FaceGlyph('🪸', 'reef coral'),
        FaceGlyph('🌱', 'spring tide'), FaceGlyph('☀️', 'summer sun'),
        FaceGlyph('🍁', 'autumn drift'), FaceGlyph('❄️', 'winter frost'),
      ],
    ),
    FaceStyleDef(
      id: 'forest',
      name: 'Deep Forest',
      blurb: 'Moss, mushrooms and woodland kin.',
      proOnly: true,
      faces: [
        FaceGlyph('🦊', 'fox'), FaceGlyph('🐻', 'bear'),
        FaceGlyph('🐰', 'rabbit'), FaceGlyph('🦌', 'deer'),
        FaceGlyph('🐗', 'boar'), FaceGlyph('🦡', 'badger'),
        FaceGlyph('🐿️', 'squirrel'), FaceGlyph('🦔', 'hedgehog'),
        FaceGlyph('🦉', 'owl'), FaceGlyph('🐦', 'songbird'),
        FaceGlyph('🦅', 'eagle'), FaceGlyph('🪶', 'feather'),
        FaceGlyph('🐸', 'frog'), FaceGlyph('🦎', 'lizard'),
        FaceGlyph('🐍', 'snake'), FaceGlyph('🐢', 'tortoise'),
        FaceGlyph('🐝', 'bee'), FaceGlyph('🦋', 'butterfly'),
        FaceGlyph('🐞', 'ladybug'), FaceGlyph('🪲', 'beetle'),
        FaceGlyph('🐜', 'ant'), FaceGlyph('🕷️', 'spider'),
        FaceGlyph('🍄', 'mushroom'), FaceGlyph('🌲', 'pine'),
        FaceGlyph('🌳', 'oak'), FaceGlyph('🍂', 'leaf'),
        FaceGlyph('🌰', 'acorn'), FaceGlyph('🪵', 'log'),
        FaceGlyph('🌸', 'forest blossom'), FaceGlyph('🌼', 'meadow daisy'),
        FaceGlyph('🪷', 'pond lotus'), FaceGlyph('🌷', 'wild tulip'),
        FaceGlyph('🌱', 'spring shoot'), FaceGlyph('☀️', 'summer light'),
        FaceGlyph('🍁', 'autumn maple'), FaceGlyph('❄️', 'winter snow'),
      ],
    ),
    FaceStyleDef(
      id: 'sky',
      name: 'Open Sky',
      blurb: 'Sun, moon and wandering clouds.',
      proOnly: true,
      faces: [
        FaceGlyph('☀️', 'sun'), FaceGlyph('🌤️', 'sun behind cloud'),
        FaceGlyph('⛅', 'partly cloudy'), FaceGlyph('🌥️', 'cloudy sun'),
        FaceGlyph('☁️', 'cloud'), FaceGlyph('🌦️', 'sun shower'),
        FaceGlyph('🌧️', 'rain'), FaceGlyph('⛈️', 'storm'),
        FaceGlyph('🌩️', 'lightning'), FaceGlyph('❄️', 'snowflake'),
        FaceGlyph('☃️', 'snowman'), FaceGlyph('🌈', 'rainbow'),
        FaceGlyph('🌙', 'crescent moon'), FaceGlyph('🌕', 'full moon'),
        FaceGlyph('⭐', 'star'), FaceGlyph('🌟', 'bright star'),
        FaceGlyph('✨', 'sparkles'), FaceGlyph('💫', 'dizzy star'),
        FaceGlyph('☄️', 'comet'), FaceGlyph('🪐', 'ringed planet'),
        FaceGlyph('🌍', 'earth'), FaceGlyph('🌎', 'americas'),
        FaceGlyph('🕊️', 'dove'), FaceGlyph('🦅', 'eagle'),
        FaceGlyph('🦢', 'swan'), FaceGlyph('🦩', 'flamingo'),
        FaceGlyph('🪁', 'kite'), FaceGlyph('🎈', 'balloon'),
        FaceGlyph('🌸', 'spring blossom'), FaceGlyph('🌼', 'summer daisy'),
        FaceGlyph('🪷', 'autumn lotus'), FaceGlyph('🌷', 'winter tulip'),
        FaceGlyph('🌱', 'spring sprout'), FaceGlyph('🌤️', 'summer sky'),
        FaceGlyph('🍁', 'autumn leaf'), FaceGlyph('⛄', 'winter snow'),
      ],
    ),
    FaceStyleDef(
      id: 'fruits',
      name: 'Orchard',
      blurb: 'Sweet harvest in every tile.',
      proOnly: true,
      faces: [
        FaceGlyph('🍎', 'apple'), FaceGlyph('🍐', 'pear'),
        FaceGlyph('🍊', 'tangerine'), FaceGlyph('🍋', 'lemon'),
        FaceGlyph('🍌', 'banana'), FaceGlyph('🍉', 'watermelon'),
        FaceGlyph('🍇', 'grapes'), FaceGlyph('🍓', 'strawberry'),
        FaceGlyph('🫐', 'blueberries'), FaceGlyph('🍈', 'melon'),
        FaceGlyph('🍒', 'cherries'), FaceGlyph('🍑', 'peach'),
        FaceGlyph('🥭', 'mango'), FaceGlyph('🍍', 'pineapple'),
        FaceGlyph('🥥', 'coconut'), FaceGlyph('🥝', 'kiwi'),
        FaceGlyph('🍅', 'tomato'), FaceGlyph('🫒', 'olive'),
        FaceGlyph('🌰', 'chestnut'), FaceGlyph('🥜', 'peanut'),
        FaceGlyph('🍯', 'honey pot'), FaceGlyph('🧁', 'cupcake'),
        FaceGlyph('🍰', 'cake'), FaceGlyph('🍪', 'cookie'),
        FaceGlyph('🍩', 'doughnut'), FaceGlyph('🍮', 'custard'),
        FaceGlyph('🧋', 'bubble tea'), FaceGlyph('🍵', 'tea'),
        FaceGlyph('🌸', 'plum blossom'), FaceGlyph('🌼', 'chamomile'),
        FaceGlyph('🪷', 'lotus tea'), FaceGlyph('🌷', 'tulip tea'),
        FaceGlyph('🌱', 'spring sprout'), FaceGlyph('☀️', 'summer sun'),
        FaceGlyph('🍁', 'autumn leaf'), FaceGlyph('❄️', 'winter snow'),
      ],
    ),
    FaceStyleDef(
      id: 'kanji',
      name: 'Ink Garden',
      blurb: 'Nature written in sumi ink.',
      proOnly: true,
      faces: [
        FaceGlyph('山', 'mountain'), FaceGlyph('川', 'river'),
        FaceGlyph('海', 'sea'), FaceGlyph('空', 'sky'),
        FaceGlyph('風', 'wind'), FaceGlyph('雨', 'rain'),
        FaceGlyph('雪', 'snow'), FaceGlyph('花', 'flower'),
        FaceGlyph('鳥', 'bird'), FaceGlyph('魚', 'fish'),
        FaceGlyph('月', 'moon'), FaceGlyph('日', 'sun'),
        FaceGlyph('星', 'star'), FaceGlyph('雲', 'cloud'),
        FaceGlyph('霧', 'mist'), FaceGlyph('露', 'dew'),
        FaceGlyph('霜', 'frost'), FaceGlyph('霞', 'haze'),
        FaceGlyph('虹', 'rainbow'), FaceGlyph('雷', 'thunder'),
        FaceGlyph('嵐', 'storm'), FaceGlyph('渚', 'shore'),
        FaceGlyph('渓', 'ravine'), FaceGlyph('峯', 'peak'),
        FaceGlyph('谷', 'valley'), FaceGlyph('林', 'grove'),
        FaceGlyph('森', 'forest'), FaceGlyph('竹', 'bamboo'),
        FaceGlyph('梅', 'plum'), FaceGlyph('桜', 'cherry'),
        FaceGlyph('松', 'pine'), FaceGlyph('楓', 'maple'),
        FaceGlyph('春', 'spring'), FaceGlyph('夏', 'summer'),
        FaceGlyph('秋', 'autumn'), FaceGlyph('冬', 'winter'),
      ],
    ),
    FaceStyleDef(
      id: 'stones',
      name: 'River Stones',
      blurb: 'Carved marks on smooth pebbles.',
      proOnly: true,
      faces: [
        FaceGlyph('●', 'full stone'), FaceGlyph('◐', 'half stone'),
        FaceGlyph('○', 'ring stone'), FaceGlyph('◎', 'double ring'),
        FaceGlyph('⬤', 'dark stone'), FaceGlyph('◯', 'light stone'),
        FaceGlyph('⬥', 'diamond'), FaceGlyph('⬧', 'small diamond'),
        FaceGlyph('▲', 'triangle'), FaceGlyph('△', 'hollow triangle'),
        FaceGlyph('■', 'square'), FaceGlyph('□', 'hollow square'),
        FaceGlyph('⬢', 'hexagon'), FaceGlyph('⬣', 'tall hexagon'),
        FaceGlyph('✦', 'spark'), FaceGlyph('✧', 'faint spark'),
        FaceGlyph('☾', 'moon'), FaceGlyph('☀', 'sun'),
        FaceGlyph('♒', 'waves'), FaceGlyph('≋', 'ripples'),
        FaceGlyph('〰', 'flow'), FaceGlyph('〜', 'stream'),
        FaceGlyph('❖', 'knot'), FaceGlyph('✜', 'cross'),
        FaceGlyph('✚', 'plus'), FaceGlyph('✖', 'crossed'),
        FaceGlyph('➰', 'loop'), FaceGlyph('➿', 'double loop'),
        FaceGlyph('🌸', 'spring blossom'), FaceGlyph('🌼', 'summer daisy'),
        FaceGlyph('🪷', 'autumn lotus'), FaceGlyph('🌷', 'winter tulip'),
        FaceGlyph('🌱', 'spring sprout'), FaceGlyph('☀️', 'summer sun'),
        FaceGlyph('🍁', 'autumn leaf'), FaceGlyph('❄️', 'winter snow'),
      ],
    ),
  ];

  /// Public catalog. In debug builds, verifies the RULES.md invariant that
  /// every style defines exactly 36 faces (ids 0-27 standard, 28-35 honor).
  static List<FaceStyleDef> get all {
    assert(() {
      for (final s in _all) {
        assert(s.faces.length == 36,
            'Face style ${s.id} defines ${s.faces.length} faces, want 36');
      }
      return true;
    }());
    return _all;
  }
}

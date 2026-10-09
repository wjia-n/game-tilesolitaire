// Zen garden UI kit for Tile Solitaire.
// Palette, typography and tactile widgets per DESIGN.md:
// bamboo tiles, raked sand, cedar plaques, moss pebble buttons,
// go-stone toggles, carved sand-groove sliders, ivory tally chips.
import 'dart:math';

import 'package:flutter/material.dart';

class Zen {
  static const sand = Color(0xFFE8DCC3);
  static const sandGroove = Color(0xFFD2C2A3);
  static const bambooIvory = Color(0xFFF5EFDD);
  static const paperWhite = Color(0xFFFAF7F0);
  static const sumiInk = Color(0xFF2B2620);
  static const moss = Color(0xFF6B7F5E);
  static const deepMoss = Color(0xFF4E6143);
  static const cedar = Color(0xFF8C6D46);
  static const darkCedar = Color(0xFF5A432A);
  static const riverStone = Color(0xFF8A8D8F);
  static const riverStoneDark = Color(0xFF6E7173);

  /// Engraved-plaque heading: heavy, letterspaced, carved shadow.
  static TextStyle heading(double size) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: sumiInk,
        shadows: const [
          Shadow(offset: Offset(0, 1.5), color: paperWhite),
          Shadow(offset: Offset(0, -1), color: Color(0x595A432A)),
        ],
      );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: sumiInk,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: Color(0xFF8A7A5C),
  );

  static String clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Full-screen raked-sand background with soft top-left daylight.
class RakedSand extends StatelessWidget {
  const RakedSand({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Zen.sand,
      child: CustomPaint(
        painter: _RakePainter(),
        child: child,
      ),
    );
  }
}

class _RakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gentle daylight wash from the top-left (subtle material shading).
    final wash = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      wash,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.9),
          radius: 1.4,
          colors: [
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(wash),
    );
    // Raked wave lines.
    final linePaint = Paint()
      ..color = Zen.sandGroove.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final hiPaint = Paint()
      ..color = Zen.paperWhite.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    var row = 0;
    for (var y = 26.0; y < size.height + 20; y += 36) {
      final path = Path();
      for (var x = -20.0; x <= size.width + 20; x += 8) {
        final yy = y + sin(x / 90 + row * 1.7) * 7 + sin(x / 31 + row) * 2.5;
        if (x == -20) {
          path.moveTo(x, yy);
        } else {
          path.lineTo(x, yy);
        }
      }
      canvas.drawPath(path, linePaint);
      canvas.drawPath(path.shift(const Offset(0, 2.2)), hiPaint);
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A pseudo-3D bamboo tile: cedar base, ivory face, engraved sumi glyph,
/// specular top line and a soft contact shadow.
class BambooTile extends StatelessWidget {
  const BambooTile({
    super.key,
    required this.glyph,
    required this.size,
    this.selected = false,
    this.hinted = false,
    this.covered = false,
    this.dimmed = false,
    this.lift = 0,
    this.semanticsLabel,
  });

  final String glyph;
  final double size; // width; height = size * 1.3
  final bool selected;
  final bool hinted;
  final bool covered;
  final bool dimmed;
  final double lift;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? 'tile',
      child: CustomPaint(
        size: Size(size, size * 1.3),
        painter: _BambooTilePainter(
          glyph: glyph,
          selected: selected,
          hinted: hinted,
          covered: covered,
          dimmed: dimmed,
          lift: lift,
        ),
      ),
    );
  }
}

class _BambooTilePainter extends CustomPainter {
  _BambooTilePainter({
    required this.glyph,
    required this.selected,
    required this.hinted,
    required this.covered,
    required this.dimmed,
    required this.lift,
  });

  final String glyph;
  final bool selected;
  final bool hinted;
  final bool covered;
  final bool dimmed;
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.16;
    final body = RRect.fromLTRBR(0, 0, w, h, Radius.circular(r));

    // Contact / floating shadow (grows when lifted).
    canvas.drawShadow(
      Path()..addRRect(body.shift(Offset(0, lift))),
      Zen.sumiInk.withValues(alpha: selected ? 0.45 : 0.35),
      4 + lift * 1.6,
      true,
    );

    canvas.save();
    canvas.translate(0, -lift);

    // Cedar base: bottom stratum of the tile.
    final base = RRect.fromLTRBR(0, h * 0.60, w, h, Radius.circular(r));
    canvas.drawRRect(base, Paint()..color = Zen.cedar);
    canvas.drawRRect(
      RRect.fromLTRBR(3, h * 0.60 + 3, w - 3, h - 3, Radius.circular(r * 0.7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Zen.darkCedar.withValues(alpha: 0.6),
    );
    // Dark foot line for weight.
    canvas.drawRRect(
      RRect.fromLTRBR(2, h - 5, w - 2, h - 1, Radius.circular(r * 0.5)),
      Paint()..color = Zen.darkCedar.withValues(alpha: 0.55),
    );

    // Bamboo ivory face: top stratum with subtle material shading.
    final face = RRect.fromLTRBR(0, 0, w, h * 0.84, Radius.circular(r));
    final facePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: selected
            ? [Zen.paperWhite, const Color(0xFFEFE3C8)]
            : [Zen.paperWhite, Zen.bambooIvory],
      ).createShader(Rect.fromLTRB(0, 0, w, h * 0.84));
    canvas.drawRRect(face, facePaint);
    // Top specular line.
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.10, 3, w * 0.90, 6.5, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    // Hairline edge.
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Zen.sandGroove,
    );

    // Engraved sumi-ink glyph: a dark under-cut first (the carve shadow),
    // then the ink face on top.
    TextStyle glyphStyle(Color color) => TextStyle(
          fontSize: w * (glyph.runes.length > 1 ? 0.40 : 0.52),
          height: 1.0,
          color: color,
        );
    final tp = TextPainter(
      text: TextSpan(text: glyph, style: glyphStyle(Zen.sumiInk)),
      textDirection: TextDirection.ltr,
    )..layout();
    final gx = (w - tp.width) / 2;
    final gy = (h * 0.84 - tp.height) / 2 - h * 0.02;
    tp.text = TextSpan(
        text: glyph, style: glyphStyle(Zen.darkCedar.withValues(alpha: 0.85)));
    tp.layout();
    tp.paint(canvas, Offset(gx, gy + 1.6));
    tp.text = TextSpan(text: glyph, style: glyphStyle(Zen.sumiInk));
    tp.layout();
    tp.paint(canvas, Offset(gx, gy));

    // Selection / hint rims (carved moss, no glow).
    if (selected) {
      canvas.drawRRect(
        RRect.fromLTRBR(1.5, 1.5, w - 1.5, h - 1.5, Radius.circular(r)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Zen.deepMoss,
      );
    } else if (hinted) {
      canvas.drawRRect(
        RRect.fromLTRBR(1.5, 1.5, w - 1.5, h - 1.5, Radius.circular(r)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Zen.moss,
      );
    }

    // Covered tiles get the warm dusk tint; non-free tiles rest dimmed.
    if (covered) {
      canvas.drawRRect(
          body, Paint()..color = const Color(0x2E5A432A));
    }
    if (dimmed) {
      canvas.drawRRect(
          body, Paint()..color = Zen.sand.withValues(alpha: 0.42));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BambooTilePainter old) =>
      old.glyph != glyph ||
      old.selected != selected ||
      old.hinted != hinted ||
      old.covered != covered ||
      old.dimmed != dimmed ||
      old.lift != lift;
}

enum PebbleKind { primary, secondary, wood }

/// A tactile pebble button: carved inner rim, sinks 1.5 px when pressed.
class PebbleButton extends StatefulWidget {
  const PebbleButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.kind = PebbleKind.primary,
    this.enabled = true,
    this.badge,
    this.big = false,
    this.semanticsLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final PebbleKind kind;
  final bool enabled;
  final String? badge;
  final bool big;
  final String? semanticsLabel;

  @override
  State<PebbleButton> createState() => _PebbleButtonState();
}

class _PebbleButtonState extends State<PebbleButton> {
  bool _pressed = false;

  Color get _base {
    if (!widget.enabled) return Zen.riverStone.withValues(alpha: 0.55);
    return switch (widget.kind) {
      PebbleKind.primary => Zen.moss,
      PebbleKind.secondary => Zen.riverStone,
      PebbleKind.wood => Zen.cedar,
    };
  }

  Color get _rim {
    if (!widget.enabled) return Zen.riverStoneDark.withValues(alpha: 0.5);
    return switch (widget.kind) {
      PebbleKind.primary => Zen.deepMoss,
      PebbleKind.secondary => Zen.riverStoneDark,
      PebbleKind.wood => Zen.darkCedar,
    };
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.kind == PebbleKind.wood || !widget.enabled
        ? Zen.paperWhite.withValues(alpha: widget.enabled ? 1 : 0.8)
        : Zen.paperWhite;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, _pressed ? 1.5 : 0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.big ? 34 : 18,
            vertical: widget.big ? 15 : 10,
          ),
          decoration: BoxDecoration(
            color: _base,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _rim, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Zen.sumiInk.withValues(alpha: _pressed ? 0.18 : 0.32),
                blurRadius: _pressed ? 3 : 7,
                offset: Offset(0, _pressed ? 1.5 : 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 2,
                offset: const Offset(0, -1.5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: widget.big ? 22 : 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.big ? 18 : 14,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              if (widget.badge != null)
                Positioned(
                  right: -14,
                  top: -16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Zen.sumiInk,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: Zen.paperWhite, width: 1.5),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: Zen.paperWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
}

/// Go-stone toggle: ON = obsidian sumi stone with a moss dot,
/// OFF = sunken carved ring in the sand.
class GoStoneToggle extends StatelessWidget {
  const GoStoneToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          height: 36,
          decoration: BoxDecoration(
            color: value ? Zen.sumiInk : Zen.sand,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value ? Zen.darkCedar : Zen.sandGroove,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Zen.sumiInk.withValues(alpha: value ? 0.4 : 0.18),
                blurRadius: value ? 6 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? Zen.sumiInk : Zen.paperWhite,
                    border: Border.all(
                      color: value ? Zen.moss : Zen.sandGroove,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: value ? 0.25 : 0.9),
                        blurRadius: 2,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                  child: value
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Zen.moss,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shallow carved groove in the sand with a smooth river-stone knob.
class SandGrooveSlider extends StatelessWidget {
  const SandGrooveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticsLabel,
  });
  final double value; // 0..1
  final ValueChanged<double> onChanged;
  final String? semanticsLabel;

  void _setFromX(double x, double width) {
    onChanged((x / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: semanticsLabel,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) =>
                _setFromX(d.localPosition.dx, w),
            onTapDown: (d) => _setFromX(d.localPosition.dx, w),
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Zen.sandGroove,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: Zen.darkCedar.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Zen.darkCedar.withValues(alpha: 0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 6 + (w - 12 - 26) * value,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Zen.riverStone,
                        border: Border.all(
                            color: Zen.riverStoneDark, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Zen.sumiInk.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Carved ivory tally pill: small-caps label over a bold value.
class TallyChip extends StatelessWidget {
  const TallyChip({
    super.key,
    required this.label,
    required this.value,
    this.semanticsLabel,
  });
  final String label;
  final String value;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? '$label $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Zen.bambooIvory,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Zen.sandGroove, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Zen.sumiInk.withValues(alpha: 0.16),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Zen.chipLabel),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Zen.sumiInk,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cedar-framed ema plaque with a rice-paper inner face.
class CedarPlaque extends StatelessWidget {
  const CedarPlaque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Zen.cedar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Zen.darkCedar, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Zen.sumiInk.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Zen.paperWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Zen.sandGroove.withValues(alpha: 0.8)),
        ),
        child: child,
      ),
    );
  }
}

/// Gentle top-of-screen banner (fade-and-settle, no bounce).
class ToastBanner extends StatelessWidget {
  const ToastBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Zen.sumiInk.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Zen.cedar, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Zen.sumiInk.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Zen.paperWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny footprint preview of a layout for the menu cards.
class LayoutPreview extends StatelessWidget {
  const LayoutPreview({
    super.key,
    required this.cells,
    required this.maxX,
    required this.maxY,
  });
  final List<List<int>> cells; // [x, y, z]
  final int maxX;
  final int maxY;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LayoutPreviewPainter(cells, maxX, maxY),
      size: const Size(120, 84),
    );
  }
}

class _LayoutPreviewPainter extends CustomPainter {
  _LayoutPreviewPainter(this.cells, this.maxX, this.maxY);
  final List<List<int>> cells;
  final int maxX;
  final int maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / (maxX + 1);
    final ch = size.height / (maxY + 1);
    final ordered = [...cells]..sort((a, b) => a[2].compareTo(b[2]));
    for (final c in ordered) {
      final r = RRect.fromLTRBR(
        c[0] * cw + 1,
        c[1] * ch + 1 - c[2] * 2,
        (c[0] + 1) * cw - 1,
        (c[1] + 1) * ch - 1 - c[2] * 2,
        Radius.circular(2),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color =
              Zen.cedar.withValues(alpha: 0.35 + c[2] * 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stacked river stones (stone cairn) for the cleared-garden motif.
class Cairn extends StatelessWidget {
  const Cairn({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _CairnPainter());
  }
}

class _CairnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final stones = [
      (0.34, 0.30, const Color(0xFF9A9DA0)), // top
      (0.46, 0.34, const Color(0xFF8A8D8F)), // mid
      (0.60, 0.36, const Color(0xFF7B7E81)), // base
    ];
    var y = size.height * 0.92;
    for (final s in stones) {
      final w = size.width * s.$1;
      final h = size.height * s.$2;
      y -= h * 0.82;
      final rect = Rect.fromCenter(
          center: Offset(cx, y + h / 2), width: w, height: h);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 3, y + h + 2), width: w * 0.9, height: 10),
        Paint()..color = Zen.sumiInk.withValues(alpha: 0.22),
      );
      canvas.drawOval(rect, Paint()..color = s.$3);
      canvas.drawOval(
        Rect.fromLTWH(rect.left + w * 0.16, rect.top + h * 0.12, w * 0.3, h * 0.28),
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
    // A sprig of moss on top.
    final mossPaint = Paint()..color = Zen.moss;
    canvas.drawCircle(Offset(cx - 6, size.height * 0.10), 5, mossPaint);
    canvas.drawCircle(Offset(cx + 4, size.height * 0.085), 6, mossPaint);
    canvas.drawCircle(Offset(cx + 12, size.height * 0.11), 4, mossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tile Solitaire PRO: Free-vs-Pro comparison, real purchase, restore,
// and tip jar. All prices come from the store — never hardcoded.
// Until Wajiha creates the products in Play Console, the screen shows an
// honest "available after store setup" state.
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../game/audio_service.dart';
import '../game/prefs.dart';
import '../services/iap_service.dart';
import '../ui/zen.dart';

class ProScreen extends StatefulWidget {
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.prefs,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.prefs.pro = true;
      widget.prefs.savePro();
      widget.audio.playSfx('win');
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PRO unlocked — the whole garden is yours!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.playSfx('win');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      body: RakedSand(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
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
                        widget.audio.playSfx('tap');
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text('Tile Solitaire PRO',
                          style: Zen.heading(22),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 90),
                  ],
                ),
                const SizedBox(height: 16),
                _ComparisonCard(isPro: widget.prefs.pro),
                const SizedBox(height: 16),
                _BuyCard(
                  audio: widget.audio,
                  prefs: widget.prefs,
                  store: store,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _TipsCard(
                  audio: widget.audio,
                  store: store,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final bool isPro;
  const _ComparisonCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete tile-solitaire game', true, true),
      ('All official rules', true, true),
      ('9 layouts + daily garden', true, true),
      ('3 difficulties', true, true),
      ('Undo, pause, resume', true, true),
      ('Music & sound effects', true, true),
      ('Hints & shuffles per game', '3 + 3', '5 + 5'),
      ('Garden themes', '4', '12+'),
      ('Tile-face styles', '3', '9'),
      ('Custom garden creator', false, true),
      ('Exclusive tray accents', false, true),
      ('PRO medallion on the menu', false, true),
    ];
    return CedarPlaque(
      child: Column(
        children: [
          Text('Free vs PRO', style: Zen.heading(20)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: Zen.body,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Zen.chipLabel, textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Zen.chipLabel, textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1, style: Zen.body.copyWith(fontSize: 13)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2)),
                  Expanded(flex: 2, child: _Cell(value: r.$3)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Zen.deepMoss.withValues(alpha: 0.15),
                  border: Border.all(color: Zen.deepMoss, width: 1.5),
                ),
                child: Text(
                  'PRO is active on this device',
                  style: TextStyle(
                      color: Zen.deepMoss,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  const _Cell({required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final on = value as bool;
      return Icon(
        on ? Icons.check_circle : Icons.remove_circle_outline,
        color: on ? Zen.deepMoss : Zen.sandGroove,
        size: 20,
      );
    }
    return Text(
      value as String,
      style: TextStyle(
          fontWeight: FontWeight.w800, color: Zen.sumiInk, fontSize: 13),
      textAlign: TextAlign.center,
    );
  }
}

class _BuyCard extends StatelessWidget {
  final AudioService audio;
  final GamePrefs prefs;
  final StoreService store;
  final VoidCallback onChanged;

  const _BuyCard({
    required this.audio,
    required this.prefs,
    required this.store,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final product = store.proProduct;
    return CedarPlaque(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Unlock PRO', style: Zen.heading(18)),
          const SizedBox(height: 6),
          Text(
            'Every theme, every tile-face style, the custom garden '
            'creator, and a fuller toolkit in every game.',
            style: Zen.body,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Zen.sand,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Zen.sandGroove),
              ),
              child: Text(
                store.error ?? 'Available after store setup',
                style: Zen.body.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else if (prefs.pro)
            Center(
              child: PebbleButton(
                label: 'Restore purchase',
                icon: Icons.restore,
                kind: PebbleKind.secondary,
                onTap: () {
                  audio.playSfx('tap');
                  store.restore();
                },
              ),
            )
          else
            Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: store.purchaseInProgress,
                builder: (context, busy, _) => PebbleButton(
                  label: busy
                      ? 'Working…'
                      : 'Buy PRO — ${product?.price ?? ''}',
                  icon: Icons.spa,
                  big: true,
                  enabled: !busy,
                  onTap: () {
                    audio.playSfx('tap');
                    store.buyPro();
                  },
                ),
              ),
            ),
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (context, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(err,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
          ),
          if (store.storeReady && !prefs.pro) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  audio.playSfx('tap');
                  store.restore();
                },
                child: const Text('Restore a previous purchase'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final AudioService audio;
  final StoreService store;
  const _TipsCard({required this.audio, required this.store});

  Widget _tipButton(
      BuildContext context, ProductDetails? product, String label, IconData icon) {
    return Expanded(
      child: PebbleButton(
        label: product == null ? label : '$label — ${product.price}',
        icon: icon,
        kind: PebbleKind.wood,
        enabled: product != null,
        onTap: product == null
            ? null
            : () {
                audio.playSfx('tap');
                store.buyTip(product);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CedarPlaque(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tip jar', style: Zen.heading(18)),
          const SizedBox(height: 6),
          Text(
            'Tile Solitaire is made by one indie gardener. '
            'A small tip keeps the sand raked.',
            style: Zen.body,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup',
              style: Zen.body.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            )
          else
            Row(
              children: [
                _tipButton(context, store.coffeeProduct, 'Coffee',
                    Icons.coffee),
                const SizedBox(width: 10),
                _tipButton(context, store.chocolateProduct, 'Chocolate',
                    Icons.cake),
              ],
            ),
        ],
      ),
    );
  }
}

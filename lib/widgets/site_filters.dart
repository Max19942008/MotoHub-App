import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../theme.dart';
import '../utils/labels.dart';

/// Website-style controls of the list header card: a full-width sort button
/// and a wrap of filter buttons, each opening a small dropdown menu.

const _border = Color(0xFFE0E0E0);
const _text = Color(0xFF181A20);

ButtonStyle _outlined({double height = 40}) => OutlinedButton.styleFrom(
      foregroundColor: _text,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _border),
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(
          fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w500),
    );

/// Anchor a menu under [context]'s widget.
Future<T?> _menu<T>(BuildContext context, List<PopupMenuEntry<T>> items) {
  final box = context.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final rect = Rect.fromPoints(
    box.localToGlobal(Offset(0, box.size.height + 6), ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
    constraints:
        const BoxConstraints(minWidth: 200, maxWidth: 240, maxHeight: 360),
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE5E5E5))),
    items: items,
  );
}

PopupMenuItem<T> _item<T>(T value, String label, {bool selected = false}) =>
    PopupMenuItem<T>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Brand.green : _text)),
          ),
          if (selected) const Icon(Icons.check, size: 18, color: Brand.green),
        ],
      ),
    );

PopupMenuEntry<T> _heading<T>(String text) => PopupMenuItem<T>(
      enabled: false,
      height: 34,
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280))),
    );

/// Full-width "Yangi ⌄" sort button.
class SortButton extends StatelessWidget {
  const SortButton({super.key, required this.sort, required this.onChanged});
  final SortOption? sort;
  final ValueChanged<SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: _outlined(height: 36),
          onPressed: () async {
            final picked = await _menu<SortOption>(context, [
              for (final o in SortOption.values)
                _item(o, o.label, selected: o == sort),
            ]);
            if (picked != null) onChanged(picked);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(sort?.label ?? 'Yangi',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 10),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Brend ⌄" — toggles one value per tap, like the site's menus.
class MultiFilterButton extends StatelessWidget {
  const MultiFilterButton({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final count = selected.length;
    return Builder(
      builder: (context) => OutlinedButton(
        style: _outlined().copyWith(
          side: WidgetStatePropertyAll(
              BorderSide(color: count > 0 ? Brand.green : _border)),
        ),
        onPressed: () async {
          final picked = await _menu<String>(context, [
            for (final o in options)
              _item(o, labelOf(o), selected: selected.contains(o)),
          ]);
          if (picked != null) onToggle(picked);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count > 0 ? '$label ($count)' : label),
            const SizedBox(width: 18),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Translates enum values the same way the cards do.
String labelOf(String value) => label(value);

/// "2000 - 2026 ⌄" / "$0 - $2,000,000 ⌄" — two lists (from / to) in one menu.
class RangeFilterButton extends StatelessWidget {
  const RangeFilterButton({
    super.key,
    required this.text,
    required this.fromTitle,
    required this.toTitle,
    required this.fromOptions,
    required this.toOptions,
    required this.format,
    this.from,
    this.to,
    required this.onChanged,
  });

  final String text;
  final String fromTitle;
  final String toTitle;
  final List<int> fromOptions;
  final List<int> toOptions;
  final String Function(int) format;
  final int? from;
  final int? to;
  final void Function(int? from, int? to) onChanged;

  @override
  Widget build(BuildContext context) {
    final active = from != null || to != null;
    return Builder(
      builder: (context) => OutlinedButton(
        style: _outlined().copyWith(
          side: WidgetStatePropertyAll(
              BorderSide(color: active ? Brand.green : _border)),
        ),
        onPressed: () async {
          final picked = await _menu<(bool, int)>(context, [
            _heading(fromTitle),
            for (final v in fromOptions)
              _item((true, v), format(v), selected: v == from),
            const PopupMenuDivider(),
            _heading(toTitle),
            for (final v in toOptions)
              _item((false, v), format(v), selected: v == to),
          ]);
          if (picked == null) return;
          var (isFrom, v) = picked;
          var f = from, t = to;
          if (isFrom) {
            f = v;
            if (t != null && t < v) t = v;
          } else {
            t = v;
            if (f != null && f > v) f = v;
          }
          onChanged(f, t);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 18),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// "↻ Tozalash"
class ResetFilterButton extends StatelessWidget {
  const ResetFilterButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: _outlined(),
        onPressed: onPressed,
        icon: const Icon(Icons.refresh_rounded, size: 19),
        label: const Text('Tozalash'),
      );
}

/// Price options of the site's price menu.
const minPriceOptions = [
  0,
  500,
  1000,
  2000,
  5000,
  10000,
  20000,
  50000,
  100000,
  200000
];
const maxPriceOptions = [
  500,
  1000,
  2000,
  5000,
  10000,
  20000,
  50000,
  100000,
  200000,
  500000
];
String usd(int v) => formatPrice(v, 'USD');

/// Years in the site's year menu (newest first).
List<int> yearOptions() =>
    [for (var y = DateTime.now().year; y >= 2000; y--) y];

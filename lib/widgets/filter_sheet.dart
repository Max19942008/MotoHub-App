import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../utils/labels.dart';

class FilterSection {
  FilterSection(this.title, this.options, Set<String> selected) : selected = {...selected};

  final String title;
  final List<String> options;
  final Set<String> selected;
}

class FilterResult {
  FilterResult({required this.sections, required this.sort, this.minPrice, this.maxPrice});

  /// Same order as the sections passed in.
  final List<Set<String>> sections;
  final SortOption sort;
  final int? minPrice;
  final int? maxPrice;
}

/// Bottom sheet with sort + multi-select chip sections (+ optional price range).
Future<FilterResult?> showFilterSheet(
  BuildContext context, {
  required List<FilterSection> sections,
  required SortOption sort,
  bool withPrice = false,
  int? minPrice,
  int? maxPrice,
}) {
  return showModalBottomSheet<FilterResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(
      sections: sections,
      sort: sort,
      withPrice: withPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.sections,
    required this.sort,
    required this.withPrice,
    this.minPrice,
    this.maxPrice,
  });

  final List<FilterSection> sections;
  final SortOption sort;
  final bool withPrice;
  final int? minPrice;
  final int? maxPrice;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SortOption _sort = widget.sort;
  late final _min = TextEditingController(text: widget.minPrice?.toString() ?? '');
  late final _max = TextEditingController(text: widget.maxPrice?.toString() ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      for (final s in widget.sections) {
        s.selected.clear();
      }
      _sort = SortOption.newest;
      _min.clear();
      _max.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      FilterResult(
        sections: [for (final s in widget.sections) s.selected],
        sort: _sort,
        minPrice: int.tryParse(_min.text.replaceAll(' ', '')),
        maxPrice: int.tryParse(_max.text.replaceAll(' ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Filtrlar', style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: _reset, child: const Text('Tozalash')),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                heading('Saralash'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in SortOption.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: _sort == option,
                        onSelected: (_) => setState(() => _sort = option),
                      ),
                  ],
                ),
                if (widget.withPrice) ...[
                  heading('Narx (\$)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _min,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'dan', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _max,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'gacha', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
                for (final section in widget.sections) ...[
                  heading(section.title),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in section.options)
                        FilterChip(
                          label: Text(label(option)),
                          selected: section.selected.contains(option),
                          onSelected: (on) => setState(() {
                            on ? section.selected.add(option) : section.selected.remove(option);
                          }),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _apply, child: const Text('Natijalarni ko\'rsatish')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

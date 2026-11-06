import 'dart:async';

import 'package:flutter/material.dart';

/// Search field + filter button with an active-filter badge.
/// Search fires 500 ms after the user stops typing.
class SearchBarRow extends StatefulWidget {
  const SearchBarRow({
    super.key,
    required this.hint,
    required this.initialText,
    required this.activeFilters,
    required this.onSearch,
    required this.onFilter,
  });

  final String hint;
  final String initialText;
  final int activeFilters;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;

  @override
  State<SearchBarRow> createState() => _SearchBarRowState();
}

class _SearchBarRowState extends State<SearchBarRow> {
  late final _controller = TextEditingController(text: widget.initialText);
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => widget.onSearch(value));
    setState(() {}); // toggle the clear button
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: _controller,
              hintText: widget.hint,
              elevation: const WidgetStatePropertyAll(0),
              leading: const Icon(Icons.search),
              onChanged: _changed,
              onSubmitted: (v) {
                _debounce?.cancel();
                widget.onSearch(v);
              },
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _changed('');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: widget.activeFilters > 0,
            label: Text('${widget.activeFilters}'),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.tune),
              tooltip: 'Filtrlar',
              onPressed: widget.onFilter,
            ),
          ),
        ],
      ),
    );
  }
}

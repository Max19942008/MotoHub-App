import 'package:flutter/material.dart';

import '../api/graphql_client.dart';
import '../models/listing.dart';
import 'common.dart';

typedef PageFetcher<T> = Future<PageResult<T>> Function(int page);

/// Two-column grid with infinite scroll and pull-to-refresh.
/// Give it a new [key] when the filter changes to start over from page 1.
class PagedGrid<T> extends StatefulWidget {
  const PagedGrid({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.header,
    this.emptyMessage = 'Hech narsa topilmadi',
  });

  final PageFetcher<T> fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? header;
  final String emptyMessage;

  @override
  State<PagedGrid<T>> createState() => _PagedGridState<T>();
}

class _PagedGridState<T> extends State<PagedGrid<T>> {
  final _items = <T>[];
  final _scroll = ScrollController();
  int _page = 0;
  int _total = 0;
  bool _loading = false;
  String? _error;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || (_page > 0 && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final next = await widget.fetch(_page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _total = next.total;
        _items.addAll(next.items);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _total = 0;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_items.isEmpty && _loading) {
      body = const SliverFillRemaining(hasScrollBody: false, child: LoadingView());
    } else if (_items.isEmpty && _error != null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: MessageView(icon: Icons.cloud_off, message: _error!, onRetry: _refresh),
      );
    } else if (_items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: MessageView(icon: Icons.search_off, message: widget.emptyMessage),
      );
    } else {
      body = SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.66,
          ),
          itemCount: _items.length,
          itemBuilder: (context, i) => widget.itemBuilder(context, _items[i]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          body,
          if (_items.isNotEmpty && (_loading || _error != null))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : TextButton(onPressed: _loadMore, child: const Text('Yana yuklash')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../api/graphql_client.dart';
import '../models/listing.dart';
import '../theme.dart';
import 'common.dart';

typedef PageFetcher<T> = Future<PageResult<T>> Function(int page);

/// Website-style list: a white header card (title, "N mavjud", search) on top,
/// then one big card per row, with infinite scroll and pull-to-refresh.
/// Give it a new [key] when the filter changes to start over from page 1.
class PagedGrid<T> extends StatefulWidget {
  const PagedGrid({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.header,
    this.title,
    this.emptyMessage = 'Hech narsa topilmadi',
  });

  final PageFetcher<T> fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? header;

  /// Big page title in the header card, e.g. "Mototsikllar".
  final String? title;
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        sliver: SliverList.separated(
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: widget.itemBuilder(context, _items[i]),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.title != null)
            SliverToBoxAdapter(child: _HeaderCard(title: widget.title!, total: _total, child: widget.header))
          else if (widget.header != null)
            SliverToBoxAdapter(child: widget.header),
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
          // room for the floating AI button
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
    );
  }
}

/// White rounded card like the website's filter header: title, count, search.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.title, required this.total, this.child});
  final String title;
  final int total;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Brand.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
            const SizedBox(height: 2),
            Text('$total mavjud', style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted)),
            if (child != null) ...[
              const Padding(padding: EdgeInsets.only(top: 12), child: Divider(height: 1, color: Brand.line)),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

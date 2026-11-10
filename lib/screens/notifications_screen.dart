import 'package:flutter/material.dart' hide Text;

import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';
import '../i18n/text.dart';
import '../i18n/i18n.dart';

/// The site's /notifications page: list, "Mark all read", delete one.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = Repository.instance;
  List<AppNotification>? _items;
  int _unread = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (items, unread) = await _repo.notifications();
      if (mounted) {
        setState(() {
          _items = items;
          _unread = unread;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 36)),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            const Text('Bildirishnomalar',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Brand.ink)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _unread == 0
                    ? null
                    : () => _run(() => _repo.markNotificationsRead()),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text("Hammasini o'qilgan deb belgilash"),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              MessageView(
                  icon: Icons.cloud_off, message: _error!, onRetry: _load)
            else if (items == null)
              const SizedBox(height: 240, child: LoadingView())
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Column(children: [
                  Icon(Icons.notifications_none,
                      size: 56, color: Color(0xFF999999)),
                  SizedBox(height: 8),
                  Text("Bildirishnomalar yo'q",
                      style: TextStyle(color: Color(0xFF999999))),
                ]),
              )
            else
              for (final n in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                  decoration: BoxDecoration(
                    color: n.unread
                        ? Brand.green.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 6, children: [
                              _Chip(n.type, Brand.green, outlined: true),
                              if (n.unread)
                                const _Chip('Yangi', Colors.red,
                                    outlined: false),
                            ]),
                            const SizedBox(height: 6),
                            Text(n.title,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Brand.ink)),
                            if (n.description?.isNotEmpty == true) ...[
                              const SizedBox(height: 3),
                              Text(n.description!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF666666))),
                            ],
                            const SizedBox(height: 5),
                            Text(timeAgo(n.createdAt),
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFFAAAAAA))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: "O'chirish".tr,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () =>
                            _run(() => _repo.deleteNotification(n.id)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color, {required this.outlined});
  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: outlined ? null : color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: outlined ? color : Colors.white)),
      );
}

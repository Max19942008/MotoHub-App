import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../theme.dart';

/// The site's "Write an Article" form: category, title, text, Register.
/// Pops `true` once the article is published.
class WriteArticleScreen extends StatefulWidget {
  const WriteArticleScreen({super.key});

  @override
  State<WriteArticleScreen> createState() => _WriteArticleScreenState();
}

class _WriteArticleScreenState extends State<WriteArticleScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = 'FREE';
  bool _saving = false;

  static const _categories = [
    ('FREE', 'Free'),
    ('HUMOR', 'Humor'),
    ('NEWS', 'News'),
    ('RECOMMEND', 'Recommendation'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Same HTML the site's editor produces, so the post renders on the web too.
  static String _toHtml(String text) {
    const escape = HtmlEscape(HtmlEscapeMode.element);
    return text
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((p) =>
            '<p>${escape.convert(p.trim()).replaceAll('\n', '<br>')}</p>')
        .join();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    String? problem;
    if (title.length < 3 || title.length > 50) {
      problem = "Sarlavha 3–50 belgidan iborat bo'lishi kerak";
    } else if (body.length < 3) {
      problem = 'Maqola matnini yozing';
    } else if (_toHtml(body).length > 250) {
      problem = 'Matn juda uzun (taxminan 230 belgigacha)';
    }
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _saving = true);
    try {
      await Repository.instance.createArticle(_category, title, _toHtml(body));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maqola muvaffaqiyatli joylandi')));
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF7F838D));
    return Scaffold(
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 36)),
      backgroundColor: const Color(0xFFF7F8FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
        children: [
          const Text('Maqola yozish',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: Brand.ink)),
          const SizedBox(height: 4),
          const Text("G'oyalaringizni bemalol yozing!",
              style: TextStyle(fontSize: 14, color: Brand.muted)),
          const SizedBox(height: 26),
          const Text('Turkum', style: label),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final c in _categories)
                DropdownMenuItem(value: c.$1, child: Text(c.$2)),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'FREE'),
          ),
          const SizedBox(height: 18),
          const Text('Sarlavha', style: label),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Type Title'),
          ),
          const SizedBox(height: 8),
          const Text('Matn', style: label),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            minLines: 10,
            maxLines: 18,
            maxLength: 230,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Type here', alignLabelWithHint: true),
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: 250,
              height: 45,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Joylash'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

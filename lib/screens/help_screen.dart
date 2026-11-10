import 'package:flutter/material.dart' hide Text;

import '../data/faq.dart';
import '../theme.dart';
import '../widgets/site_sections.dart';
import '../i18n/text.dart';

const _violet = Color(0xFF667EEA);
const _purple = Color(0xFF764BA2);
const _pink = Color(0xFFF093FB);

/// The site's Help centre (/cs): "E'lon-xabar" and "Savol-javob" tabs.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  bool _faq = false;
  String _category = 'bike';
  int? _open = 0;

  static const _categories = [
    ('bike', 'Mototsikl'),
    ('payment', "To'lov"),
    ('buyers', 'Xaridorlar uchun'),
    ('agents', 'Agentlar uchun'),
    ('membership', "A'zolik"),
    ('community', 'Hamjamiyat'),
    ('other', 'Boshqa'),
  ];

  // Same two notices as the site.
  static const _notices = [
    (true, 'Register to use and get discounts', '01.03.2024'),
    (false, "It's absolutely free to upload and trade bikes", '31.03.2024'),
  ];

  Widget _gradientText(String text, double size,
          {List<Color> colors = const [_violet, _purple, _pink]}) =>
      ShaderMask(
        shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: size,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      );

  Widget _tab(String icon, String label, bool active, VoidCallback onTap) =>
      Expanded(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [_violet, _purple])
                    : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: _violet.withValues(alpha: 0.3), width: 2),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: _violet.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : _violet)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFEEF0FD), Color(0xFFF6F4FE)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: _violet, size: 28),
                    const SizedBox(width: 10),
                    Flexible(child: _gradientText('Yordam markazi', 30)),
                  ],
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [_violet, _purple]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                    '🌟 Biz yordam berishga tayyormiz! Istalgan savolni bering',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: _violet)),
                const SizedBox(height: 22),
                Row(children: [
                  _tab('📢', "E'lon-xabar", !_faq,
                      () => setState(() => _faq = false)),
                  const SizedBox(width: 10),
                  _tab('❓', 'Savol-javob', _faq,
                      () => setState(() => _faq = true)),
                ]),
                const SizedBox(height: 28),
                if (_faq) ..._faqContent() else ..._noticeContent(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }

  List<Widget> _noticeContent() => [
        const Text("📢 E'lon-xabar",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: _violet)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _violet.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_violet, _purple])),
                child: const Row(children: [
                  SizedBox(
                      width: 42,
                      child: Text('#',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Text('Sarlavha',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700))),
                  Text('Sana',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
              for (var i = 0; i < _notices.length; i++)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _notices[i].$1
                        ? const LinearGradient(
                            colors: [Color(0xFFFFF5E6), Color(0xFFFFE6CC)])
                        : null,
                    border: Border(
                      left: BorderSide(
                          color: _notices[i].$1
                              ? const Color(0xFFFF9800)
                              : Colors.transparent,
                          width: 4),
                      bottom: BorderSide(color: _violet.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (_notices[i].$1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('🎉 Event',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          )
                        else
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_violet, _purple]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const Spacer(),
                        Text('📅 ${_notices[i].$3}',
                            style: const TextStyle(
                                fontSize: 12.5, color: Brand.muted)),
                      ]),
                      const SizedBox(height: 10),
                      Text(_notices[i].$2,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Brand.ink)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ];

  List<Widget> _faqContent() {
    final items = faqData[_category] ?? const [];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in _categories)
            ChoiceChip(
              label: Text(c.$2),
              selected: _category == c.$1,
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _category = c.$1;
                _open = 0;
              }),
              labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _category == c.$1 ? Colors.white : _violet),
              selectedColor: _violet,
              backgroundColor: Colors.white,
              side: BorderSide(color: _violet.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _violet.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              _FaqTile(
                question: items[i].$1,
                answer: items[i].$2,
                open: _open == i,
                onTap: () => setState(() => _open = _open == i ? null : i),
              ),
          ],
        ),
      ),
    ];
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile(
      {required this.question,
      required this.answer,
      required this.open,
      required this.onTap});
  final String question;
  final String answer;
  final bool open;
  final VoidCallback onTap;

  Widget _badge(String letter, List<Color> colors) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(letter,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: _violet.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(children: [
                _badge('Q', const [_violet, _purple]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(question,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Brand.ink)),
                ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _violet),
                ),
              ]),
            ),
          ),
          if (open)
            Container(
              color: _violet.withValues(alpha: 0.04),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge('A', const [Color(0xFF25B44B), Color(0xFF178F38)]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(answer,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF4B5563))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

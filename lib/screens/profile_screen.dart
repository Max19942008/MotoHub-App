import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../config.dart';
import '../widgets/site_sections.dart';
import 'my_page_screen.dart';

/// Login / signup for guests, profile + logout for members.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final member = AuthService.instance.member;
        return member == null
            ? const _AuthForm()
            : MyPageScreen(member: member);
      },
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _form = GlobalKey<FormState>();
  final _nick = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  bool _signup = false;
  bool _isAgent = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The site keeps LOGIN / SIGN UP disabled until the fields are filled.
    for (final c in [_nick, _password, _phone]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nick.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signup) {
        await AuthService.instance.signup(
          nick: _nick.text,
          password: _password.text,
          phone: _phone.text,
          isAgent: _isAgent,
        );
      } else {
        await AuthService.instance.login(_nick.text, _password.text);
      }
      // ProfileScreen rebuilds into the profile view on its own.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _violet = Color(0xFF667EEA);
  static const _purple = Color(0xFF764BA2);
  static const _pink = Color(0xFFF093FB);
  static const _slate = Color(0xFF64748B);
  static const _dark = Color(0xFF1E293B);

  InputDecoration _input(String label, String hint, IconData icon,
          {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        hintStyle: const TextStyle(color: Color(0xFFB4BCC8)),
        prefixIcon: Icon(icon, color: _violet),
        suffixIcon: suffix,
        fillColor: Colors.white.withValues(alpha: 0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: _violet.withValues(alpha: 0.12), width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _violet, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      );

  Widget _typeButton(String label, IconData icon, bool agent) {
    final active = _isAgent == agent;
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _busy ? null : () => setState(() => _isAgent = agent),
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [_violet, _purple])
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? null
                  : Border.all(color: _violet.withValues(alpha: 0.3), width: 2),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: _violet.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: active ? Colors.white : _violet),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : _violet)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_busy &&
        _nick.text.isNotEmpty &&
        _password.text.isNotEmpty &&
        (!_signup || _phone.text.isNotEmpty);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F8FE), Color(0xFFFBF7FD), Color(0xFFF4FBFE)],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView(
          padding: const EdgeInsets.only(top: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 36, 22, 26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8F9FF)]),
                  border: Border.all(color: _violet.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                        color: _violet.withValues(alpha: 0.15),
                        blurRadius: 60,
                        offset: const Offset(0, 20)),
                  ],
                ),
                child: Form(
                  key: _form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            decoration: BoxDecoration(boxShadow: [
                              BoxShadow(
                                  color: _violet.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ]),
                            child: Image.asset('assets/brand/logo.png',
                                height: 64),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('SIZNING MOTOTSIKL BOZORINGIZ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                                color: _slate)),
                        const SizedBox(height: 28),
                        Text(_signup ? 'Hisob yaratish' : 'Xush kelibsiz!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 28,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w900,
                                color: _dark)),
                        const SizedBox(height: 10),
                        Text(
                            _signup
                                ? "MOTOPRESTO'ga qo'shiling va mototsikl sotib olishni yoki sotishni boshlang"
                                : "Davom etish uchun MOTOPRESTO'ga kiring",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: _slate)),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _nick,
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: _input('Taxallus',
                              'Taxallusingizni kiriting', Icons.person),
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.length < 3 || t.length > 20) {
                              return "3–20 ta belgi bo'lishi kerak";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: !_showPassword,
                          autofillHints: [
                            _signup
                                ? AutofillHints.newPassword
                                : AutofillHints.password
                          ],
                          textInputAction: _signup
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) => _signup ? null : _submit(),
                          decoration: _input(
                            'Parol',
                            'Parolingizni kiriting',
                            Icons.lock,
                            suffix: IconButton(
                              color: const Color(0xFF94A3B8),
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                          validator: (v) {
                            final t = v ?? '';
                            if (t.length < 5 || t.length > 30) {
                              return "5–30 ta belgi bo'lishi kerak";
                            }
                            return null;
                          },
                        ),
                        if (_signup) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _phone,
                            enabled: !_busy,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            textInputAction: TextInputAction.done,
                            decoration: _input('Phone Number',
                                'Telefon raqamingizni kiriting', Icons.phone),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.length < 7 || t.length > 20) {
                                return "Telefon raqamni to'g'ri kiriting";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                _violet.withValues(alpha: 0.05),
                                _purple.withValues(alpha: 0.05)
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _violet.withValues(alpha: 0.1),
                                  width: 2),
                            ),
                            child: Column(children: [
                              const Text(
                                  "Men sifatida ro'yxatdan o'tmoqchiman:",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _dark)),
                              const SizedBox(height: 14),
                              Row(children: [
                                _typeButton(
                                    'FOYDALANUVCHI', Icons.person, false),
                                const SizedBox(width: 12),
                                _typeButton('AGENT', Icons.two_wheeler, true),
                              ]),
                            ]),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent)),
                        ],
                        const SizedBox(height: 26),
                        Opacity(
                          opacity: canSubmit ? 1 : 0.5,
                          // Own Material so the Ink paints above the card.
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: canSubmit ? _submit : null,
                              child: Ink(
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                      colors: [_violet, _purple, _pink]),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _violet.withValues(alpha: 0.3),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: Center(
                                  child: _busy
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white))
                                      : Text(_signup ? 'SIGN UP' : 'LOGIN',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              letterSpacing: 1,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                                _signup
                                    ? 'Hisobingiz bormi? '
                                    : "Hisobingiz yo'qmi? ",
                                style: const TextStyle(
                                    fontSize: 14, color: _slate)),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: _violet,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: Size.zero),
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _signup = !_signup;
                                        _error = null;
                                      }),
                              child: Text(
                                  _signup ? 'KIRISH' : "RO'YXATDAN O'TISH",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const _PrivacyLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  const _PrivacyLink();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
      onPressed: () => launchUrl(Uri.parse(privacyUrl),
          mode: LaunchMode.externalApplication),
      child: const Text('Maxfiylik siyosati'),
    );
  }
}

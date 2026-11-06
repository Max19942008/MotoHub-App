import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../config.dart';
import '../widgets/common.dart';

/// Login / signup for guests, profile + logout for members.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final member = AuthService.instance.member;
        return member == null ? const _AuthForm() : _ProfileView(member: member);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.member});
  final Member member;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Chiqish')),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.logout();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
        title: const Text('Hisobni o\'chirish'),
        content: const Text(
          'Hisobingiz butunlay o\'chiriladi: barcha qurilmalardagi sessiyalar yopiladi, '
          'e\'lonlaringiz va maqolalaringiz saytdan olib tashlanadi. Buni qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthService.instance.deleteAccount();
      messenger.showSnackBar(const SnackBar(content: Text('Hisobingiz o\'chirildi')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: ClipOval(
            child: SizedBox.square(dimension: 96, child: NetImage(member.image, iconSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        Text(member.nick, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Center(child: Tag(member.isAgent ? 'Diler' : 'Foydalanuvchi', highlight: true)),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              if (member.fullName?.isNotEmpty == true)
                ListTile(leading: const Icon(Icons.person_outline), title: Text(member.fullName!), subtitle: const Text('Ism')),
              if (member.phone?.isNotEmpty == true)
                ListTile(leading: const Icon(Icons.phone_outlined), title: Text(member.phone!), subtitle: const Text('Telefon')),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('E\'lon joylash va profilni tahrirlash hozircha saytda'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: scheme.error,
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Chiqish'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => _deleteAccount(context),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Hisobni o\'chirish'),
        ),
        const _PrivacyLink(),
      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.account_circle_outlined, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(_signup ? 'Ro\'yxatdan o\'tish' : 'Kirish', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          _signup ? 'Hisob saytda ham, ilovada ham ishlaydi' : 'Saytdagi hisobingiz bilan kiring',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Kirish')),
            ButtonSegment(value: true, label: Text('Ro\'yxatdan o\'tish')),
          ],
          selected: {_signup},
          onSelectionChanged: _busy
              ? null
              : (s) => setState(() {
                    _signup = s.first;
                    _error = null;
                  }),
        ),
        const SizedBox(height: 20),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nick,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nik (login)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 3 || t.length > 20) return '3–20 ta belgi bo\'lishi kerak';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: !_showPassword,
                  autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
                  textInputAction: _signup ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: (_) => _signup ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) {
                    final t = v ?? '';
                    if (t.length < 5 || t.length > 30) return '5–30 ta belgi bo\'lishi kerak';
                    return null;
                  },
                ),
                if (_signup) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Telefon raqam',
                      hintText: '+998 90 123 45 67',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.length < 7 || t.length > 20) return 'Telefon raqamni to\'g\'ri kiriting';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Men dilerman'),
                    subtitle: const Text('Mototsikl va qismlar sotuvchi do\'kon yoki agent'),
                    value: _isAgent,
                    onChanged: _busy ? null : (v) => setState(() => _isAgent = v),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(_signup ? 'Ro\'yxatdan o\'tish' : 'Kirish'),
        ),
        const SizedBox(height: 12),
        const _PrivacyLink(),
      ],
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  const _PrivacyLink();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(Uri.parse(privacyUrl), mode: LaunchMode.externalApplication),
      child: const Text('Maxfiylik siyosati'),
    );
  }
}

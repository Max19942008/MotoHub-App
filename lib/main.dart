import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/auth_service.dart';
import 'config.dart';
import 'screens/assistant_screen.dart';
import 'screens/home_screen.dart';
import 'screens/motorbikes_screen.dart';
import 'screens/parts_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init(); // restore a saved session before the first request
  runApp(const MotoprestoApp());
}

class MotoprestoApp extends StatelessWidget {
  const MotoprestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOTOPRESTO',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(),
      home: const HomeShell(),
    );
  }
}

/// Pages reachable from the drawer, same order as the website menu.
enum AppPage { home, bikes, parts, assistant, profile }

/// Website layout: dark navbar (logo · Kirish · ☰), drawer menu,
/// floating "AI Assistant" button bottom-left.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  AppPage _page = AppPage.home;
  String _partsCategory = 'SPARE_PART';

  void _go(AppPage page, {String? category}) {
    setState(() {
      _page = page;
      if (category != null) _partsCategory = category;
    });
    _scaffold.currentState?.closeEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        return Scaffold(
          key: _scaffold,
          appBar: AppBar(
            toolbarHeight: 60,
            titleSpacing: 16,
            title: GestureDetector(onTap: () => _go(AppPage.home), child: const BrandLogo(height: 36)),
            actions: [
              if (auth.isLoggedIn)
                _AvatarButton(image: auth.member?.image, onTap: () => _go(AppPage.profile))
              else
                _LoginPill(onTap: () => _go(AppPage.profile)),
              IconButton(
                tooltip: 'Menyu',
                icon: const Icon(Icons.menu, size: 28),
                onPressed: () => _scaffold.currentState?.openEndDrawer(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          endDrawer: _MenuDrawer(
            page: _page,
            partsCategory: _partsCategory,
            loggedIn: auth.isLoggedIn,
            onGo: _go,
            onLogout: () {
              _scaffold.currentState?.closeEndDrawer();
              auth.logout();
            },
          ),
          body: IndexedStack(
            index: _page.index,
            children: [
              const HomeScreen(),
              const MotorbikesScreen(),
              PartsScreen(
                category: _partsCategory,
                onCategoryChanged: (c) => _partsCategory = c,
              ),
              const AssistantScreen(),
              const ProfileScreen(),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: _page == AppPage.assistant
              ? null
              : _AiFab(onTap: () => _go(AppPage.assistant)),
        );
      },
    );
  }
}

class _LoginPill extends StatelessWidget {
  const _LoginPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.account_circle_outlined, size: 20),
        label: const Text('Kirish'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.image, required this.onTap});
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profil',
      onPressed: onTap,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        ),
        child: ClipOval(child: NetImage(image, iconSize: 18)),
      ),
    );
  }
}

class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer({
    required this.page,
    required this.partsCategory,
    required this.loggedIn,
    required this.onGo,
    required this.onLogout,
  });

  final AppPage page;
  final String partsCategory;
  final bool loggedIn;
  final void Function(AppPage page, {String? category}) onGo;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool active, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: active ? Brand.green.withValues(alpha: 0.12) : null,
              border: Border(left: BorderSide(color: active ? Brand.green : Colors.transparent, width: 3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

    return Drawer(
      width: 300,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 16, right: 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  const BrandLogo(height: 34),
                  const Spacer(),
                  IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            item('Bosh sahifa', page == AppPage.home, () => onGo(AppPage.home)),
            item('Mototsikllar', page == AppPage.bikes, () => onGo(AppPage.bikes)),
            item('Ehtiyot qismlar', page == AppPage.parts && partsCategory == 'SPARE_PART',
                () => onGo(AppPage.parts, category: 'SPARE_PART')),
            item('Aksessuarlar', page == AppPage.parts && partsCategory == 'ACCESSORY',
                () => onGo(AppPage.parts, category: 'ACCESSORY')),
            item('AI yordamchi', page == AppPage.assistant, () => onGo(AppPage.assistant)),
            item(loggedIn ? 'Mening sahifam' : 'Kirish / Ro\'yxatdan o\'tish', page == AppPage.profile,
                () => onGo(AppPage.profile)),
            item('Maxfiylik siyosati', false,
                () => launchUrl(Uri.parse(privacyUrl), mode: LaunchMode.externalApplication)),
            const Spacer(),
            if (loggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Chiqish'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The website's floating "AI Assistant" pill (48px high).
class _AiFab extends StatelessWidget {
  const _AiFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brand.ai,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: [BoxShadow(color: Brand.ai.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy_outlined, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          ),
        ),
      ),
    );
  }
}

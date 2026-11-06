import 'package:flutter/material.dart';

import 'api/auth_service.dart';
import 'screens/assistant_screen.dart';
import 'screens/motorbikes_screen.dart';
import 'screens/parts_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init(); // restore a saved session before the first request
  runApp(const MotoHubApp());
}

const _brand = Color(0xFFE8462B);

class MotoHubApp extends StatelessWidget {
  const MotoHubApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _brand, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoHub',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _titles = ['Mototsikllar', 'Qismlar', 'AI yordamchi', 'Profil'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.two_wheeler, color: scheme.primary),
            const SizedBox(width: 8),
            Text('MotoHub', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: AuthService.instance,
              builder: (context, _) => Text(
                '· ${_tab == 3 && !AuthService.instance.isLoggedIn ? 'Kirish' : _titles[_tab]}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [MotorbikesScreen(), PartsScreen(), AssistantScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler), label: 'Mototsikllar'),
            const NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Qismlar'),
            const NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'AI yordamchi'),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: AuthService.instance.isLoggedIn ? 'Profil' : 'Kirish',
            ),
          ],
        ),
      ),
    );
  }
}

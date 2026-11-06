import 'package:flutter/material.dart';

import 'screens/motorbikes_screen.dart';
import 'screens/parts_screen.dart';

void main() => runApp(const MotoHubApp());

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

  static const _titles = ['Mototsikllar', 'Qismlar'];

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
            Text('· ${_titles[_tab]}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [MotorbikesScreen(), PartsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler), label: 'Mototsikllar'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Qismlar'),
        ],
      ),
    );
  }
}

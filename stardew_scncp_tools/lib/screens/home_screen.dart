import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'sprite_editor_screen.dart';
import 'content_patcher_screen.dart';
import '../widgets/custom_title_bar.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Handle window close event
    if (!kIsWeb) {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: FocusScope(
        autofocus: true,
        child: Scaffold(
          appBar: const CustomTitleBar(),
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              SpriteEditorScreen(),
              ContentPatcherScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.image),
                label: 'Sprite Editor',
              ),
              NavigationDestination(
                icon: Icon(Icons.description),
                label: 'Content Patcher',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/robot_connection_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/control_screen.dart';

void main() {
  runApp(const HexapodControlApp());
}

class HexapodControlApp extends StatelessWidget {
  const HexapodControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RobotConnectionProvider(),
      child: MaterialApp(
        title: 'Hexapod Control',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SetupScreen(),
    ControlScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: 'Control',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

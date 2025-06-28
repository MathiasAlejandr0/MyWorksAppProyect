import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'services_page.dart';
import 'requests_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const ServicesPage(),
    const RequestsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Verificar si se pasó un índice inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is int && args >= 0 && args < _pages.length) {
        setState(() {
          _currentIndex = args;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_repair_service),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Mis Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondaryColor,
      ),
    );
  }
}

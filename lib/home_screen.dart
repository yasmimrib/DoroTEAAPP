// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:dorotea_app/profile_screen.dart';
import 'package:dorotea_app/about_screen.dart';
import 'package:dorotea_app/music_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Map<String, dynamic>> _featureCards;

  @override
  void initState() {
    super.initState();
    _featureCards = [
      {
        'icon': Icons.camera_alt,
        'title': 'Visualizar Agora',
        'description': 'Acompanhe em tempo real como está seu pequeno',
        'onTap': () {
          debugPrint('Visualizar Agora clicado!');
        },
      },
      {
        'icon': Icons.music_note,
        'title': 'Escolher Música',
        'description': 'Escolha a música que o ursinho Dorotea vai tocar',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MusicSelectionScreen()),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'title': 'Relatórios de Humor',
        'description': 'Entenda como tem sido os últimos dias',
        'onTap': () {
          debugPrint('Relatórios de Humor clicado!');
        },
      },
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        debugPrint('Home clicado!');
        break;
      case 1:
        debugPrint('Ursinho clicado (Abrir tela Sobre)!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        debugPrint('Perfil clicado!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: const Text('DoroTEA'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: _featureCards.map((cardData) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildFeatureCard(
                icon: cardData['icon'],
                title: cardData['title'],
                description: cardData['description'],
                onTap: cardData['onTap'] as VoidCallback,
                primaryPurple: primaryPurple,
                lightPurpleText: lightPurpleText,
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Ursinho',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color primaryPurple,
    required Color lightPurpleText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Icon(
              icon,
              size: 40.0,
              color: primaryPurple,
            ),
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: lightPurpleText,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: lightPurpleText),
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
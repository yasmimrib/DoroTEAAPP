import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/screens/music_selection_screen.dart';
import 'package:dorotea_app/screens/report_screen.dart';
import 'package:dorotea_app/screens/camera_screen.dart'; // Importe a tela da câmera
import 'package:dorotea_app/screens/guide_music.dart'; // Importe a nova tela

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Map<String, dynamic>> _featureCards;
  // Aumente a lista para incluir o novo botão
  final List<bool> _isPressed = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _featureCards = [
      {
        'icon': Icons.camera_alt,
        'title': 'Visualizar Agora',
        'description': 'Acompanhe em tempo real como está seu pequeno',
        'onTap': () {
          // Ação para a tela da câmera
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.music_note,
        'title': 'Escolher Música',
        'description': 'Escolha a música que o ursinho Dorotea vai tocar',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicSelectionScreen(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.headphones, // Novo ícone para musicoterapia guiada
        'title': 'Terapia Guiada',
        'description': 'Inicie uma sessão de musicoterapia guiada com o Dorotea',
        'onTap': () {
          // Ação para a tela de musicoterapia guiada
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  GuidedMusic(email: widget.email),
            ),
          );
        },
      },
      {
        'icon': Icons.assignment,
        'title': 'Relatórios de Humor',
        'description': 'Entenda como tem sido os últimos dias',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportScreen(userEmail: widget.email),
            ),
          );
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userEmail: widget.email),
          ),
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
        title: Text(
          'DoroTEA',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: List.generate(_featureCards.length, (index) {
            final cardData = _featureCards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isPressed[index] = true);
                },
                onTapUp: (_) {
                  setState(() => _isPressed[index] = false);
                  cardData['onTap']();
                },
                onTapCancel: () {
                  setState(() => _isPressed[index] = false);
                },
                child: AnimatedScale(
                  scale: _isPressed[index] ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: _buildFeatureCard(
                    icon: cardData['icon'],
                    title: cardData['title'],
                    description: cardData['description'],
                    primaryPurple: primaryPurple,
                    lightPurpleText: lightPurpleText,
                  ),
                ),
              ),
            );
          }),
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
            label: 'DoroTEA',
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
    required Color primaryPurple,
    required Color lightPurpleText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.18),
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
                  style: GoogleFonts.quicksand(
                    color: lightPurpleText,
                    fontSize: 19.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            color: lightPurpleText,
          ),
        ],
      ),
    );
  }
}

// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'package:dorotea_app/profile_screen.dart'; // Importe a tela de perfil
import 'package:dorotea_app/about_screen.dart'; // Importe a tela "Sobre"

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Para controlar o item selecionado na BottomNavigationBar

  // Lista de dados para os cartões de funcionalidade
  final List<Map<String, dynamic>> _featureCards = [
    {
      'icon': Icons.camera_alt, // Ícone da câmera
      'title': 'Visualizar Agora',
      'description': 'Acompanhe em tempo real como está seu pequeno',
      'onTap': () {
        // Lógica para "Visualizar Agora"
        debugPrint('Visualizar Agora clicado!');
      },
    },
    {
      'icon': Icons.music_note, // Ícone de música
      'title': 'Escolher Música',
      'description': 'Escolha a música que o ursinho Dorotea vai tocar',
      'onTap': () {
        // Lógica para "Escolher Música"
        debugPrint('Escolher Música clicado!');
      },
    },
    {
      'icon': Icons.assignment, // Ícone de planilha/relatório
      'title': 'Relatórios de Humor',
      'description': 'Entenda como tem sido os últimos dias',
      'onTap': () {
        // Lógica para "Relatórios de Humor"
        debugPrint('Relatórios de Humor clicado!');
      },
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Lógica para navegação da BottomNavigationBar
    switch (index) {
      case 0:
        debugPrint('Home clicado!');
        // Se você tiver uma Home mais complexa com sub-telas, gerenciará a navegação aqui.
        // Por enquanto, fica na HomeScreen.
        break;
      case 1:
        debugPrint('Ursinho clicado (Abrir tela Sobre)!');
        // Navegação para a Tela "Sobre"
        Navigator.push( // Usamos push para poder voltar para a HomeScreen
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        debugPrint('Perfil clicado!');
        // Navegação para a Tela de Perfil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cores do tema, puxadas de main.dart
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple, // Fundo roxo consistente
      appBar: AppBar(
        title: const Text('DoroTEA'), // Título da AppBar conforme a imagem
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: _featureCards.map((cardData) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0), // Espaçamento entre os cartões
              child: _buildFeatureCard(
                icon: cardData['icon'],
                title: cardData['title'],
                description: cardData['description'],
                onTap: cardData['onTap'],
                primaryPurple: primaryPurple,
                lightPurpleText: lightPurpleText,
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryPurple, // Fundo da barra de navegação
        selectedItemColor: Colors.white, // Cor do ícone selecionado
        unselectedItemColor: Colors.white.withOpacity(0.7), // Cor dos ícones não selecionados
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // O label não aparece na imagem, mas é boa prática ter
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets), // Ícone de urso/pata
            label: 'Ursinho',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ícone de perfil
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para construir cada cartão de funcionalidade
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
        color: Colors.white, // Fundo branco do cartão
        borderRadius: BorderRadius.circular(20.0), // Borda arredondada
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone estático (câmera, música, planilha)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2), // Fundo suave para o ícone
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Icon(
              icon,
              size: 40.0,
              color: primaryPurple, // Cor do ícone
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
                    color: lightPurpleText, // Cor do título do cartão
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600], // Cor da descrição
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
          // Seta clicável
          IconButton(
            icon: Icon(Icons.arrow_forward, color: lightPurpleText), // Cor da seta
            onPressed: onTap, // Ação ao clicar na seta
          ),
        ],
      ),
    );
  }
}
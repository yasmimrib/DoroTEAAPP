import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dorotea_app/screens/add_music_screen.dart';
import 'package:dorotea_app/Telas_X/profile_screen.dart';
import 'package:dorotea_app/Telas_X/about_screen.dart';
import 'package:dorotea_app/Telas_X/home_screen.dart';
import 'package:dorotea_app/constants.dart'; // Assumindo AppConfig.apiUrl

// Estrutura de dados para a música
class Music {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final bool isDeletable;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.isDeletable,
  });

  // Converte Map<String, dynamic> em objeto Music
  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'].toString(), // Garante que o ID é string (para BD e assets)
      title: json['title'] ?? 'Sem Título',
      artist: json['artist'] ?? 'Sem Artista',
      audioUrl: json['audioUrl'] ?? '',
      isDeletable: json['isDeletable'] ?? false,
    );
  }
}

class MusicSelectionScreen extends StatefulWidget {
  final String email;
  const MusicSelectionScreen({super.key, required this.email});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  // Lista de músicas padrão (imutável)
  final List<Music> _defaultMusicList = [
    Music(
        id: 'bmp',
        title: '60 BPM',
        artist: 'Anônimo',
        audioUrl: 'assets/audios/bmp.mp3',
        isDeletable: false),
    Music(
        id: 'brilha_estrelinha',
        title: 'Brilha Estrelinha',
        artist: 'Anônimo',
        audioUrl: 'assets/audios/brilha_brilha_estrelinha.mp3',
        isDeletable: false),
    Music(
        id: 'clair_de_lune',
        title: 'Clair de Lune',
        artist: 'Claude Debussy',
        audioUrl: 'assets/audios/clair_de_lune.mp3',
        isDeletable: false),
    Music(
        id: 'lullaby',
        title: 'Lullaby',
        artist: 'Johannes Brahms',
        audioUrl: 'assets/audios/lullaby.mp3',
        isDeletable: false),
    Music(
        id: 'primavera',
        title: 'Primavera',
        artist: 'Vivaldi',
        audioUrl: 'assets/audios/primavera.mp3',
        isDeletable: false),
  ];

  // Lista combinada de todas as músicas (padrão + usuário)
  List<Music> _allMusics = [];

  // Estado para a seleção: armazena o ID único da música pré-selecionada.
  String? _selectedMusicUniqueId;
  
  final _player = AudioPlayer();
  String? _playingMusicId; // Mudança para usar o ID da música ao invés do índice
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inicializa _allMusics com as músicas padrão
    _allMusics = _defaultMusicList;
    // Define a primeira música padrão como a inicialmente selecionada
    _selectedMusicUniqueId = _defaultMusicList.first.id;
    _loadUserMusic();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // --- Navegação (Mantida) ---
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const HomeScreen(email: 'user@email.com')),
        );
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

  // --- Lógica de Carregamento de Músicas ---
  Future<void> _loadUserMusic() async {
    final String userEmail = widget.email.trim();
    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado ou email inválido.');
      return;
    }

    final url = Uri.parse('${AppConfig.apiUrl}/musics/$userEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> fetchedMusics = data['musics'];
        final List<Music> userMusics =
            fetchedMusics.map((json) => Music.fromJson(json)).toList();

        setState(() {
          // Combina as listas de música padrão e de usuário
          _allMusics = [..._defaultMusicList, ...userMusics];
        });
        debugPrint('Músicas do usuário carregadas com sucesso.');
      } else {
        debugPrint('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão ao carregar músicas: $e');
    }
  }

  // --- NOVA Lógica de Pré-Seleção ---
  void _selectMusic(Music music) async {
    setState(() {
      _selectedMusicUniqueId = music.id;
    });
    // Envia a seleção para a API
    await _sendPreferredMusicToApi(music);
  }

  // --- NOVA Chamada API para Salvar a Música Preferida ---
  Future<void> _sendPreferredMusicToApi(Music music) async {
    final String userEmail = widget.email.trim();
    
    // ATENÇÃO: Rota hipotética. Você deve implementá-la no seu servidor Flask!
    final url = Uri.parse('${AppConfig.apiUrl}/set_preferred_music'); 
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': userEmail,
          'musicId': music.id,
          'audioUrl': music.audioUrl,
          'title': music.title,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Música "${music.title}" selecionada para o ESP!')),
          );
        }
      } else {
        debugPrint('Erro ao enviar música preferida: ${response.statusCode}');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar preferência no servidor.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro de conexão ao enviar preferência: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao comunicar a preferência.')),
        );
      }
    }
  }


  // --- Lógica de Deleção ---
  Future<void> _deleteMusic(String musicId) async {
    final url = Uri.parse('${AppConfig.apiUrl}/delete_music/$musicId');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Música deletada com sucesso!')),
          );
        }
        await _loadUserMusic();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao deletar música.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao deletar música: $e');
      // ... (outros tratamentos de erro)
    }
  }

  // --- Lógica de Reprodução (Modificada para usar ID) ---
  Future<void> _playMusic(String audioUrl, String musicId) async {
    try {
      if (_playingMusicId == musicId) {
        // Se já está tocando, pausa
        setState(() {
          _playingMusicId = null;
        });
        await _player.pause();
        return;
      }
      
      // Para o áudio atual se estiver tocando
      await _player.stop();
      
      // Atualiza o estado ANTES de começar a tocar
      setState(() {
        _playingMusicId = musicId;
      });

      if (audioUrl.startsWith('assets/')) {
        await _player.setAsset(audioUrl);
      } else {
        await _player.setUrl(audioUrl);
      }
      
      await _player.play();

    } catch (e) {
      debugPrint('Erro ao tocar música: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao tocar música. Verifique o URL ou o arquivo.')),
        );
      }
      setState(() {
        _playingMusicId = null;
      });
    }
  }

  // --- Widgets de Design ---

  Widget _buildMusicSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicItem(BuildContext context, Music music) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingMusicId == music.id;
    final bool isSelected = _selectedMusicUniqueId == music.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Material(
        elevation: isSelected ? 8 : 3,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
                ? Border.all(color: primaryPurple, width: 2.5)
                : null,
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Botão de play/pause
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPlaying ? primaryPurple.withOpacity(0.8) : primaryPurple,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: primaryPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => _playMusic(music.audioUrl, music.id),
                  ),
                ),
                const SizedBox(width: 16),
                // Informações da música
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.title,
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? primaryPurple : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        music.artist,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Ações (delete e seleção)
                Column(
                  children: [
                    if (music.isDeletable)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                        onPressed: () => _deleteMusic(music.id),
                      ),
                    GestureDetector(
                      onTap: () => _selectMusic(music),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primaryPurple : Colors.grey[400]!,
                            width: 2,
                          ),
                          color: isSelected ? primaryPurple : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMusicCard() {
    final Color primaryPurple = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.library_music,
                  color: primaryPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar Nova Música',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryPurple,
                      ),
                    ),
                    Text(
                      'Personalize sua biblioteca',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMusicScreen(email: widget.email),
                      ),
                    ).then((_) {
                      _loadUserMusic();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    // Separa as músicas para exibição (apenas para títulos de seção)
    final List<Music> userMusics =
        _allMusics.where((m) => m.isDeletable).toList();
    final List<Music> defaultMusics =
        _allMusics.where((m) => !m.isDeletable).toList();

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
      body: RefreshIndicator(
        onRefresh: _loadUserMusic,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddMusicCard(),

              // Músicas Padrão
              _buildMusicSectionHeader('Músicas Padrão'),
              if (defaultMusics.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nenhuma música padrão disponível.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: defaultMusics.length,
                  itemBuilder: (context, index) {
                    return _buildMusicItem(context, defaultMusics[index]);
                  },
                ),

              // Músicas do Usuário
              _buildMusicSectionHeader('Músicas do Usuário'),
              if (userMusics.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nenhuma música adicionada ainda.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userMusics.length,
                  itemBuilder: (context, index) {
                    return _buildMusicItem(context, userMusics[index]);
                  },
                ),
            ],
          ),
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
}

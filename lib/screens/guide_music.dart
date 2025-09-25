import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

// O nome da tela foi atualizado para ser mais claro
class GuidedMusic extends StatefulWidget {
  final String email;
  const GuidedMusic({super.key, required this.email});

  @override
  State<GuidedMusic> createState() => _GuidedMusicState();
}

class _GuidedMusicState extends State<GuidedMusic> {
  static const String _serverIp = 'http://192.168.0.110:5000';

  final List<Map<String, dynamic>> _defaultMusicList = [
    {
      'id': 'bmp',
      'title': '60 BPM',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bmp.mp3',
      'isDeletable': false,
    },
    {
      'id': 'brilha_estrelinha',
      'title': 'Brilha Estrelinha',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/brilha_brilha_estrelinha.mp3',
      'isDeletable': false,
    },
    {
      'id': 'clair_de_lune',
      'title': 'Clair de Lune',
      'artist': 'Claude Debussy',
      'audioUrl': 'assets/audios/clair_de_lune.mp3',
      'isDeletable': false,
    },
    {
      'id': 'lullaby',
      'title': 'Lullaby',
      'artist': 'Johannes Brahms',
      'audioUrl': 'assets/audios/lullaby.mp3',
      'isDeletable': false,
    },
    {
      'id': 'primavera',
      'title': 'Primavera',
      'artist': 'Vivaldi',
      'audioUrl': 'assets/audios/primavera.mp3',
      'isDeletable': false,
    },
  ];

  late List<Map<String, dynamic>> _userMusicList;
  final _player = AudioPlayer();
  int? _playingIndex;

  // Variável para armazenar o ID da música sendo tocada no ESP
  int? _playingEspId;

  @override
  void initState() {
    super.initState();
    _userMusicList = [];
    _loadUserMusic();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _loadUserMusic() async {
    final String userEmail = widget.email;
    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado.');
      return;
    }

    final url = Uri.parse('$_serverIp/musics/$userEmail');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> fetchedMusics = data['musics'];
        final List<Map<String, dynamic>> userMusics =
            List<Map<String, dynamic>>.from(fetchedMusics.map((music) {
          return {
            'id': music['id'].toString(),
            'title': music['title'] ?? 'Sem Título',
            'artist': music['artist'] ?? 'Sem Artista',
            'audioUrl': music['audioUrl'] ?? '',
            'isDeletable': music['isDeletable'] ?? true,
          };
        }));
        setState(() {
          _userMusicList = userMusics;
        });
        debugPrint('Músicas do usuário carregadas com sucesso.');
      } else {
        debugPrint('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão ao carregar músicas: $e');
    }
  }

  Future<void> _playMusicOnEsp(String musicId, int index) async {
    final url = Uri.parse('$_serverIp/play_music');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'music_id': musicId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Comando de reprodução enviado para o ESP!')),
          );
        }
        setState(() {
          _playingEspId = index;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao enviar comando de reprodução.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao enviar comando para o ESP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão com o ESP.')),
        );
      }
    }
  }

  Future<void> _stopMusicOnEsp() async {
    final url = Uri.parse('$_serverIp/stop_music');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        debugPrint('Comando de parada enviado para o ESP!');
        setState(() {
          _playingEspId = null;
        });
      }
    } catch (e) {
      debugPrint('Erro ao enviar comando de parada: $e');
    }
  }

  // Novo widget para os cabeçalhos de seção, para o grid
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
      child: Text(
        title,
        style: GoogleFonts.quicksand(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // Novo widget para os cartões de música no grid
  Widget _buildMusicGridItem(
      BuildContext context, Map<String, dynamic> music, int index) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingEspId == index;
    return GestureDetector(
      onTap: () async {
        if (isPlaying) {
          _stopMusicOnEsp();
        } else {
          _playMusicOnEsp(music['id'], index);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 6,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícone para mostrar status de reprodução
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: primaryPurple,
                  size: 32,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    music['title'] ?? 'Título Desconhecido',
                    style: GoogleFonts.quicksand(
                      color: primaryPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    music['artist'] ?? 'Artista Desconhecido',
                    style: GoogleFonts.roboto(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: Text(
          'Musicoterapia Guiada',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Suas Músicas'),
            if (_userMusicList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Nenhuma música adicionada ainda.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _userMusicList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final music = _userMusicList[index];
                    return _buildMusicGridItem(context, music, index);
                  },
                ),
              ),
            _buildSectionHeader('Padrão para Relaxar'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _defaultMusicList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final music = _defaultMusicList[index];
                  return _buildMusicGridItem(
                      context, music, _userMusicList.length + index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

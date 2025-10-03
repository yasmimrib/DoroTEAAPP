import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuidedMusic extends StatefulWidget {
  final String email;
  const GuidedMusic({super.key, required this.email});

  @override
  State<GuidedMusic> createState() => _GuidedMusicState();
}

class _GuidedMusicState extends State<GuidedMusic> {
  static const String _espIp = 'http://192.168.0.10';

  final List<Map<String, dynamic>> _defaultMusicList = [
    {
      'id': 'bmp',
      'title': '60 BPM',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/bmp.mp3',
      'isDeletable': false,
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'id': 'brilha_estrelinha',
      'title': 'Brilha Estrelinha',
      'artist': 'Anônimo',
      'audioUrl': 'assets/audios/brilha_brilha_estrelinha.mp3',
      'isDeletable': false,
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'id': 'clair_de_lune',
      'title': 'Clair de Lune',
      'artist': 'Claude Debussy',
      'audioUrl': 'assets/audios/clair_de_lune.mp3',
      'isDeletable': false,
      'icon': Icons.nightlight,
      'color': Colors.indigo,
    },
    {
      'id': 'lullaby',
      'title': 'Lullaby',
      'artist': 'Johannes Brahms',
      'audioUrl': 'assets/audios/lullaby.mp3',
      'isDeletable': false,
      'icon': Icons.bedtime,
      'color': Colors.purple,
    },
    {
      'id': 'primavera',
      'title': 'Primavera',
      'artist': 'Vivaldi',
      'audioUrl': 'assets/audios/primavera.mp3',
      'isDeletable': false,
      'icon': Icons.local_florist,
      'color': Colors.green,
    },
  ];

  late List<Map<String, dynamic>> _userMusicList;
  int? _playingEspId;

  @override
  void initState() {
    super.initState();
    _userMusicList = [];
    _loadUserMusic();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadUserMusic() async {
    final String userEmail = widget.email;
    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado.');
      return;
    }

    final url = Uri.parse('http://192.168.0.110:5000/musics/$userEmail');
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
            'icon': Icons.music_note,
            'color': Theme.of(context).primaryColor,
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
    // Atualiza o estado IMEDIATAMENTE
    setState(() {
      _playingEspId = index;
    });
    
    final url = Uri.parse('$_espIp/play');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': musicId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Música iniciada no DoroTEA!')),
          );
        }
      } else {
        // Se falhou, reverte o estado
        setState(() {
          _playingEspId = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao iniciar música.')),
          );
        }
      }
    } catch (e) {
      // Se deu erro, reverte o estado
      setState(() {
        _playingEspId = null;
      });
      debugPrint('Erro ao enviar comando para o ESP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão com o DoroTEA.')),
        );
      }
    }
  }

  Future<void> _stopMusicOnEsp() async {
    // Atualiza o estado IMEDIATAMENTE
    setState(() {
      _playingEspId = null;
    });
    
    final url = Uri.parse('$_espIp/stop');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        debugPrint('Música parada no ESP!');
      }
    } catch (e) {
      debugPrint('Erro ao parar música: $e');
    }
  }

  Widget _buildMusicCard(Map<String, dynamic> music, int index) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingEspId == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        elevation: isPlaying ? 8 : 4,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isPlaying 
                ? LinearGradient(
                    colors: [primaryPurple.withOpacity(0.8), primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPlaying ? Colors.white.withOpacity(0.2) : music['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                music['icon'],
                color: isPlaying ? Colors.white : music['color'],
                size: 30,
              ),
            ),
            title: Text(
              music['title'],
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPlaying ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              music['artist'],
              style: TextStyle(
                color: isPlaying ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: GestureDetector(
              onTap: () async {
                if (isPlaying) {
                  _stopMusicOnEsp();
                } else {
                  _playMusicOnEsp(music['id'], index);
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isPlaying ? Colors.white : primaryPurple,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isPlaying ? primaryPurple : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.headphones, color: Colors.white, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Musicoterapia Guiada',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Toque para reproduzir no DoroTEA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_userMusicList.isNotEmpty) ...[
              _buildSectionTitle('Suas Músicas'),
              ...List.generate(_userMusicList.length, (index) {
                return _buildMusicCard(_userMusicList[index], index);
              }),
            ],

            _buildSectionTitle('Biblioteca Terapêutica'),
            ...List.generate(_defaultMusicList.length, (index) {
              return _buildMusicCard(
                _defaultMusicList[index], 
                _userMusicList.length + index
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
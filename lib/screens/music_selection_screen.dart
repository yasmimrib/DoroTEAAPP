// lib/screens/music_selection_screen.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dorotea_app/screens/add_music_screen.dart';
import 'package:dorotea_app/screens/home_screen.dart';
import 'package:dorotea_app/screens/profile_screen.dart';
import 'package:dorotea_app/screens/initial_screen.dart';
import 'package:dorotea_app/screens/report_screen.dart';


class MusicSelectionScreen extends StatefulWidget {
  final String email;
  const MusicSelectionScreen({super.key, required this.email});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  // Lista de músicas padrão. O campo 'audioUrl' aponta para o asset.
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

  late List<Map<String, dynamic>> _musicList;
  final _player = AudioPlayer();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _musicList = List.from(_defaultMusicList);
    _loadAllMusic();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _loadAllMusic() async {
    final String userEmail = widget.email;

    if (userEmail.isEmpty) {
      debugPrint('Usuário não logado.');
      return;
    }

    const String apiUrl = 'http://127.0.0.1:5000';
    final url = Uri.parse('$apiUrl/musics/$userEmail');

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
          _musicList = List.from(_defaultMusicList);
          _musicList.addAll(userMusics);
        });

        debugPrint('Músicas do usuário carregadas com sucesso.');
      } else {
        debugPrint('Erro ao carregar músicas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro de conexão ao carregar músicas: $e');
    }
  }

  Future<void> _deleteMusic(String musicId) async {
    const String apiUrl = 'http://127.0.0.1:5000';
    final url = Uri.parse('$apiUrl/delete_music/$musicId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Música deletada com sucesso!')),
          );
        }
        _loadAllMusic();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao deletar música.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao deletar música: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de conexão ao deletar música.')),
        );
      }
    }
  }

  Future<void> _playMusic(String audioUrl, int index) async {
    try {
      if (audioUrl.startsWith('assets/')) {
        await _player.setAsset(audioUrl);
      } else {
        await _player.setUrl(audioUrl);
      }
      
      await _player.play();
      setState(() {
        _playingIndex = index;
      });
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          setState(() {
            _playingIndex = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Erro ao tocar música: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao tocar música. Verifique o URL.')),
        );
      }
    }
  }

  void _pauseMusic() {
    _player.pause();
    setState(() {
      _playingIndex = null;
    });
  }

  Widget _buildMusicItem(
      BuildContext context, Map<String, dynamic> music, int index) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final bool isPlaying = _playingIndex == index;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: music['isSelected'] ?? false ? primaryPurple : Colors.white,
      child: ListTile(
        leading: Icon(
          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          color: music['isSelected'] ?? false ? Colors.white : primaryPurple,
          size: 40,
        ),
        title: Text(
          music['title'] ?? 'Título Desconhecido',
          style: TextStyle(
            color: music['isSelected'] ?? false ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          // CORREÇÃO: Usar o campo 'artist' para músicas da API
          music['artist'] ?? 'Artista Desconhecido',
          style: TextStyle(
            color: music['isSelected'] ?? false ? Colors.white70 : Colors.grey[600],
          ),
        ),
        trailing: music['isDeletable'] ?? false
            ? IconButton(
                icon: Icon(Icons.delete,
                    color: music['isSelected'] ?? false ? Colors.white : Colors.red),
                onPressed: () {
                  _deleteMusic(music['id'].toString());
                },
              )
            : null,
        onTap: () async {
          setState(() {
            _musicList.forEach((m) => m['isSelected'] = false);
            music['isSelected'] = true;
          });
          if (isPlaying) {
            _pauseMusic();
          } else {
            _playMusic(music['audioUrl'], index);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: const Text('Escolher Música'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAllMusic();
        },
        child: ListView.builder(
          itemCount: _musicList.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAddMusicCard();
            }
            final music = _musicList[index - 1];
            return _buildMusicItem(context, music, index - 1);
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(lightPurpleText),
    );
  }

  Widget _buildAddMusicCard() {
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adicione suas próprias músicas',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: lightPurpleText),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: lightPurpleText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMusicScreen(email: widget.email),
                  ),
                ).then((_) {
                  _loadAllMusic();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(Color lightPurpleText) {
    return BottomNavigationBar(
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
      selectedItemColor: lightPurpleText,
      unselectedItemColor: Colors.grey,
      onTap: (index) async {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(email: widget.email)),
          );
        } else if (index == 2) {
          if (widget.email.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(userEmail: widget.email)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, faça login novamente.')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InitialScreen()),
            );
          }
        }
      },
    );
  }
}
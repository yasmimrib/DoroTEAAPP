import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dorotea_app/screens/add_music_screen.dart'; 
import 'package:dorotea_app/screens/home_screen.dart';
import 'package:dorotea_app/screens/about_screen.dart';
import 'package:dorotea_app/screens/profile_screen.dart';

class MusicSelectionScreen extends StatefulWidget {
  const MusicSelectionScreen({super.key});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  // ATUALIZADO: Usando caminhos para arquivos locais
  final List<Map<String, dynamic>> _defaultMusicList = [
    {'id': 'bmp', 'title': '60 BPM', 'time': '2:40 (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/audios/bmp.mp3'},
    {'id': 'brilha_estrelinha', 'title': 'Brilha Estrelinha', 'time': '1:17 (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/audios/brilha_brilha_estrelinha.mp3'},
    {'id': 'clair_de_lune', 'title': 'Clair de Lune', 'time': '5:24 (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/audios/claire_de_lune.mp3'},
    {'id': 'gymnopedle', 'title': 'Gymnopédie No.1', 'time': '3:29 (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/audios/gymnopedle.mp3'},
  ];

  List<Map<String, dynamic>> _allMusicList = [];
  int _selectedIndex = 1;
  String? _currentPlayingMusicId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadAllMusic();
    
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.ready) {
        setState(() {
          // Atualiza a UI quando a música está pronta para tocar
        });
      }
      if (playerState.playing) {
        // Nada a fazer, o play já atualizou o ID.
      } else if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _currentPlayingMusicId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAllMusic() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    _allMusicList = List.from(_defaultMusicList);

    if (user != null) {
      try {
        QuerySnapshot userMusicSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('musics')
            .get();
        
        for (var doc in userMusicSnapshot.docs) {
          _allMusicList.add({
            'id': doc.id,
            'title': doc['title'] as String,
            'time': doc['time'] as String,
            'audioUrl': doc['audioUrl'] as String,
            'isSelected': doc['isSelected'] as bool,
            'isDeletable': true,
          });
        }

        setState(() {}); 
        debugPrint('Músicas do Firebase recarregadas: ${_allMusicList.length}');
        
      } catch (e) {
        debugPrint('Erro ao carregar músicas do usuário: $e');
      }
    }
  }

  void _playMusic(String id, String audioUrl) async {
    try {
      if (audioUrl.isNotEmpty) {
        await _audioPlayer.stop();

        // ATUALIZADO: Verificação para tocar URL ou arquivo local
        if (audioUrl.startsWith('http')) {
          await _audioPlayer.setUrl(audioUrl);
        } else {
          await _audioPlayer.setAsset(audioUrl);
        }

        await _audioPlayer.play();
        setState(() {
          _currentPlayingMusicId = id;
        });
      } 
    } catch (e) {
      debugPrint('Erro ao tocar a música: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  Future<void> _deleteMusic(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('musics')
            .doc(docId)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música excluída com sucesso!')),
        );

        _loadAllMusic();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir música.')),
        );
        debugPrint('Erro ao excluir música do Firestore: $e');
      }
    }
  }

  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Música'),
          content: const Text('Tem certeza que deseja excluir esta música?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMusic(docId);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'DoroTEA',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.70,
                ),
                itemCount: _allMusicList.length,
                itemBuilder: (context, index) {
                  return _buildMusicGridBlock(
                    _allMusicList[index]['id'] as String,
                    _allMusicList[index]['title'] as String,
                    _allMusicList[index]['time'] as String,
                    _allMusicList[index]['isSelected'] as bool,
                    _allMusicList[index]['isDeletable'] as bool,
                    _allMusicList[index]['audioUrl'] as String,
                    index,
                    primaryPurple,
                    lightPurpleText
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAddMusicBlock(lightPurpleText),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Ursinho'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: primaryPurple,
      ),
    );
  }

  Widget _buildMusicGridBlock(String id, String title, String time, bool isSelected, bool isDeletable, String audioUrl, int index, Color primaryPurple, Color lightPurpleText) {
    bool isCurrentSongPlaying = _currentPlayingMusicId == id && _audioPlayer.playing;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(Icons.music_note, size: 50, color: lightPurpleText),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: lightPurpleText),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      time,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isCurrentSongPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: lightPurpleText,
                    size: 40,
                  ),
                  onPressed: () {
                    if (isCurrentSongPlaying) {
                      _audioPlayer.pause();
                      setState(() {
                        _currentPlayingMusicId = null;
                      });
                    } else {
                      _playMusic(id, audioUrl);
                    }
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selecionar',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? lightPurpleText : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          for (int i = 0; i < _allMusicList.length; i++) {
                            _allMusicList[i]['isSelected'] = (i == index);
                          }
                        });
                      },
                      activeColor: lightPurpleText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDeletable)
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
                onPressed: () => _showDeleteConfirmationDialog(id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddMusicBlock(Color lightPurpleText) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adicione suas próprias músicas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: lightPurpleText),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: lightPurpleText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMusicScreen()),
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
      currentIndex: _selectedIndex,
      selectedItemColor: lightPurpleText,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
    );
  }
}
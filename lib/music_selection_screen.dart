import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dorotea_app/add_music_screen.dart';
import 'package:dorotea_app/home_screen.dart';
import 'package:dorotea_app/about_screen.dart';
import 'package:dorotea_app/profile_screen.dart';

class MusicSelectionScreen extends StatefulWidget {
  const MusicSelectionScreen({super.key});

  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final List<Map<String, dynamic>> _defaultMusicList = [
    {'id': 'calm_music', 'title': 'Música Calma', 'artist': 'X (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/musics/som-ambiente-relaxante.mp3'},
    {'id': 'relaxing_melody', 'title': 'Melodia Relaxante', 'artist': 'X (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/musics/som-ambiente-piano.mp3'},
    {'id': 'nature_sounds', 'title': 'Sons da Natureza', 'artist': 'X (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/musics/som-ambiente-natureza.mp3'},
    {'id': 'lullaby', 'title': 'Canção de Ninar', 'artist': 'X (min)', 'isSelected': false, 'isDeletable': false, 'audioUrl': 'assets/musics/som-ambiente-ninar.mp3'},
  ];

  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Lógica de comunicação BLE
  Future<void> _sendCommandToEspBle(String audioUrl) async {
    if (!await FlutterBluePlus.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth não suportado neste dispositivo.')),
      );
      return;
    }

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ative o Bluetooth.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procurando pelo ESP32...')),
      );

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      BluetoothDevice? espDevice;
      // Correção: acessa a lista de resultados de forma segura
      final scanResults = await FlutterBluePlus.scanResults.first;
      for (final r in scanResults) {
        if ((r.device.platformName ?? '') == 'ESP32' || (r.device.localName ?? '') == 'ESP32') {
          espDevice = r.device;
          break;
        }
      }

      await FlutterBluePlus.stopScan();

      if (espDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ESP32 não encontrado.')),
        );
        return;
      }

      await espDevice.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a ${espDevice.platformName}')),
      );

      final services = await espDevice.discoverServices();
      BluetoothCharacteristic? filenameCharacteristic;

      final serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
      final characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

      for (var service in services) {
        if (service.uuid == serviceUuid) {
          for (var c in service.characteristics) {
            if (c.uuid == characteristicUuid) {
              filenameCharacteristic = c;
              break;
            }
          }
          break;
        }
      }

      if (filenameCharacteristic != null) {
        final command = 'PLAY:$audioUrl';
        await filenameCharacteristic.write(command.codeUnits, withoutResponse: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comando de reprodução enviado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serviço/Característica não encontrada.')),
        );
      }

      await espDevice.disconnect();
    } catch (e) {
      debugPrint("Erro BLE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na comunicação BLE: $e')),
      );
    } finally {
      FlutterBluePlus.stopScan();
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMusicList(),
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

  Widget _buildMusicList() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildMusicGridView(_defaultMusicList);
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('musics')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar músicas.'));
        }
        
        List<Map<String, dynamic>> userMusicList = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['title'] as String,
            'artist': doc['artist'] as String,
            'audioUrl': doc['audioUrl'] as String,
            'isSelected': doc['isSelected'] as bool,
            'isDeletable': true,
          };
        }).toList();

        List<Map<String, dynamic>> allMusicList = List.from(_defaultMusicList)..addAll(userMusicList);

        return _buildMusicGridView(allMusicList);
      },
    );
  }

  Widget _buildMusicGridView(List<Map<String, dynamic>> musicList) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: musicList.length,
      itemBuilder: (context, index) {
        return _buildMusicGridBlock(
          musicList[index]['id'] as String,
          musicList[index]['title'] as String,
          musicList[index]['artist'] as String,
          musicList[index]['isSelected'] as bool,
          musicList[index]['isDeletable'] as bool,
          musicList[index]['audioUrl'] as String?,
          musicList,
          index,
          primaryPurple,
          lightPurpleText
        );
      },
    );
  }

  Widget _buildMusicGridBlock(
    String id, 
    String title, 
    String artist, 
    bool isSelected, 
    bool isDeletable, 
    String? audioUrl,
    List<Map<String, dynamic>> musicList, 
    int index, 
    Color primaryPurple, 
    Color lightPurpleText
  ) {
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
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: lightPurpleText),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artist,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.play_circle_filled,
                    color: lightPurpleText,
                    size: 40,
                  ),
                  onPressed: () {
                    if (audioUrl != null && audioUrl.isNotEmpty) {
                      _sendCommandToEspBle(audioUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Esta música não possui um URL de áudio definido.')),
                      );
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
                      onChanged: (bool? value) async {
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          try {
                            // Desseleciona a música anterior
                            final prevSelected = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('musics')
                                .where('isSelected', isEqualTo: true)
                                .get();

                            if (prevSelected.docs.isNotEmpty) {
                               await prevSelected.docs.first.reference.update({'isSelected': false});
                            }
                            
                            // Seleciona a música atual
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('musics')
                                .doc(id)
                                .update({'isSelected': true});
                          } catch (e) {
                            debugPrint('Erro ao atualizar seleção no Firebase: $e');
                          }
                        }
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
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Adicione suas próprias músicas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: lightPurpleText
                ),
                softWrap: true,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: lightPurpleText),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMusicScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
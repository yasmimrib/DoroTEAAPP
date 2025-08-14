import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';

class AddMusicScreen extends StatefulWidget {
  const AddMusicScreen({super.key});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _urlController = TextEditingController();

  final _audioPlayer = AudioPlayer();
  bool _isUrlValid = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _urlController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkAndPlayUrl() async {
    // Adiciona uma validação inicial de formato antes de tentar tocar
    if (_urlController.text.isEmpty || !_isValidUrlFormat(_urlController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um URL válido.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _audioPlayer.setUrl(_urlController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL validado com sucesso!')),
      );
      setState(() {
        _isUrlValid = true;
      });
    } catch (e) {
      debugPrint('Erro ao validar URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválido. Por favor, verifique o link.')),
      );
      setState(() {
        _isUrlValid = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para validar o formato do URL
  bool _isValidUrlFormat(String url) {
    // Expressão regular para validar formato de URL básico
    final urlRegExp = RegExp(r'^(http|https):\/\/');
    return urlRegExp.hasMatch(url);
  }

  Future<void> _saveMusicToFirebase() async {
    if (!_formKey.currentState!.validate() || !_isUrlValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos e valide o URL.')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('musics')
            .add({
          'title': _titleController.text,
          'artist': _artistController.text,
          'audioUrl': _urlController.text,
          'isSelected': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Música adicionada com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar música. Tente novamente.')),
        );
        debugPrint('Erro ao salvar música no Firebase: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: const Text(
          'Adicionar Música',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), 
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0), 
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de Título
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Título da Música',
                      prefixIcon: Icon(Icons.music_note, color: lightPurpleText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o título da música.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo de Artista
                  TextFormField(
                    controller: _artistController,
                    decoration: InputDecoration(
                      labelText: 'Artista',
                      prefixIcon: Icon(Icons.person, color: lightPurpleText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do artista.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo de URL
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL do Arquivo de Áudio',
                      prefixIcon: Icon(Icons.link, color: lightPurpleText),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      errorText: _isUrlValid ? null : 'URL inválido.',
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.play_circle_fill, color: lightPurpleText),
                              onPressed: _checkAndPlayUrl,
                            ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a URL do arquivo de áudio.';
                      }
                      // Adiciona a validação de formato
                      if (!_isValidUrlFormat(value)) {
                        return 'O formato do URL está incorreto (ex: http://exemplo.com/musica.mp3)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: _saveMusicToFirebase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightPurpleText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Adicionar Música',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

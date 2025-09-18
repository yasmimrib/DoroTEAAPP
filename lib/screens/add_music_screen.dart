// lib/screens/add_music_screen.dart
import 'package:flutter/material.dart';
import 'package:dorotea_app/screens/music_selection_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMusicScreen extends StatefulWidget {
  final String email;

  const AddMusicScreen({super.key, required this.email});

  @override
  State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _audioUrlController = TextEditingController();
  bool _isLoading = false; // Adiciona o estado de carregamento

  Future<void> _addMusic() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Ativa o estado de carregamento
      });

      final String title = _titleController.text.trim();
      final String artist = _artistController.text.trim();
      final String audioUrl = _audioUrlController.text.trim();

      final String email = widget.email;

      // Troque '127.0.0.1' pelo IP do seu servidor real
      const String apiUrl = 'http://127.0.0.1:5000';
      final url = Uri.parse('$apiUrl/add_music/$email');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': title,
            'artist': artist,
            'audio_url': audioUrl,
          }),
        );

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Música adicionada com sucesso!')),
            );
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MusicSelectionScreen(email: widget.email)),
            );
          }
        } else {
          final erro = jsonDecode(response.body)['erro'];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao adicionar música: $erro')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro de conexão. Verifique o servidor.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Desativa o estado de carregamento, independentemente do resultado
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: primaryPurple,
      appBar: AppBar(
        title: const Text('Adicionar Música'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.music_note,
                size: 80.0,
                color: Colors.white,
              ),
              const SizedBox(height: 30.0),

              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título da Música'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o título.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artistController,
                      decoration: const InputDecoration(labelText: 'Artista'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o artista.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _audioUrlController,
                      decoration: const InputDecoration(labelText: 'URL do Arquivo de Áudio'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um URL de áudio válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _addMusic,
                        child: const Text('Adicionar Música'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
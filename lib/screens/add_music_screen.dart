import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:convert';
import 'dart:io';

class AddMusicScreen extends StatefulWidget {
final String email;
const AddMusicScreen({super.key, required this.email});

@override
State<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends State<AddMusicScreen> {
final TextEditingController _titleController = TextEditingController();
final TextEditingController _artistController = TextEditingController();
File? _selectedFile;
String _fileName = 'Nenhum arquivo selecionado';

Future<void> _pickFile() async {
FilePickerResult? result = await FilePicker.platform.pickFiles(
type: FileType.custom,
allowedExtensions: ['mp3'],
);

if (result != null && result.files.single.path != null) {
  setState(() {
    _selectedFile = File(result.files.single.path!);
    _fileName = path.basename(_selectedFile!.path);
  });
} else {
  setState(() {
    _selectedFile = null;
    _fileName = 'Nenhum arquivo selecionado';
  });
}

}

Future<void> _addMusic() async {
if (_selectedFile == null) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Por favor, selecione um arquivo de áudio.')),
);
}
return;
}

final String title = _titleController.text.trim();
final String artist = _artistController.text.trim();
final String userEmail = widget.email.trim();

if (title.isEmpty || artist.isEmpty) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, preencha todos os campos.')),
    );
  }
  return;
}

const String apiUrl = 'http://192.168.0.110:5000/add_music';
// Mude esta linha para remover espaços em branco invisíveis.
debugPrint('Enviando para o servidor o email: ${widget.email}');
final request = http.MultipartRequest('POST', Uri.parse(apiUrl.trim()));

final String? mimeType = lookupMimeType(_selectedFile!.path);

request.files.add(await http.MultipartFile.fromPath(
  'file',
  _selectedFile!.path,
  contentType: mimeType != null ? MediaType.parse(mimeType) : null,
));

request.fields['email'] = userEmail;
request.fields['title'] = title;
request.fields['artist'] = artist;

try {
  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 201) {
    debugPrint('Upload bem-sucedido!');
    debugPrint('Resposta: $responseBody');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Música adicionada com sucesso!')),
      );
    }
    
    Navigator.pop(context);
    
  } else {
    debugPrint('Erro no upload: ${response.statusCode}');
    debugPrint('Corpo do erro: $responseBody');
    if (mounted) {
      final Map<String, dynamic> errorData = json.decode(responseBody);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro: ${errorData['erro'] ?? 'Erro desconhecido'}')),
      );
    }
  }
} catch (e) {
  debugPrint('Erro de conexão: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro de conexão ao enviar a música.')),
    );
  }
}

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
'Adicionar Nova Música',
style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
),
backgroundColor: Theme.of(context).primaryColor,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
TextField(
controller: _titleController,
decoration: const InputDecoration(labelText: 'Título da Música'),
),
const SizedBox(height: 16.0),
TextField(
controller: _artistController,
decoration: const InputDecoration(labelText: 'Nome do Artista'),
),
const SizedBox(height: 16.0),
Row(
children: [
Expanded(
child: Text(
_fileName,
style: const TextStyle(fontStyle: FontStyle.italic),
overflow: TextOverflow.ellipsis,
),
),
TextButton(
onPressed: _pickFile,
child: const Text('Selecionar Arquivo'),
),
],
),
const SizedBox(height: 32.0),
ElevatedButton(
onPressed: _addMusic,
style: ElevatedButton.styleFrom(
backgroundColor: Theme.of(context).primaryColor,
padding: const EdgeInsets.symmetric(vertical: 16.0),
),
child: Text(
'Adicionar Música',
style: GoogleFonts.quicksand(
fontSize: 18, fontWeight: FontWeight.bold),
),
),
],
),
),
);
}
}
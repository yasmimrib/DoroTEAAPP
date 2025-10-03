import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

// O controller VLC é mais robusto para streams RTSP/IP.
late VlcPlayerController _vlcController;

class CameraScreen extends StatefulWidget {
  // Mantendo o construtor original que recebe email (ou outro dado)
  final String email;
  const CameraScreen({super.key, required this.email});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // URL RTSP confirmada. Estamos reintroduzindo a porta 554
  // e testando um caminho mais comum (Streaming/Channels/101) ou (ch0/0)
  // Use a que for mais provável para a sua câmera.
  // Vou usar o caminho original que funcionou no VLC, mas com a porta:
  // static const String _streamUrl = 'rtsp://admin:admin@192.168.40.20:554/live'; // ORIGINAL

  // Tentativa 1: Voltando a porta 554
  // static const String _streamUrl = 'rtsp://admin:admin@192.168.40.20:554/live';

  // Tentativa 2: Usando o caminho 'Streaming/Channels/101'
  static const String _streamUrl = 'rtsp://admin:admin@192.168.40.20:554/live'; // NOVO CAMINHO

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVlcPlayer();
  }

  Future<void> _initializeVlcPlayer() async {
    try {
      // 1. Inicializa o VlcPlayerController
      _vlcController = VlcPlayerController.network(
        _streamUrl,
        hwAcc: HwAcc.full, // Habilita aceleração por hardware para melhor performance
        autoPlay: true,
        // Usando as opções padrão para evitar erros de sintaxe.
        options: VlcPlayerOptions(),
      );

      // 2. Aguarda a inicialização e monitora o estado
      _vlcController.addListener(listenerVlc);

      // Não definimos _isInitialized = true aqui,
      // pois queremos que o listener confirme a conexão.
    } catch (e) {
      print('Erro ao inicializar o VLC Player: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  void listenerVlc() {
    if (!mounted) return;

    // Monitora o estado da conexão
    if (_vlcController.value.isInitialized && _vlcController.value.isPlaying) {
      // O stream está ativo e inicializado
      if (!_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
      }
    } else if (_vlcController.value.hasError) {
      // Captura o erro e mostra
      print('ERRO CRÍTICO NO STREAM VLC: ${_vlcController.value.errorDescription}');
      if (_isInitialized) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
    // Força a reconstrução do widget para mostrar o estado atual (_isInitialized)
    if (_vlcController.value.isBuffering) {
      // Opcional: mostrar status de buffer
    }
  }

  @override
  void dispose() {
    _vlcController.removeListener(listenerVlc);
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera IP - DoroTEA')),
      body: Center(
        child: _isInitialized
            ? Container(
                constraints: const BoxConstraints(
                  maxWidth: 800, // Limita o tamanho para melhor visualização em telas grandes
                ),
                // O VlcPlayer só é carregado se o controller for inicializado com sucesso
                child: VlcPlayer(
                  controller: _vlcController,
                  aspectRatio: 16 / 9, // Ajusta a proporção do seu vídeo
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Tentando conectar ao stream da câmera...', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Text('Verifique a rede, a URL RTSP ou o Firewall.', style: TextStyle(color: Colors.red)),
                ],
              ),
      ),
    );
  }
}
// lib/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para obter o usuário atual
import 'package:cloud_firestore/cloud_firestore.dart'; // Para buscar os dados do Firestore
import 'package:dorotea_app/initial_screen.dart'; // Importe a tela inicial para redirecionar no logout

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Variáveis para armazenar os dados do usuário
  String _fullName = 'Carregando...';
  String _email = 'Carregando...';
  String _bearCode = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Chama a função para carregar os dados ao iniciar a tela
  }

  Future<void> _loadUserProfile() async {
    try {
      // Obter o usuário atualmente logado
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Buscar o documento do usuário no Cloud Firestore usando o UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          // Se o documento existe, atualize o estado com os dados
          setState(() {
            _fullName = userDoc['fullName'] ?? 'Nome não disponível';
            _email = userDoc['email'] ?? 'Email não disponível';
            _bearCode = userDoc['bearCode'] ?? 'Código não disponível';
          });
        } else {
          debugPrint('Documento do usuário não encontrado no Firestore.');
          setState(() {
            _fullName = 'Dados não encontrados';
            _email = currentUser.email ?? 'Email não disponível'; // Pelo menos o email do Auth
            _bearCode = 'Dados não encontrados';
          });
        }
      } else {
        debugPrint('Nenhum usuário logado.');
        setState(() {
          _fullName = 'Não logado';
          _email = 'Não logado';
          _bearCode = 'Não logado';
        });
        // Opcional: Redirecionar para a tela de login se não houver usuário logado
        // if (mounted) {
        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(builder: (context) => const LoginScreen()),
        //     (Route<dynamic> route) => false,
        //   );
        // }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil do usuário: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar dados do perfil.', style: TextStyle(color: Colors.white))),
        );
      }
      setState(() {
        _fullName = 'Erro!';
        _email = 'Erro!';
        _bearCode = 'Erro!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cores do tema, puxadas de main.dart
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;
    final Color textColorOnPrimary = Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white;


    return Scaffold(
      backgroundColor: primaryPurple, // Fundo roxo consistente
      appBar: AppBar(
        title: const Text('DoroTEA'), // Título da AppBar conforme a imagem
        centerTitle: true, // Centraliza o título
        // O ícone de voltar (seta) já é adicionado automaticamente pela AppBar quando há um Navigator.push
      ),
      body: Center(
        child: SingleChildScrollView( // Usar SingleChildScrollView para evitar overflow se o teclado aparecer
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0), // Padding geral
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centraliza os elementos na coluna
            children: <Widget>[
              // Avatar grande com ícone de pessoa (conforme imagem)
              CircleAvatar(
                radius: 70, // Tamanho do círculo
                backgroundColor: Colors.white, // Fundo branco do círculo
                child: Icon(
                  Icons.person,
                  size: 80, // Tamanho do ícone de pessoa
                  color: primaryPurple, // Cor do ícone
                ),
              ),
              const SizedBox(height: 10.0), // Espaço entre o avatar e o nome

              // Nome do usuário
              Text(
                _fullName.toUpperCase(), // Exibir em maiúsculas como na imagem
                style: TextStyle(
                  color: textColorOnPrimary, // Cor do texto branco ou similar
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30.0), // Espaço antes das informações pessoais

              // Título "Informações Pessoais"
              Align( // Alinha o texto à esquerda
                alignment: Alignment.centerLeft,
                child: Text(
                  'Informações Pessoais',
                  style: TextStyle(
                    color: textColorOnPrimary.withOpacity(0.8), // Um pouco mais suave que o nome
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              // Container para as informações (linhas de ícone + texto)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco
                  borderRadius: BorderRadius.circular(10.0), // Borda arredondada
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.person,
                      label: 'Nome:',
                      value: _fullName, // <--- Usando a variável de estado
                      labelColor: primaryPurple,
                      valueColor: Colors.grey[800]!,
                    ),
                    _buildDivider(), // Divisor entre os itens
                    _buildInfoRow(
                      context,
                      icon: Icons.email,
                      label: 'Email:',
                      value: _email, // <--- Usando a variável de estado
                      labelColor: primaryPurple,
                      valueColor: Colors.grey[800]!,
                    ),
                    _buildDivider(), // Divisor
                    _buildInfoRow(
                      context,
                      icon: Icons.pets, // Ícone de urso
                      label: 'Código do urso:',
                      value: _bearCode, // <--- Usando a variável de estado
                      labelColor: primaryPurple,
                      valueColor: Colors.grey[800]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0), // Espaço antes do botão de Logout

              // Botão de Logout
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco para o botão de logout
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: InkWell( // InkWell para tornar o container clicável e ter efeito ripple
                  onTap: () async { // <--- Mude para async
                    debugPrint('Botão Logout clicado!');
                    try {
                      await FirebaseAuth.instance.signOut(); // Desloga do Firebase
                      if (mounted) { // Verifica se o widget ainda está montado antes de usar o contexto
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deslogado com sucesso!', style: TextStyle(color: Colors.white))),
                        );
                        // Redireciona para a tela inicial/login e remove todas as rotas anteriores
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const InitialScreen()), // Volta para a tela inicial
                          (Route<dynamic> route) => false, // Remove todas as rotas da pilha
                        );
                      }
                    } catch (e) {
                      debugPrint('Erro ao fazer logout: $e');
                      if (mounted) { // Verifica se o widget ainda está montado antes de usar o contexto
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao deslogar. Tente novamente.', style: TextStyle(color: Colors.white))),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(10.0), // Borda arredondada para o InkWell
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaça ícone/texto e seta
                      children: [
                        Row(
                          children: [
                            Icon(Icons.logout, color: primaryPurple), // Ícone de logout
                            const SizedBox(width: 15.0),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: primaryPurple,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios, color: primaryPurple, size: 18.0), // Seta para frente
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir cada linha de informação do perfil (com ícone)
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: labelColor), // Ícone
          const SizedBox(width: 15.0),
          Expanded( // Expanded para garantir que o texto não ultrapasse
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para o divisor entre as informações
  Widget _buildDivider() {
    return Container(
      height: 1.0,
      color: Colors.grey[200], // Cor do divisor
      margin: const EdgeInsets.symmetric(horizontal: 20.0), // Margem para não ir até as bordas
    );
  }
}
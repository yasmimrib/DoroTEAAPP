// lib/signup_screen.dart
import 'package:flutter/material.dart';
// import 'package:doroteia_login_app/login_screen.dart'; // Você pode querer voltar para a tela de login após o cadastro
import 'package:dorotea_app/home_screen.dart'; // Importar a tela principal do Doroteia
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importe o Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe o Cloud Firestore


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bearCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bearCodeController.dispose();
    super.dispose();
  }

  void _handleSignUp() async { // <--- Mude para async
  if (_formKey.currentState!.validate()) {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String bearCode = _bearCodeController.text.trim(); // Pode ser opcional

    try {
      // 1. Criar usuário com email e senha usando Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Salvar informações adicionais do usuário no Cloud Firestore
      // O UID (User ID) do Firebase Auth é o identificador único do usuário
      // e é uma boa prática usá-lo como ID do documento no Firestore.
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'bearCode': bearCode, // Salva mesmo que seja vazio se o campo não tiver validação
        'createdAt': Timestamp.now(), // Para registrar quando o usuário foi criado
      });

      // Se chegou até aqui, o cadastro e o salvamento no Firestore foram bem-sucedidos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro efetuado com sucesso!', style: TextStyle(color: Colors.white))),
      );

      // Após o cadastro bem-sucedido, você pode:
      // a) Redirecionar para a tela de login para que o usuário se autentique:
      // Navigator.pop(context); // Volta para a tela anterior (LoginScreen)

      // b) Ou, se você quer que ele já esteja logado e vá para a HomeScreen:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Este email já está em uso para outra conta.';
      } else {
        message = 'Erro ao cadastrar: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: TextStyle(color: Colors.white))),
      );
      debugPrint('Erro de cadastro Firebase: ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado. Tente novamente.', style: TextStyle(color: Colors.white))),
      );
      debugPrint('Erro geral de cadastro: $e');
    }
  }
}

  @override
  Widget build(BuildContext context) {
    // As cores do tema serão puxadas de main.dart
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary; // Cor do texto de destaque

    return Scaffold(
      backgroundColor: primaryPurple, // Fundo roxo consistente
      appBar: AppBar(
        title: const Text('Cadastro'), // Título da AppBar conforme a imagem
        // O estilo da AppBar (cor, texto branco) virá do main.dart
      ),
      body: Center(
        child: SingleChildScrollView(
          // Adiciona padding para o conteúdo não ficar colado nas bordas
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Ursinho pequeno
              Image.asset(
                'assets/bear_logo.png',
                height: 80.0, // Tamanho consistente com a tela de Login
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20.0),

              // Texto "É um prazer ter você aqui!"
              Text(
                'É um prazer ter você aqui!\nPreencha os campos com atenção.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40.0), // Espaçamento antes dos campos

              // Container para os campos de entrada e botão (fundo branco)
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco dos campos
                  borderRadius: BorderRadius.circular(20.0), // Borda arredondada
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os elementos
                    children: <Widget>[
                      // Campo "Nome completo"
                      TextFormField(
                        controller: _fullNameController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo:',
                          hintText: 'Digite seu nome completo',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu nome completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo de E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email:',
                          hintText: 'Digite seu email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo de Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha:',
                          hintText: 'Crie sua senha',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo de Confirmar Senha
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirme a senha:',
                          hintText: 'Confirme sua senha',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Campo "Código do Urso" (sem validação)
                      TextFormField(
                        controller: _bearCodeController,
                        keyboardType: TextInputType.number, // Sugere teclado numérico
                        decoration: const InputDecoration(
                          labelText: 'Código do urso:',
                          hintText: 'Digite o código do seu urso (opcional)',
                        ),
                        // NENHUM 'validator' para este campo, conforme solicitado.
                      ),
                      const SizedBox(height: 24.0),

                      // Botão "CADASTRAR"
                      ElevatedButton(
                        onPressed: _handleSignUp,
                        child: const Text('CADASTRAR'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
}
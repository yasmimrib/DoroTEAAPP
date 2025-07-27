// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:dorotea_app/signup_screen.dart'; // Importe a tela de cadastro
import 'package:dorotea_app/home_screen.dart'; // Importe a tela principal (Home)
import 'package:firebase_auth/firebase_auth.dart'; // Importe o Firebase Auth


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async { // <--- Mude para async
  if (_formKey.currentState!.validate()) {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // 1. Autenticar usuário com email e senha usando Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Se chegou aqui, o login foi bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login bem-sucedido!', style: TextStyle(color: Colors.white))),
      );

      // Redireciona para a HomeScreen e remove a LoginScreen da pilha
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Nenhum usuário encontrado para este email.';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        message = 'O formato do email é inválido.';
      } else if (e.code == 'network-request-failed') {
        message = 'Erro de conexão: Verifique sua internet.';
      }
      else {
        message = 'Erro ao fazer login: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: TextStyle(color: Colors.white))),
      );
      debugPrint('Erro de login Firebase: ${e.code} - ${e.message}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro inesperado. Tente novamente.', style: TextStyle(color: Colors.white))),
      );
      debugPrint('Erro geral de login: $e');
    }
  }
}
  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cores do tema, puxadas de main.dart
    final Color primaryPurple = Theme.of(context).primaryColor;
    final Color lightPurpleText = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: primaryPurple, // Fundo roxo consistente
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Ursinho pequeno (adaptado da Imagem 2)
              Image.asset(
                'assets/bear_logo.png',
                height: 80.0, // Tamanho consistente com a Imagem 2
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20.0),

              // Texto "Estamos felizes em te ver de novo!"
              Text(
                'Estamos felizes em te ver de novo!',
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
                          hintText: 'Digite sua senha',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha';
                          }
                          if (value.length < 6) {
                            return 'Senha inválida.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Botão "ENTRAR"
                      ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text('ENTRAR'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Espaço entre o container e o botão de cadastro

              // Botão de texto "Cadastrar"
              TextButton(
                onPressed: _navigateToSignUp,
                child: const Text('Cadastrar'),
              ),
              const SizedBox(height: 10.0), // Espaço para "Esqueceu a senha?" (se for adicionar)
              // TextButton(
              //   onPressed: () {
              //     // Lógica para recuperar senha
              //     debugPrint('Esqueceu a senha? clicado!');
              //   },
              //   child: const Text('Esqueceu a senha?'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
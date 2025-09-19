//tela inicial
import 'package:flutter/material.dart';
import 'package:dorotea_app/screens/login_screen.dart'; 

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cores do tema, puxadas de main.dart
    final Color primaryPurple = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: primaryPurple, // Fundo da tela roxo
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Imagem do urso
              Image.asset(
                'assets/bear_logo.png', 
                height: MediaQuery.of(context).size.height * 0.5, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20.0),
              // Texto "DoroTEA"
              Image.asset(
                'assets/dorotea_text.png', 
                height: 80.0, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 50.0), // Espaço antes do botão

              // Botão "VAMOS LÁ!"
              ElevatedButton(
              style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50), // largura, altura
              textStyle: const TextStyle(
              fontSize: 20, // tamanho da fonte
              //fontWeight: FontWeight.bold, // negrito
              fontFamily: 'Roboto', // trocar a fonte
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text('VAMOS LÁ!'),
        ),
            ],
          ),
        ),
      ),
    );
  }
}
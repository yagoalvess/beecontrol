import 'package:abelhas/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeControl',
      theme: ThemeData(
        primaryColor: Colors.amber, // cor principal do app
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber, // afeta AppBar, botões, etc.
          brightness: Brightness.light, // ou Brightness.dark para tema escuro
        ),
        scaffoldBackgroundColor: Colors.yellow[50], // fundo da tela
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber, // cor da AppBar
          foregroundColor: Colors.black, // cor do texto da AppBar
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

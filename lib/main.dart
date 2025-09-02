import 'package:abelhas/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeControl',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber[700]!,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.amber[700],
          // Ícones e títulos em preto
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          // Textos do corpo da tela em preto
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber[700],
          // Ícone do botão em preto
          foregroundColor: Colors.black,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
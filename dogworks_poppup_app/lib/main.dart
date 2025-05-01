import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const PopPupApp());
}

class PopPupApp extends StatelessWidget {
  const PopPupApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PUP-POP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2B3674), // Deep blue
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF5D9C59), // Green
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B3674),
          ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

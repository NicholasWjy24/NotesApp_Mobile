import 'package:flutter/material.dart';
import 'package:nnotes/screen/home/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 185, 149, 102),
            onPrimary: const Color.fromARGB(255, 185, 149, 102),
            onSecondary: const Color.fromARGB(255, 247, 216, 176)),
        textTheme: GoogleFonts.quintessentialTextTheme(),
        scaffoldBackgroundColor: const Color.fromARGB(255, 224, 201, 166),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

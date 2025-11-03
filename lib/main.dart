import 'package:flutter/material.dart';
import 'package:saa/login_screen.dart';

void main() {
  runApp(const SAAApp());
}

class SAAApp extends StatelessWidget {
  const SAAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAA',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

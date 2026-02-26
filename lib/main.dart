import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AssetInventoryApp());
}

class AssetInventoryApp extends StatelessWidget {
  const AssetInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixed Asset Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: LoginScreen(),
    );
  }
}
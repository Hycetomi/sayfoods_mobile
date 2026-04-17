import 'package:flutter/material.dart';

class EditAdminProfileScreen extends StatelessWidget {
  const EditAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Admin Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFCFCFC), // bgColor
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(child: Text('Admin Profile Edit Placeholder', style: TextStyle(color: Colors.grey))),
    );
  }
}

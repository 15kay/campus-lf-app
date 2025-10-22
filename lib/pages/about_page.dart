import 'package:flutter/material.dart';
import 'manual_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campus Lost & Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Purpose: A digital platform for WSU students to report, find, and recover lost items around campus.'),
            const SizedBox(height: 8),
            const Text('Developer: Kgaugelo Mmakola'),
            const SizedBox(height: 4),
            const Text('Contact: info@dsinventech.com'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Open User Manual'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
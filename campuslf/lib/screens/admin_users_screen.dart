import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Users'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: AuthService.isAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;
          if (!isAdmin) {
            return const Center(
              child: Text('Admin access required'),
            );
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final name = (data['name'] ?? '') as String;
                  final email = (data['email'] ?? '') as String;
                  final isAdminFlag = (data['isAdmin'] ?? false) as bool;
                  final created = data['createdAt'];
                  String createdStr = '';
                  if (created is Timestamp) {
                    createdStr = created.toDate().toLocal().toString();
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdminFlag ? Colors.redAccent : Colors.blueGrey,
                      child: Icon(isAdminFlag ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white),
                    ),
                    title: Text(name.isNotEmpty ? name : 'Unnamed'),
                    subtitle: Text(email),
                    trailing: Text(createdStr, style: const TextStyle(fontSize: 12)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
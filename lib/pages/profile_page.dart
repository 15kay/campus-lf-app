import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app.dart';

class ProfilePage extends StatefulWidget {
  final void Function(UserProfile) onProfileUpdated;
  const ProfilePage({super.key, required this.onProfileUpdated});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name = TextEditingController(text: '');
  late final TextEditingController _studentNumber = TextEditingController(text: '');
  late final TextEditingController _email = TextEditingController(text: '');
  String _gender = 'Other';
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isSaving = false;

  // Fallbacks when fields left empty
  String _initialName = '';
  String _initialStudentNumber = '';
  String _initialEmail = '';

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email.text = user.email ?? '';
      _initialEmail = user.email ?? '';
      _initialName = user.displayName ?? (user.email?.split('@').first ?? 'User');
    }
    
    await _loadProfile();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final p = await loadUserProfile();
      if (!mounted) return;
      
      if (p != null) {
        setState(() {
          _name.text = p.name;
          _studentNumber.text = p.studentNumber;
          if (_email.text.isEmpty) _email.text = p.email;
          _gender = p.gender.isNotEmpty ? p.gender : _gender;
          _imageBytes = p.profileImageBytes;
          _initialName = p.name.isNotEmpty ? p.name : _initialName;
          _initialStudentNumber = p.studentNumber.isNotEmpty ? p.studentNumber : _initialStudentNumber;
          _initialEmail = p.email.isNotEmpty ? p.email : _initialEmail;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save profile changes.')));
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = UserProfile(
        uid: uid,
        name: _name.text.trim().isEmpty ? _initialName : _name.text.trim(),
        studentNumber: _studentNumber.text.trim().isEmpty ? _initialStudentNumber : _studentNumber.text.trim(),
        email: _email.text.trim().isEmpty ? _initialEmail : _email.text.trim(),
        gender: _gender,
        profileImageBytes: _imageBytes,
      );
      
      await saveUserProfile(updated);
      widget.onProfileUpdated(updated);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      // Not authenticated: redirect to LoginPage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your profile...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                child: _imageBytes == null ? const Icon(Icons.person, size: 48) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(onPressed: _pickProfileImage, child: const Text('Change Profile Picture')),
                    const SizedBox(height: 8),
                    Text(_email.text, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('UID: ${uid.substring(0, 8)}...', 
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Personal Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _studentNumber, decoration: const InputDecoration(labelText: 'Student number', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
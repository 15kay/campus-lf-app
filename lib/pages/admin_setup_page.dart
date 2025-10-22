import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _createAdminUser() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty ||
        _studentNumberController.text.isEmpty) {
      setState(() {
        _message = 'Please fill in all fields';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // Create user account
      final user = await FirebaseService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Create user profile with admin status
        final userProfile = UserProfile(
          uid: user.uid,
          name: _nameController.text.trim(),
          studentNumber: _studentNumberController.text.trim(),
          email: _emailController.text.trim(),
          gender: 'Not specified',
          phone: '',
          isAdmin: true, // Set as admin
        );

        // Save user profile
        await FirebaseService.saveUserProfile(userProfile);

        setState(() {
          _message = 'Admin user created successfully!\nEmail: ${_emailController.text}\nYou can now sign in with admin privileges.';
          _isError = false;
          _isLoading = false;
        });

        // Clear form
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _studentNumberController.clear();

      } else {
        setState(() {
          _message = 'Failed to create user account';
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _makeCurrentUserAdmin() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final currentUser = FirebaseService.getCurrentUser();
      if (currentUser != null) {
        await FirebaseService.setUserAdminStatus(currentUser.uid, true);
        setState(() {
          _message = 'Current user (${currentUser.email}) is now an admin!';
          _isError = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'No user is currently signed in';
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Setup Options',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF075E54),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choose one of the options below to set up admin access:',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Make current user admin
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Option 1: Make Current User Admin',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'If you\'re already signed in, click this button to give yourself admin privileges.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _makeCurrentUserAdmin,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Make Me Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Option 2: Create new admin user
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Option 2: Create New Admin User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Create a new user account with admin privileges.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _studentNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Student Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createAdminUser,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create Admin User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF075E54),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                    border: Border.all(
                      color: _isError ? Colors.red : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: TextStyle(
                      color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. After creating an admin user, sign out and sign in with the admin account\n'
                      '2. Look for "Admin Dashboard" in the menu (three dots)\n'
                      '3. Use the admin dashboard to manage users and reports\n'
                      '4. You can promote other users to admin from the Users tab',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
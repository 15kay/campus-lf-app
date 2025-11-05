import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/two_factor_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  bool _isEnabled = false;
  List<String> _backupCodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTwoFactorStatus();
  }

  Future<void> _loadTwoFactorStatus() async {
    final isEnabled = await TwoFactorService.isTwoFactorEnabled();
    final backupCodes = await TwoFactorService.getBackupCodes();
    
    setState(() {
      _isEnabled = isEnabled;
      _backupCodes = backupCodes;
    });
  }

  Future<void> _toggleTwoFactor() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isEnabled) {
        await TwoFactorService.disableTwoFactor();
        setState(() {
          _isEnabled = false;
          _backupCodes = [];
        });
        _showSnackBar('Two-factor authentication disabled', Colors.orange);
      } else {
        final codes = await TwoFactorService.enableTwoFactor();
        setState(() {
          _isEnabled = true;
          _backupCodes = codes;
        });
        _showBackupCodesDialog(codes);
      }
    } catch (e) {
      _showSnackBar('Error updating two-factor authentication', Colors.red);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _regenerateBackupCodes() async {
    setState(() => _isLoading = true);
    
    try {
      final newCodes = await TwoFactorService.regenerateBackupCodes();
      setState(() => _backupCodes = newCodes);
      _showBackupCodesDialog(newCodes);
    } catch (e) {
      _showSnackBar('Error generating backup codes', Colors.red);
    }
    
    setState(() => _isLoading = false);
  }

  void _showBackupCodesDialog(List<String> codes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Backup Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save these backup codes in a secure location. Each code can only be used once.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: codes.map((code) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codes.join('\n')));
              _showSnackBar('Backup codes copied to clipboard', Colors.green);
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _isEnabled ? Colors.green : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                _isEnabled ? Icons.security : Icons.security_outlined,
                color: _isEnabled ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Secure Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an extra layer of security to your WSU Lost & Found account',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: _isEnabled ? Colors.green : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Two-Factor Authentication',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _isEnabled ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isEnabled ? Colors.green : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isEnabled,
                        onChanged: _isLoading ? null : (value) => _toggleTwoFactor(),
                        thumbColor: WidgetStateProperty.all(Colors.green),
                      ),
                    ],
                  ),
                  if (_isEnabled) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Backup Codes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${_backupCodes.length} backup codes remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _showBackupCodesDialog(_backupCodes),
                            child: const Text('View Codes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _regenerateBackupCodes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Regenerate'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• When enabled, you\'ll receive a verification code via email\n'
                    '• Enter the code along with your password to sign in\n'
                    '• Use backup codes if you can\'t access your email\n'
                    '• Each backup code can only be used once',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
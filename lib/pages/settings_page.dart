import 'package:flutter/material.dart';
import 'admin_setup_page.dart';

class SettingsPage extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  const SettingsPage({super.key, required this.themeMode, required this.onThemeModeChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how the app looks. System uses your device theme.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_brightness)),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) => onThemeModeChanged(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(icon: const Icon(Icons.check), onPressed: () {}, label: const Text('Primary Action')),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.tune),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(side: BorderSide(color: cs.primary)),
                        label: const Text('Outlined'),
                      ),
                      TextButton.icon(icon: const Icon(Icons.more_horiz), onPressed: () {}, label: const Text('Text')), 
                      const Chip(label: Text('Chip')), 
                      Chip(label: Text('Accent'), avatar: CircleAvatar(backgroundColor: cs.secondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const TextField(decoration: InputDecoration(labelText: 'Sample input')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('Notifications (optional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: const Text('Push notifications can be enabled when Firebase Cloud Messaging is configured.'),
              trailing: Icon(Icons.info_outline, color: cs.secondary),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text('Admin Setup', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              subtitle: const Text('Set up the first admin user or promote existing users to admin.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminSetupPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ManualPage extends StatelessWidget {
  const ManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        backgroundColor: const Color(0xFF2E7D32), // Professional green
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildSectionHeader('📱 Welcome to Campus Lost & Found', Icons.home),
            const SizedBox(height: 8),
            _buildDescription(
              'Your comprehensive solution for reporting, finding, and recovering lost items on campus. '
              'Connect with fellow students through real-time messaging, video calls, and more!'
            ),

            const SizedBox(height: 24),
            
            // Getting Started
            _buildSectionHeader('🚀 Getting Started', Icons.play_arrow),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Download and install the Campus Lost & Found app',
              'Sign in with your campus credentials or register a new account',
              'Complete your profile with contact information',
              'Grant necessary permissions (camera, microphone, storage)',
              'You\'re ready to start using all features!'
            ]),

            const SizedBox(height: 24),

            // Report an Item
            _buildSectionHeader('📝 Reporting Lost/Found Items', Icons.add_circle),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Tap "Report Item" from the main navigation',
              'Select item type: Lost or Found',
              'Fill in detailed item description and category',
              'Add location where item was lost/found',
              'Select the date when incident occurred',
              'Take a photo or upload from gallery',
              'Add any additional notes or contact preferences',
              'Tap "Submit" to publish your report'
            ]),
            _buildTip('💡 Tip: Include as many details as possible to help others identify your item!'),

            const SizedBox(height: 24),

            // Search & Browse
            _buildSectionHeader('🔍 Searching for Items', Icons.search),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Navigate to the Search page',
              'Use keywords to search item descriptions',
              'Filter by categories (Electronics, Clothing, Books, etc.)',
              'Filter by date range or location',
              'Tap on any result to view full details',
              'Contact the reporter directly through messaging'
            ]),

            const SizedBox(height: 24),

            // Enhanced Messaging
            _buildSectionHeader('💬 Professional Messaging', Icons.chat),
            const SizedBox(height: 8),
            _buildDescription('Our enhanced messaging system provides a complete communication experience:'),
            const SizedBox(height: 12),
            
            _buildSubSection('📱 Text Messaging', [
              'Send and receive messages in real-time',
              'See delivery status: ⏰ Sending → ✓ Delivered → ✓✓ Read',
              'View typing indicators when others are typing',
              'Online status shows when users are active'
            ]),

            _buildSubSection('🎤 Voice Messages', [
              'Hold the microphone button to record voice messages',
              'Release to send, swipe to cancel',
              'Tap voice messages to play/pause',
              'Voice messages are automatically uploaded and synced'
            ]),

            _buildSubSection('📷 Image Sharing', [
              'Tap the camera icon to take a photo',
              'Tap the attachment icon to select from gallery',
              'Images are compressed and uploaded automatically',
              'Tap images in chat to view full size'
            ]),

            const SizedBox(height: 24),

            // Video & Voice Calls
            _buildSectionHeader('📹 Video & Voice Calls', Icons.videocam),
            const SizedBox(height: 8),
            _buildDescription('Make real-time video and voice calls using WebRTC technology:'),
            const SizedBox(height: 12),

            _buildSubSection('📞 Starting a Call', [
              'Open any conversation',
              'Tap the video camera icon for video calls',
              'Tap the phone icon for voice calls',
              'Wait for the other person to accept',
              'Enjoy high-quality real-time communication!'
            ]),

            _buildSubSection('🎛️ Call Controls', [
              'Mute/unmute your microphone',
              'Turn your camera on/off during video calls',
              'End call button to terminate the session',
              'Call duration is automatically tracked',
              'Call history is saved in your conversation'
            ]),

            _buildTip('💡 Tip: Ensure you have a stable internet connection for the best call quality!'),

            const SizedBox(height: 24),

            // My Reports Management
            _buildSectionHeader('📋 Managing Your Reports', Icons.list_alt),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Access "My Reports" from the main menu',
              'View all your submitted lost and found reports',
              'Tap "Edit" to update item details or status',
              'Mark items as "Found" or "Returned" when resolved',
              'Delete reports that are no longer needed',
              'Track engagement and messages from other users'
            ]),

            const SizedBox(height: 24),

            // AI Agent
            _buildSectionHeader('🧠 AI Agent', Icons.psychology),
            const SizedBox(height: 8),
            _buildDescription('Get intelligent assistance with our advanced AI agent:'),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Access the AI agent from the assistant button',
              'Get contextual help based on your current activity',
              'Use quick actions for common tasks like reporting and searching',
              'Receive smart suggestions tailored to your usage patterns',
              'Get guided assistance for complex processes',
              'Automate routine tasks with intelligent workflows'
            ]),

            const SizedBox(height: 24),

            // Settings & Customization
            _buildSectionHeader('⚙️ Settings & Customization', Icons.settings),
            const SizedBox(height: 8),
            _buildStepByStep([
              'Access Settings from the main menu',
              'Switch between Light and Dark themes',
              'Manage notification preferences',
              'Update your profile information',
              'Configure privacy settings',
              'Manage app permissions'
            ]),

            const SizedBox(height: 24),

            // Troubleshooting
            _buildSectionHeader('🔧 Troubleshooting & FAQ', Icons.help),
            const SizedBox(height: 8),
            
            _buildSubSection('❓ Common Issues', [
              'Q: Video calls not working?\nA: Check camera/microphone permissions and internet connection',
              'Q: Messages not sending?\nA: Verify internet connection and try again',
              'Q: Can\'t upload images?\nA: Check storage permissions and available space',
              'Q: App running slowly?\nA: Close other apps and restart the Campus LF app'
            ]),

            _buildSubSection('📞 Contact Support', [
              'Email: support@campuslf.edu',
              'Phone: (555) 123-4567',
              'Office Hours: Mon-Fri 9AM-5PM',
              'Emergency: Contact campus security directly'
            ]),

            const SizedBox(height: 24),

            // Tips for Success
            _buildSectionHeader('🌟 Tips for Success', Icons.lightbulb),
            const SizedBox(height: 8),
            _buildTipsList([
              'Be detailed in your item descriptions',
              'Include clear, well-lit photos',
              'Respond promptly to messages',
              'Use video calls for item verification',
              'Update your reports when items are found',
              'Be respectful in all communications',
              'Check the app regularly for new matches'
            ]),

            const SizedBox(height: 32),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    '🎓 Campus Lost & Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connecting students, recovering memories.\nVersion 2.0 - Enhanced with real-time communication',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24), // Professional green
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32), // Professional green
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }

  Widget _buildStepByStep(List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32), // Professional green
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32), // Professional green
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 16)), // Professional green
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32), width: 1), // Professional green
      ),
      child: Text(
        tip,
        style: const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Color(0xFF2E7D32), // Professional green
        ),
      ),
    );
  }

  Widget _buildTipsList(List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.map((tip) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⭐ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
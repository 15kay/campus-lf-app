import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigator.dart';
import 'screens/dark_mode_screen.dart';
import 'services/auth_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.success('Firebase initialized successfully');
    if (kDebugMode) {
      final cfg = DefaultFirebaseOptions.currentPlatform;
      Logger.debug('Firebase Config: ${cfg.projectId}');
    }
  } catch (e) {
    Logger.error('Firebase initialization failed: $e');
    // Continue anyway for development
  }
  
  runApp(const CampusLostFoundApp());
}

class CampusLostFoundApp extends StatelessWidget {
  const CampusLostFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..loadTheme(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'WSU Campus Lost & Found',
            theme: themeProvider.lightTheme,
            themeMode: ThemeMode.light,
            home: FutureBuilder<bool>(
              future: AuthService.isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }
                return snapshot.data == true ? const MainNavigator() : const AuthScreen();
              },
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
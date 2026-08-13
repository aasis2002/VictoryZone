import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/team_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    
    // Initialize Notifications
    await NotificationService.initialize();

    // Attempt to seed data, but don't fail if permissions are restricted
    try {
      await FirestoreService().initializeApp();
    } catch (e) {
      debugPrint("Firestore Seed Warning: $e");
    }
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: VictoryZoneApp(isFirebaseInitialized: firebaseInitialized),
    ),
  );
}

class VictoryZoneApp extends StatelessWidget {
  final bool isFirebaseInitialized;
  const VictoryZoneApp({super.key, required this.isFirebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Victory Zone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isFirebaseInitialized 
          ? const AuthWrapper() 
          : const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "Firebase could not be initialized. \n\nPlease ensure you have added 'google-services.json' to 'android/app/' and configured your project correctly.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If user is logged in, show Home, otherwise show Login
    if (authProvider.userModel != null) {
      // Save FCM Token
      NotificationService.saveToken(authProvider.userModel!.uid);
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}

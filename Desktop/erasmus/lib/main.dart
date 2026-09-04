import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/information_screen.dart';
import 'screens/home_screen.dart';
import 'models/simulation_data.dart';

const String _kHasSeenInformationScreen = 'has_seen_information_screen';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SimulationData(),
      child: const ErasmusApp(),
    ),
  );
}

class ErasmusApp extends StatelessWidget {
  const ErasmusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Erasmus+ Simülasyon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LaunchGate(),
    );
  }
}

class LaunchGate extends StatelessWidget {
  const LaunchGate({super.key});

  Future<bool> _hasSeenInformationScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenInformationScreen) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenInformationScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSeenInformationScreen = snapshot.data ?? false;

        if (hasSeenInformationScreen) {
          return const HomeScreen();
        }

        return const InformationScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _waitForAuthLoad();
  }

  Future<void> _waitForAuthLoad() async {
    final authProvider = context.read<AuthProvider>();
    print('SplashScreen: Waiting for authProvider to load...');
    bool timedOut = false;
    await Future.any([
      Future.doWhile(() async {
        if (!authProvider.isLoading) return false;
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      }),
      Future.delayed(const Duration(seconds: 5)).then((_) => timedOut = true),
    ]);
    print('SplashScreen: Done waiting. timedOut=$timedOut, isAuthenticated=${authProvider.isAuthenticated}');
    await Future.delayed(const Duration(milliseconds: 300)); // For splash effect
    if (!timedOut && authProvider.isAuthenticated) {
      print('SplashScreen: Navigating to /home');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      print('SplashScreen: Navigating to /welcome');
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paynote/main.dart';
import 'package:paynote/MainPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    checkBiometricAndNavigate();
  }

  Future<void> checkBiometricAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final canCheckBiometrics = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();
    final savedUsername = await secureStorage.read(key: 'username');
    final savedPassword = await secureStorage.read(key: 'password');

    if (!mounted) return;

    if (canCheckBiometrics &&
        isDeviceSupported &&
        savedUsername != null &&
        savedPassword != null) {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // If biometric is successful, auto-login and go to MainPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
        return;
      }
    }

    // If biometric fails or not available or no saved credentials, go to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'PayNote'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.moneyBill1Wave,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "PayNote",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

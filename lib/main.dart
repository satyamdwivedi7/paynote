import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:paynote/splashscreen.dart';
import 'package:paynote/register.dart';
import 'package:paynote/MainPage.dart';
import 'package:paynote/helpers/routeobserver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayNote',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();

  bool _isBiometricAvailable = false;
  String? savedUsername;
  String? savedPassword;

  @override
  void initState() {
    super.initState();
    checkBiometricAvailability();
    loadSavedCredentials();
  }

  Future<void> checkBiometricAvailability() async {
    final bool canCheck = await auth.canCheckBiometrics;
    final bool isDeviceSupported = await auth.isDeviceSupported();
    setState(() {
      _isBiometricAvailable = canCheck && isDeviceSupported;
    });
  }

  Future<void> loadSavedCredentials() async {
    savedUsername = await secureStorage.read(key: 'username');
    savedPassword = await secureStorage.read(key: 'password');
  }

  Future<void> authenticateAndLogin() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        if (savedUsername != null && savedPassword != null) {
          userController.text = savedUsername!;
          passwordController.text = savedPassword!;
          await login();
        } else {
          if (!mounted) return;
          Flushbar(
            title: "No Saved Credentials",
            message: "No saved username/password found.",
            flushbarPosition: FlushbarPosition.TOP,
            icon: const Icon(Icons.info, color: Colors.blue),
            duration: const Duration(seconds: 3),
          ).show(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Flushbar(
        title: "Authentication Failed",
        message: "Biometric authentication failed: ${e.toString()}",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  Future<void> login() async {
    final String username = userController.text.trim();
    final String password = passwordController.text.trim();
    final baseUri = dotenv.env['BASE_URI'];

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all the fields.")),
      );
      return;
    }

    if (baseUri == null || baseUri.isEmpty) {
      Flushbar(
        title: "Configuration Error",
        message: "BASE_URI is not defined in the .env file",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 3),
      ).show(context);
      return;
    }

    final url = Uri.parse("$baseUri/user/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('message') && data.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('userId', data['userId']);

          await secureStorage.write(key: 'username', value: username);
          await secureStorage.write(key: 'password', value: password);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        } else {
          throw Exception("Unexpected response format.");
        }
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        Flushbar(
          title: "Login Failed",
          message: data['message'] ?? "Invalid credentials",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      if (!mounted) return;
      Flushbar(
        title: "Error",
        message: "An error occurred: ${e.toString()}",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(11.0),
        child: ListView(
          children: [
            const SizedBox(height: 50),
            const Center(
              child: Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: userController,
                    autofillHints: const [AutofillHints.username],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.login),
                      labelText: "Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    obscuringCharacter: "*",
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.password),
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.blueGrey,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Login", style: TextStyle(fontSize: 15)),
              ),
            ),
            if (_isBiometricAvailable) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text("Login with Biometrics"),
                  onPressed: authenticateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.blueGrey,
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Register()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shadowColor: Colors.blueGrey,
                  elevation: 7,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Register", style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

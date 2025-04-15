import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:paynote/SplashScreen.dart';
import 'package:paynote/register.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before any async calls in main
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayNote',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
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
          if (!mounted) return;
          Flushbar(
            title: "Login Successful",
            message: data['message'],
            flushbarPosition: FlushbarPosition.TOP,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 3),
          ).show(context);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
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
    } finally {
      userController.clear();
      passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        title: Text(widget.title),
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
            TextField(
              controller: userController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.login),
                labelText: "username",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              controller: passwordController,
              obscuringCharacter: "*",
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.password),
                labelText: "password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
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

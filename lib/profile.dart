import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paynote/main.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isLoading = true;
  String username = "";
  String email = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    getUserInfo(); // Fetch user info when the page loads
  }

  Future<void> getUserInfo() async {
    final baseUri = dotenv.env['BASE_URI'];

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

    final url = Uri.parse("$baseUri/user/info");

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('userId');
      final String? token = prefs.getString('token');

      if (userId == null || token == null) {
        Flushbar(
          title: "Authentication Error",
          message: "User is not logged in. Please log in again.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.warning, color: Colors.orange),
          duration: const Duration(seconds: 3),
        ).show(context);
        return;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          username = data['username'] ?? "";
          email = data['email'] ?? "";
          phone = data['phone'] ?? "";
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        Flushbar(
          title: "Error",
          message: errorData['message'] ?? "Failed to fetch user info.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      Flushbar(
        title: "Error",
        message: "An unexpected error occurred: ${e.toString()}",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data from SharedPreferences
    if (!mounted) return; // Check if the widget is still mounted
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(title: "PayNote")),
      (route) => false,
    );
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
        title: const Text("Profile"),
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Username
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Phone Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 20, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 171, 14, 3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 10,
                          shadowColor: const Color.fromARGB(255, 125, 114, 114),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:paynote/profile.dart';
import 'package:paynote/addtransaction.dart';// Assuming you have this
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoading = true;
  int totalBorrowed = 0;
  int totalLent = 0;
  List<dynamic> borrowed = [];
  List<dynamic> lent = [];

  Future<void> getContacts() async {
    final baseUri = dotenv.env['BASE_URI'];

    if (baseUri == null || baseUri.isEmpty) {
      if (!mounted) return;
      Flushbar(
        title: "Configuration Error",
        message: "BASE_URI is not defined in .env",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 3),
      ).show(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
      Flushbar(
        title: "Authentication Error",
        message: "Token not found. Please log in again.",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 3),
      ).show(context);
      return;
    }

    final response = await http.get(
      Uri.parse("$baseUri/contact/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        totalBorrowed = data['totalBorrowed'] ?? 0;
        totalLent = data['totalLent'] ?? 0;
        borrowed = data['borrowed'] ?? [];
        lent = data['lent'] ?? [];
        isLoading = false;
      });
    } else {
      final errorData = jsonDecode(response.body);
      if (!mounted) return;
      Flushbar(
        title: "Error",
        message: errorData['message'] ?? "Failed to load contacts.",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 3),
      ).show(context);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildSummaryCard("I owe", totalBorrowed, Colors.red),
                    const SizedBox(height: 10),
                    ...borrowed.map(
                      (contact) => _buildContactTile(contact, "borrowed"),
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard("I am owed", totalLent, Colors.green),
                    const SizedBox(height: 10),
                    ...lent.map(
                      (contact) => _buildContactTile(contact, "lent"),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard(String title, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            amount.toString(),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(dynamic contact, String transactionType) {
    final name = contact['name'] ?? "Unknown";
    final phone = contact['phone'] ?? "No phone number";
    final amount =
        transactionType == "borrowed"
            ? contact['totalBorrowed'] ?? 0
            : contact['totalLent'] ?? 0;
    final color = transactionType == "borrowed" ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddTransaction(
                    phone: phone,
                    contactName: name,
                    type: transactionType,
                    amount: amount,
                  ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 196, 196, 196),
          child: Text(name[0].toUpperCase()),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(phone),
        trailing: Text(
          amount.toString(),
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

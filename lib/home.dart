import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:paynote/helpers/function.dart';
import 'package:paynote/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/nav.dart';
import 'package:paynote/addtransaction.dart';
import 'package:paynote/history.dart';

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

  final int _selectedIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      // Stay on the Home page
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const History()),
      );
    }
  }

  Future<void> getContacts() async {
    final baseUri = dotenv.env['BASE_URI'];

    if (baseUri == null || baseUri.isEmpty) {
      if (!mounted) return; // Ensure the widget is still mounted
      Flushbar(
        title: "Configuration Error",
        message: "BASE_URI is not defined in the .env file",
        flushbarPosition: FlushbarPosition.TOP,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 3),
      ).show(context);
      return;
    }

    final url = Uri.parse("$baseUri/contact/");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (!mounted) return; // Ensure the widget is still mounted
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
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return; // Ensure the widget is still mounted
        setState(() {
          totalBorrowed = data['totalBorrowed'] ?? 0;
          totalLent = data['totalLent'] ?? 0;
          borrowed = data['borrowed'] ?? [];
          lent = data['lent'] ?? [];
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return; // Ensure the widget is still mounted
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
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      Flushbar(
        title: "Error",
        message: "An unexpected error occurred: ${e.toString()}",
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("PayNote"),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              },
              icon: const Icon(Icons.account_circle, size: 30),
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    // Total Borrowed Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "I owe",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalBorrowed.toString(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Borrowed Contacts
                    ...borrowed.map((contact) {
                      final name = contact['name'] ?? "Unknown";
                      final phone = contact['phone'] ?? "No phone number";
                      final totalBorrowed = contact['totalBorrowed'] ?? 0;
                      final transactionType = "borrowed";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddTransaction(
                                      phone: phone,
                                      contactName: name,
                                      type: transactionType,
                                      amount: totalBorrowed,
                                    ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color.fromARGB(
                              255,
                              196,
                              196,
                              196,
                            ),
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            phone,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Text(
                            totalBorrowed.toString(),
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Total Lent Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "I am owed",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalLent.toString(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lent Contacts
                    ...lent.map((contact) {
                      final name = contact['name'] ?? "Unknown";
                      final phone = contact['phone'] ?? "No phone number";
                      final totalLent = contact['totalLent'] ?? 0;
                      final transactionType = "lent";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddTransaction(
                                      phone: phone,
                                      contactName: name,
                                      type: transactionType,
                                      amount: totalLent,
                                    ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color.fromARGB(
                              255,
                              196,
                              196,
                              196,
                            ),
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            phone,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Text(
                            totalLent.toString(),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => pickContact(context),

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const AddContact(),
        //   ),
        //);
        child: const Icon(Icons.add, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Nav(onTap: _onNavTap, selectedIndex: _selectedIndex),
    );
  }
}

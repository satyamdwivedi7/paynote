import 'package:flutter/material.dart';
import 'package:paynote/widgets/nav.dart';
import 'package:paynote/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paynote/profile.dart';
import 'package:paynote/widgets/bottomsheet.dart';
import 'package:get/get.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<dynamic> transactions = [];
  bool isLoading = true;

  Future<void> fetchHistory() async {
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

    final uri = Uri.parse("$baseUri/transaction/all");

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        if (!mounted) return; // Ensure the widget is still mounted
        Flushbar(
          title: "Authentication Error",
          message: "You are not logged in. Please log in again.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.warning, color: Colors.orange),
          duration: const Duration(seconds: 3),
        ).show(context);
        return;
      }

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return; // Ensure the widget is still mounted
        setState(() {
          transactions = data;
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return; // Ensure the widget is still mounted
        Flushbar(
          title: "Error",
          message: errorData['message'] ?? "Failed to fetch history.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 3),
        ).show(context);
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
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHistory(); // Fetch history when the page loads
  }

  int _selectedIndex = 1; // Set the default selected index for History

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } else if (index == 1) {
      // Stay on the History page
    }
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return "${date.day} ${_monthName(date.month)}, ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
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
            const Text("History"),
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
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading indicator
              : transactions.isEmpty
              ? const Center(
                child: Text(
                  "No transactions found.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final isLent = transaction['type'] == 'lent';
                  final formattedDate = formatDate(transaction['date']);

                  // Safely access the contact name
                  final contact =
                      transaction['contact']
                          as Map<String, dynamic>?; // Ensure it's a Map
                  final contactName = contact?['name'] ?? "Unknown";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.grey[200],
                    child: ListTile(
                      leading: Icon(
                        isLent ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isLent ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      title: Text(
                        contactName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        transaction['note'] ?? "No note",
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${isLent ? "+" : "-"}${transaction['amount']}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLent ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Get.bottomSheet(const Bottomsheet(), isScrollControlled: true);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Nav(onTap: _onNavTap, selectedIndex: _selectedIndex),
    );
  }
}

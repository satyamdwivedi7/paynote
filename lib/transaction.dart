import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction extends StatefulWidget {
  final String phone;
  final String contactName;

  const Transaction({
    super.key,
    required this.phone,
    required this.contactName,
  });

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  bool isLoading = true;
  List<dynamic> transactions = [];

  Future<void> fetchTransactions() async {
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

    final url = Uri.parse("$baseUri/transaction/");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        Flushbar(
          title: "Authentication Error",
          message: "You are not logged in. Please log in first.",
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
        body: jsonEncode({"phone": widget.phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          transactions = data;
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        Flushbar(
          title: "Error",
          message: errorData['message'] ?? "Failed to load transactions.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 3),
        ).show(context);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
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
  void initState() {
    super.initState();
    fetchTransactions();
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
        title: Text(widget.contactName),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
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
                        transaction['note'] ?? "No note",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Text(
                        "${isLent ? "+" : "-"}${transaction['amount']}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLent ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

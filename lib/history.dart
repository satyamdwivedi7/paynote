import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:paynote/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paynote/helpers/routeobserver.dart'; // Import RouteObserver

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> with RouteAware {
  List<dynamic> transactions = [];
  bool isLoading = true;

  Future<void> fetchHistory() async {
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

    final uri = Uri.parse("$baseUri/transaction/all");

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        if (!mounted) return;
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
        if (!mounted) return;
        setState(() {
          transactions = data;
          isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        Flushbar(
          title: "Error",
          message: errorData['message'] ?? "Failed to fetch history.",
          flushbarPosition: FlushbarPosition.TOP,
          icon: const Icon(Icons.error, color: Colors.red),
          duration: const Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      if (!mounted) return;
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
    fetchHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    fetchHistory(); // Reload transactions when user comes back
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
      body: RefreshIndicator(
        onRefresh: fetchHistory,
        child:
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
                  physics:
                      const AlwaysScrollableScrollPhysics(), // allow pull to refresh even if list small
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isLent = transaction['type'] == 'lent';
                    final formattedDate = formatDate(transaction['date']);
                    final contact =
                        transaction['contact'] as Map<String, dynamic>?;
                    final contactName = contact?['name'] ?? "Unknown";
                    final contactPhone = contact?['phone'] ?? "Unknown";

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => Transaction(
                                    contactName: contactName,
                                    phone: contactPhone,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

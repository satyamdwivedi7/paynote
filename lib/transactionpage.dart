import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionPage extends StatefulWidget {
  final String type; // "lent" or "borrowed"
  final String phone;
  final String name; // Contact name

  const TransactionPage({
    super.key,
    required this.type,
    required this.phone,
    required this.name,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late bool isLend; // Determines if the transaction is "lent" or "borrowed"
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLend =
        widget.type.toLowerCase() == "lent"; // Initialize based on the type
  }

  Future<void> makeTransaction() async {
    final baseUri = dotenv.env['BASE_URI'];
    if (baseUri == null || baseUri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("BASE_URI is not defined in the .env file"),
        ),
      );
      return;
    }

    final uri = Uri.parse('$baseUri/transaction/create');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication token not found")),
      );
      return;
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "name" : widget.name,
          "phone": widget.phone,
          "amount": amountController.text,
          "type": widget.type,
          "note": noteController.text,
        }),
      );
      if (response.statusCode == 200) {
        // Clear input boxes
        amountController.clear();
        noteController.clear();

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction successful!")),
        );

        // Pop the page
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? "Transaction failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isLend ? Colors.green[400] : Colors.red[400];
    final buttonText = isLend ? 'Lend' : 'Borrow';
    final buttonIcon = Icons.check;
    final textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture
            const CircleAvatar(
              radius: 60,
              child: Icon(Icons.person, size: 80), // Use NetworkImage if online
            ),
            const SizedBox(height: 10),

            // Contact Name
            Text(
              widget.name, // Display the contact name dynamically
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Amount Input Field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Description Input Field
                  TextField(
                    controller: noteController,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: () {
                      makeTransaction(); // Call the transaction function
                    },
                    icon: Icon(buttonIcon, color: backgroundColor),
                    label: Text(buttonText),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor,
                      foregroundColor: backgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

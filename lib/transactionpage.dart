import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paynote/MainPage.dart';

class TransactionPage extends StatefulWidget {
  final String type; 
  final String phone;
  final String name; 

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
  late bool isLend; 
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  bool isLoading = false; 

  @override
  void initState() {
    super.initState();
    isLend =
        widget.type.toLowerCase() == "lent"; 
  }

  Future<void> makeTransaction() async {
    setState(() {
      isLoading = true; 
    });

    final baseUri = dotenv.env['BASE_URI'];
    if (baseUri == null || baseUri.isEmpty) {
      setState(() {
        isLoading = false; 
      });
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
      setState(() {
        isLoading = false; 
      });
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
          "name": widget.name,
          "phone": widget.phone,
          "amount": amountController.text,
          "type": widget.type,
          "note": noteController.text,
        }),
      );

      
      amountController.clear();
      noteController.clear();

      
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
      if (response.statusCode == 200) {
        if (!mounted) return;

        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction successful!")),
        );
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); 
        if (!mounted) return;
        Navigator.pop(context); 
        Navigator.pop(context); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
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
    } finally {
      setState(() {
        isLoading = false; 
      });
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
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(), 
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    
                    const CircleAvatar(
                      radius: 60,
                      child: Icon(
                        Icons.person,
                        size: 80,
                      ), 
                    ),
                    const SizedBox(height: 10),

                    
                    Text(
                      widget.name, 
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

                          
                          ElevatedButton.icon(
                            onPressed: () {
                              makeTransaction(); 
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

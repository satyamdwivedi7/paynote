import 'package:flutter/material.dart';
import 'package:paynote/transaction.dart';
import 'package:paynote/transactionpage.dart';

class AddTransaction extends StatefulWidget {
  final String phone;
  final String contactName;
  final String type;
  final int amount;

  const AddTransaction({
    super.key,
    required this.phone,
    required this.contactName,
    required this.type,
    required this.amount,
  });

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  late String transactionType;

  @override
  void initState() {
    super.initState();
    transactionType = widget.type;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLent = transactionType.toLowerCase() == 'lent';

    return Scaffold(
      backgroundColor: const Color(0xfff4f8f8),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            decoration: BoxDecoration(
              color:
            const Color(0xff5d8aa8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Transaction(
                                  phone: widget.phone,
                                  contactName: widget.contactName,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: isLent ? Colors.white : Colors.red[100],
                  child: const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: isLent ? 'owes you ' : 'you owe ',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    children: [
                      TextSpan(
                        text: '${widget.amount}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isLent ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(type: "lent", phone: widget.phone, name: widget.contactName,),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  const Text(
                    'Lend',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionPage(type: "borrowed", phone: widget.phone, name: widget.contactName,),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_downward,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const Text(
                    'Borrow',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Pay debt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // Implement pay debt logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff457b9d),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'Close debt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Transaction added for ${widget.contactName} as $transactionType",
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

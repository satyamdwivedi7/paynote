import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:paynote/addtransaction.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> pickContact(BuildContext context) async {
  final status = await Permission.contacts.request();

  if (!status.isGranted) {
    // Permission denied
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Permission Denied"),
            content: const Text(
              "Please enable contact permissions in settings.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
    return;
  }

  List<Contact> contacts = [];
  try {
    contacts = await FlutterContacts.getContacts(withProperties: true);
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Failed to load contacts: $e")));
    return;
  }

  if (contacts.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("No contacts available")));
    return;
  }

  showDialog(
    context: context,
    builder:
        (context) => Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Contact",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, i) {
                      final contact = contacts[i];
                      return FutureBuilder<Contact?>(
                        future: FlutterContacts.getContact(
                          contact.id,
                          withProperties: true,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final fullContact = snapshot.data!;
                          if (fullContact.phones.isEmpty)
                            return const SizedBox();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullContact.displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...fullContact.phones.map((phone) {
                                    final sanitizedPhone = _sanitizePhoneNumber(
                                      phone.number,
                                    );
                                    if (sanitizedPhone.length != 10) {
                                      return const SizedBox();
                                    }
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        sanitizedPhone,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => AddTransaction(
                                                  phone: sanitizedPhone,
                                                  contactName:
                                                      fullContact.displayName,
                                                  type: "borrowed",
                                                  amount: 0,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

String _sanitizePhoneNumber(String phoneNumber) {
  String sanitized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
  sanitized = sanitized.replaceAll(RegExp(r'^\+91|^\+977|\D'), '');
  if (sanitized.length > 10) {
    sanitized = sanitized.substring(sanitized.length - 10);
  }
  return sanitized;
}

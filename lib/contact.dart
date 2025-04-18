import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:paynote/addtransaction.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPicker extends StatefulWidget {
  const ContactPicker({super.key});

  @override
  State<ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends State<ContactPicker> {
  bool _permissionDenied = false;
  bool _isLoading = false;
  List<Contact>? _contacts;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.contacts.request();

    if (status.isGranted) {
      _permissionDenied = false;
      await _loadContacts();
    } else {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact permission denied")),
      );
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load contacts: $e")));
    }
  }

  // void _showContactPicker() async {
  //   if (_permissionDenied) {
  //     await _checkPermission();
  //     return;
  //   }

  //   if (_contacts == null) {
  //     await _checkPermission();
  //     if (!_permissionDenied && _contacts != null && _contacts!.isNotEmpty) {
  //       _showContactListDialog();
  //     }
  //   } else {
  //     _showContactListDialog();
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _permissionDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Permission Denied"),
              content: const Text(
                "Please enable contact permissions in settings.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      });
      return const SizedBox(); // <-- Return a dummy widget after scheduling the dialog
    } else if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_contacts == null || _contacts!.isEmpty) {
      return const Center(child: Text("No contacts available"));
    }

    // Show Select Contact dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _contacts!.length,
                        itemBuilder: (context, i) {
                          final contact = _contacts![i];
                          return FutureBuilder<Contact?>(
                            future: FlutterContacts.getContact(
                              contact.id,
                              withProperties: true,
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final fullContact = snapshot.data!;
                              if (fullContact.phones.isEmpty) {
                                return const SizedBox();
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        final sanitizedPhone =
                                            _sanitizePhoneNumber(phone.number);
                                        if (sanitizedPhone.length != 10) {
                                          return const SizedBox();
                                        }
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            sanitizedPhone,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
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
                                                          fullContact
                                                              .displayName,
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
    });

    return const SizedBox(); // <-- Again, dummy widget to return after scheduling
  }

  String _sanitizePhoneNumber(String phoneNumber) {
    String sanitized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    sanitized = sanitized.replaceAll(RegExp(r'^\+91|^\+977|\D'), '');
    if (sanitized.length > 10) {
      sanitized = sanitized.substring(sanitized.length - 10);
    }
    return sanitized;
  }
}

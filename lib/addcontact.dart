import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'addtransaction.dart';

class AddContact extends StatefulWidget {
  const AddContact({super.key});

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  List<Contact>? _contacts;
  bool _isLoading = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showContactPicker();
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
      });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load contacts: $e")));
    }
  }

  void _showContactPicker() async {
    if (_permissionDenied) {
      await _checkPermission();
      return;
    }

    if (_contacts == null) {
      await _checkPermission();
      if (!_permissionDenied && _contacts != null && _contacts!.isNotEmpty) {
        _showContactListDialog();
      }
    } else {
      _showContactListDialog();
    }
  }

  void _showContactListDialog() {
    if (_contacts == null || _contacts!.isEmpty) {
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
                                      final sanitizedPhone =
                                          _sanitizePhoneNumber(phone.number);
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
                                          print(
                                            'Picked Contact -> Name: ${fullContact.displayName}, Phone: $sanitizedPhone',
                                          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Contact")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Pick a contact to add",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showContactPicker,
                      child: Text(
                        _permissionDenied
                            ? "Grant Contact Permission"
                            : "Pick Contact",
                      ),
                    ),
                    if (_permissionDenied)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Contact permission is required to pick contacts. Please grant the permission.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}

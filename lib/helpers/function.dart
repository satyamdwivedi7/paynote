import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:paynote/addtransaction.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> pickContact(BuildContext context) async {
  final status = await Permission.contacts.request();

  if (!status.isGranted) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
    contacts = await FlutterContacts.getContacts(); // Only names, no properties
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Failed to load contacts: $e")));
    return;
  }

  if (contacts.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("No contacts available")));
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ContactPickerBottomSheet(contacts: contacts),
  );
}

class _ContactPickerBottomSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerBottomSheet({required this.contacts});

  @override
  State<_ContactPickerBottomSheet> createState() =>
      _ContactPickerBottomSheetState();
}

class _ContactPickerBottomSheetState extends State<_ContactPickerBottomSheet> {
  List<Contact> filteredContacts = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    filteredContacts = widget.contacts;
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredContacts =
          widget.contacts.where((contact) {
            final name = contact.displayName.toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder:
          (_, controller) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Select Contact",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: updateSearch,
                  decoration: InputDecoration(
                    hintText: "Search contact...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      filteredContacts.isEmpty
                          ? const Center(child: Text("No contacts found."))
                          : ListView.builder(
                            controller: controller,
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              return _buildContactTile(contact);
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[300],
          child: Text(
            contact.displayName.isNotEmpty
                ? contact.displayName[0].toUpperCase()
                : "?",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          contact.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () async {
          final fullContact = await FlutterContacts.getContact(
            contact.id,
            withProperties: true,
          );
          if (fullContact == null || fullContact.phones.isEmpty) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No phone number available for this contact."),
              ),
            );
            return;
          }

          final sanitizedPhones =
              fullContact.phones
                  .map((phone) => _sanitizePhoneNumber(phone.number))
                  .where((number) => number.length == 10)
                  .toList();

          if (sanitizedPhones.isEmpty) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No valid phone number found.")),
            );
            return;
          }

          final selectedPhone = sanitizedPhones.first;

          if (!context.mounted) return;
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AddTransaction(
                    phone: selectedPhone,
                    contactName: fullContact.displayName,
                    type: "borrowed",
                    amount: 0,
                  ),
            ),
          );
        },
      ),
    );
  }
}

String _sanitizePhoneNumber(String phoneNumber) {
  String sanitized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
  sanitized = sanitized.replaceAll(RegExp(r'^\+91|^\+977|\D'), '');
  if (sanitized.length > 10) {
    sanitized = sanitized.substring(sanitized.length - 10);
  }
  return sanitized;
}

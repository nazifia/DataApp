// Contact Picker Utility
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'validation.dart';

class ContactPicker {
  /// Requests contact permission, then opens a contact picker dialog.
  /// Returns the selected Nigerian phone number, or null if cancelled.
  static Future<String?> pickPhoneNumber(BuildContext context) async {
    // Request contacts permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required to pick a number.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    // Fetch contacts with phone numbers
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (contacts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contacts found on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    if (!context.mounted) return null;

    // Show contact picker dialog
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ContactPickerSheet(contacts: contacts),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerSheet({required this.contacts});

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchController = TextEditingController();
  List<Contact> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.contacts
        .where((c) => c.phones.isNotEmpty)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = widget.contacts
          .where((c) =>
              c.phones.isNotEmpty &&
              (c.displayName.toLowerCase().contains(query.toLowerCase()) ||
                  c.phones.any((p) => p.number.contains(query))))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Select Contact',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name or number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _filtered.length,
                    itemBuilder: (_, index) {
                      final contact = _filtered[index];
                      final phones = contact.phones;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          phones.first.number,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: phones.length > 1
                            ? Icon(Icons.expand_more,
                                color: Colors.grey[400])
                            : null,
                        onTap: () {
                          if (phones.length == 1) {
                            Navigator.of(context).pop(
                                Validators.formatNigerianPhone(
                                    phones.first.number));
                          } else {
                            _showMultipleNumbers(context, contact);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showMultipleNumbers(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(contact.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: contact.phones
              .map(
                (p) => ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(p.number),
                  subtitle:
                      p.label.name.isNotEmpty ? Text(p.label.name) : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(
                        Validators.formatNigerianPhone(p.number));
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PhoneBookApp());
}

class PhoneBookApp extends StatelessWidget {
  const PhoneBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Number Storage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PhoneBookScreen(),
    );
  }
}

class Contact {
  String name;
  String phoneNumber;

  Contact({required this.name, required this.phoneNumber});

  // Convert a Contact to a Map for JSON encoding
  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
      };

  // Create a Contact from a JSON Map
  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        name: json['name'],
        phoneNumber: json['phoneNumber'],
      );
}

class PhoneBookScreen extends StatefulWidget {
  const PhoneBookScreen({super.key});

  @override
  State<PhoneBookScreen> createState() => _PhoneBookScreenState();
}

class _PhoneBookScreenState extends State<PhoneBookScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // Load contacts from SharedPreferences
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsString = prefs.getString('saved_contacts');
    if (contactsString != null) {
      final List<dynamic> decodedList = jsonDecode(contactsString);
      setState(() {
        _contacts = decodedList.map((item) => Contact.fromJson(item)).toList();
      });
    }
  }

  // Save contacts to SharedPreferences
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString('saved_contacts', encodedList);
  }

  // Add a new contact
  void _addContact() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        _contacts.add(Contact(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
        ));
      });
      _saveContacts();
      _nameController.clear();
      _phoneController.clear();
      Navigator.pop(context); // Close the bottom sheet
    }
  }

  // Delete a contact
  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  // Show bottom sheet to add a phone number
  void _showAddContactModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Store New Number',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addContact,
              child: const Text('Save Number'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Number Storage'),
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text(
                'No phone numbers stored yet.\nTap "+" to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(contact.phoneNumber),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteContact(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}


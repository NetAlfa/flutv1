import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const ContactApp());

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ContactListPage(),
    );
  }
}

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact>? _contacts;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    // Request contact permissions using permission_handler
    var status = await Permission.contacts.request();

    if (status.isGranted) {
      // Fetch contacts with properties like phone numbers and thumbnails
      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      setState(() {
        _contacts = contacts;
      });
    } else {
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  Future<void> _addNewContact() async {
    // Example of creating a new contact programmatically
    final newContact = Contact()
      ..name.first = 'John'
      ..name.last = 'Doe'
      ..phones = [Phone('555-0199')];

    await newContact.insert();
    _fetchContacts(); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchContacts,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _addNewContact();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added John Doe to contacts!')),
            );
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) {
      return const Center(
        child: Text(
          'Permission Denied.\nPlease enable contacts permission in settings.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }
    if (_contacts == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_contacts!.isEmpty) {
      return const Center(child: Text('No contacts found.'));
    }

    return ListView.builder(
      itemCount: _contacts!.length,
      itemBuilder: (context, index) {
        final contact = _contacts![index];
        final phoneNumber = contact.phones.isNotEmpty
            ? contact.phones.first.number
            : 'No phone number';

        return ListTile(
          leading: contact.thumbnail != null
              ? CircleAvatar(backgroundImage: MemoryImage(contact.thumbnail!))
              : CircleAvatar(child: Text(contact.displayName.isNotEmpty ? contact.displayName[0] : '?')),
          title: Text(contact.displayName),
          subtitle: Text(phoneNumber),
          onTap: () {
            // You can navigate to a detail screen or display more info here
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(contact.displayName),
                content: Text('Phone: $phoneNumber'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChoiceCardEditorScreen extends StatefulWidget {
  const ChoiceCardEditorScreen({super.key});

  @override
  State<ChoiceCardEditorScreen> createState() => _ChoiceCardEditorScreenState();
}

class _ChoiceCardEditorScreenState extends State<ChoiceCardEditorScreen> {
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _fields = {
    'title': '',
    'goodAction': '',
    'goodPoints': 0,
    'badAction': '',
    'badPoints': 0,
    'unlockRole': '',
  };

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _db.collection('choice_cards').add(_fields);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card added.")));
    }
  }

  Future<void> _deleteCard(String id) async {
    await _db.collection('choice_cards').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card deleted.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Choice Card Editor")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Title"),
                    onSaved: (val) => _fields['title'] = val ?? '',
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Good Action"),
                    onSaved: (val) => _fields['goodAction'] = val ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Good Points"),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => _fields['goodPoints'] = int.tryParse(val ?? '0') ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Bad Action"),
                    onSaved: (val) => _fields['badAction'] = val ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Bad Points"),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => _fields['badPoints'] = int.tryParse(val ?? '0') ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Unlock Role (optional)"),
                    onSaved: (val) => _fields['unlockRole'] = val ?? '',
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveCard,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Card"),
                  )
                ],
              ),
            ),
          ),
          const Divider(),
          const Text("Existing Cards", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('choice_cards').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final cards = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cards.length,
                  itemBuilder: (_, index) {
                    final doc = cards[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text("Good: ${data['goodAction']} (${data['goodPoints']} pts)"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCard(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});
  @override
  State<NewItemScreen> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _isSendingItem = false;

  var _selectedCategory = categories[Categories.vegetables]!;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSendingItem = true;
      });

      final url = Uri.https('flutter-prep-b32a4-default-rtdb.firebaseio.com',
          'shopping-list.json');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title
        }),
      );

      String groceryId =
          (json.decode(response.body) as Map<String, dynamic>)['name'];

      final groceryItem = GroceryItem(
          id: groceryId,
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory);
      if (context.mounted) {
        Navigator.of(context).pop(groceryItem);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (enteredName) {
                  if (enteredName == null || enteredName.trim().length <= 1) {
                    return 'Must be between 1 and 50 characters.';
                  } else {
                    return null;
                  }
                },
                onSaved: (enteredName) {
                  _enteredName = enteredName!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: '1',
                      validator: (enteredQuantity) {
                        if (enteredQuantity == null ||
                            enteredQuantity.isEmpty ||
                            int.tryParse(enteredQuantity) == null ||
                            int.tryParse(enteredQuantity)! <= 0) {
                          return 'Must be a valid positive number';
                        } else {
                          return null;
                        }
                      },
                      onSaved: (enteredQuantity) {
                        _enteredQuantity = int.parse(enteredQuantity!);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _selectedCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                      width: 16,
                                      height: 16,
                                      color: category.value.color),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Text(category.value.title)
                                ],
                              ),
                            ),
                        ],
                        onChanged: (selectedCategory) {
                          _selectedCategory = selectedCategory!;
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSendingItem
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                      onPressed: _isSendingItem ? null : _saveItem,
                      child: _isSendingItem
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Add Item'))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

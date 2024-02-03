// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item_screen.dart';
import 'package:shopping_list/widgets/grocery_item.dart';
import 'package:http/http.dart' as http;

class GroceriesScreen extends StatefulWidget {
  const GroceriesScreen({super.key});

  @override
  State<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends State<GroceriesScreen> {
  List<GroceryItem> _groceries = [];
  bool _isLoading = true;
  String? _error;

  void _onRemoveItem(GroceryItem groceryItem) async {
    final itemIndex = _groceries.indexOf(groceryItem);

    final url = Uri.https('flutter-prep-b32a4-default-rtdb.firebaseio.com',
        'shopping-list/${groceryItem.id}.json');

    setState(() {
      _groceries.remove(groceryItem);
    });

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceries.insert(itemIndex, groceryItem);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'flutter-prep-b32a4-default-rtdb.firebaseio.com', 'shopping-list.json');

    Response response;
    try {
      response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later.';
          _isLoading = false;
        });
      }

      if (_error == null) {
        final Map<String, dynamic>? itemsList = json.decode(response.body);

        final List<GroceryItem> loadedItems = [];

        if (itemsList != null) {
          for (final item in itemsList.entries) {
            String id = item.key;
            String name = item.value['name'];
            int quantity = item.value['quantity'];
            Category category = categories.entries
                .firstWhere((categoryElement) =>
                    categoryElement.value.title == item.value['category'])
                .value;

            GroceryItem currentItem = GroceryItem(
                id: id, name: name, quantity: quantity, category: category);
            loadedItems.add(currentItem);
          }

          setState(() {
            _error = null;
            _groceries = loadedItems;
            _isLoading = false;
          });
        }
      }
    } catch (exception) {
      setState(() {
        _error = 'Something went wrong';

        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final groceryItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );

    if (groceryItem != null) {
      setState(() {
        _groceries.add(groceryItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final noItemsText = _error ?? 'You got no items yet';
    Widget noItemsWidget = Center(
      child: _isLoading ? const CircularProgressIndicator() : Text(noItemsText),
    );

    Widget itemsList = ListView.builder(
      padding: const EdgeInsets.all(16),
      itemExtent: 64,
      itemCount: _groceries.length,
      itemBuilder: (itemBuilderContext, index) => Dismissible(
        key: Key(_groceries[index].id),
        background: Container(color: Theme.of(context).colorScheme.error),
        child: GroceryItemWidget(
          groceryItem: _groceries[index],
        ),
        onDismissed: (dismissDirection) {
          _onRemoveItem(_groceries[index]);
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
        ],
      ),
      body: _groceries.isNotEmpty ? itemsList : noItemsWidget,
    );
  }
}

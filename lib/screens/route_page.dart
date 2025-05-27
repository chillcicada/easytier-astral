import 'package:flutter/material.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  List<String> items = List.generate(10, (index) => 'Card \$index');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReorderableListView(
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final String item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
          });
        },
       children: <Widget>[
  for (int index = 0; index < items.length; index++)
    Card(
      key: ValueKey(index), // Use index as the key
      child: ListTile(
        title: Text(items[index]),
      ),
    ),
],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../data/models/donation_model.dart';

class FoodItemDialog extends StatefulWidget {
  final Function(FoodItem) onAdd;

  const FoodItemDialog({super.key, required this.onAdd});

  @override
  State<FoodItemDialog> createState() => _FoodItemDialogState();
}

class _FoodItemDialogState extends State<FoodItemDialog> {
  final _itemNameController = TextEditingController();
  final _itemMembersController = TextEditingController();
  String _itemCategory = 'Cooked Meal';

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: const Text("What's on the menu?",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogField(_itemNameController, "Dish Name", Icons.restaurant_rounded),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _itemCategory,
            decoration: InputDecoration(
              labelText: "Category",
              prefixIcon: const Icon(Icons.category_rounded),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
            items: [
              'Cooked Meal',
              'Bakery Items',
              'Raw Materials',
              'Fruits/Veggies',
              'Other'
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _itemCategory = v!),
          ),
          const SizedBox(height: 16),
          _buildDialogField(_itemMembersController, "Serving Size (People)",
              Icons.people_rounded,
              keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: () {
            if (_itemNameController.text.isNotEmpty &&
                _itemMembersController.text.isNotEmpty) {
              widget.onAdd(FoodItem(
                foodName: _itemNameController.text,
                category: _itemCategory,
                membersServed: int.parse(_itemMembersController.text),
              ));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
          child: const Text("ADD ITEM"),
        ),
      ],
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

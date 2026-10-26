import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/models/menu_item.dart';
import '../../shared/services/api_client.dart';

class AddItemSheet extends StatefulWidget {
  final int restaurantId;
  final MenuItem? existingItem;
  const AddItemSheet(
      {super.key, required this.restaurantId, this.existingItem});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  String _selectedCategory = 'Burgers';
  bool _busy = false;
  String? _err;
  String? _uploadedImageUrl;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  final List<String> _categories = [
    'Burgers',
    'Pizza',
    'Chicken',
    'Fast Food',
    'Asian',
    'Pasta',
    'Salads',
    'Desserts',
    'Drinks',
    'Sides',
    'Breakfast',
    'Seafood',
    'Sandwiches',
    'Tacos',
    'Sushi',
    'BBQ',
    'Vegan',
    'Vegetarian',
    'Coffee',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existingItem?.name ?? '');
    _desc = TextEditingController(text: widget.existingItem?.description ?? '');
    _price = TextEditingController(
        text: widget.existingItem?.price.toString() ?? '');
    _uploadedImageUrl = widget.existingItem?.imageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      setState(() {
        _busy = true;
        _err = null;
      });

      final file = result.files.single;
      final uri = Uri.parse('http://127.0.0.1:8001/menu/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.token}';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        setState(() => _uploadedImageUrl = data['url']);
      } else {
        setState(() => _err = 'Upload failed');
      }
    } catch (e) {
      setState(() => _err = 'Upload error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showUrlDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Paste Image URL',
            style: TextStyle(color: Colors.black87)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            hintText: 'https://example.com/food.jpg',
            hintStyle: TextStyle(color: Colors.black45),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _uploadedImageUrl = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _price.text.isEmpty) {
      setState(() => _err = 'Name and price are required');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });

    final payload = {
      'name': _name.text.trim(),
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'price': _price.text.trim(),
      'currency': 'USD',
      'image_url': _uploadedImageUrl,
      'available': true,
      'sort_order': 0,
    };

    try {
      if (widget.existingItem == null) {
        await ApiClient.post(
            '/menu/restaurants/${widget.restaurantId}/items', payload);
      } else {
        await ApiClient.patch(
            '/menu/items/${widget.existingItem!.id}', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(width: 4, height: 24, color: gold),
                const SizedBox(width: 12),
                Text(
                  widget.existingItem == null
                      ? 'Add New Product'
                      : 'Edit Product',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkGreen),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image preview
            if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
              Container(
                height: 160,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(_uploadedImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red, size: 18),
                        onPressed: () =>
                            setState(() => _uploadedImageUrl = null),
                      ),
                    ),
                  ),
                ),
              ),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickAndUploadImage,
                    icon: const Icon(Icons.upload_file, color: darkGreen),
                    label: const Text('Upload File',
                        style: TextStyle(color: darkGreen)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: darkGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showUrlDialog,
                    icon: const Icon(Icons.link, color: darkGreen),
                    label: const Text('Use URL',
                        style: TextStyle(color: darkGreen)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: darkGreen),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Dropdown — BLACK TEXT on WHITE background
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down, color: darkGreen),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(color: Colors.black87)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name
            TextField(
              controller: _name,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration:
                  _inputDecoration('Product Name', 'e.g. Classic Cheeseburger'),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _desc,
              maxLines: 3,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: _inputDecoration(
                  'Description', 'Fresh beef patty with cheddar...'),
            ),
            const SizedBox(height: 12),

            // Price
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: _inputDecoration('Price (USD)', '9.99')
                  .copyWith(prefixText: '\$ '),
            ),

            if (_err != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_err!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _busy
                  ? const CircularProgressIndicator(color: gold)
                  : Text(
                      widget.existingItem == null
                          ? 'Add Product'
                          : 'Save Changes',
                      style: const TextStyle(
                          color: gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.black87, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkGreen, width: 2),
      ),
    );
  }
}

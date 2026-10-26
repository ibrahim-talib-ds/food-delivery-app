import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/services/api_client.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  String _cardType = 'visa';
  bool _saving = false;
  String? _error;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  Future<void> _saveCard() async {
    if (_numberController.text.length < 16) {
      setState(() => _error = 'Card number must be 16 digits');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.post('/wallet/cards', {
        'card_number': _numberController.text.replaceAll(' ', ''),
        'card_holder': _holderController.text,
        'expiry_date': _expiryController.text,
        'card_type': _cardType,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text('Add New Card',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Card Type',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _cardType = 'visa'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardType == 'visa'
                            ? const Color(0xFFE8F0EA)
                            : Colors.white,
                        border: Border.all(
                            color: _cardType == 'visa'
                                ? darkGreen
                                : Colors.grey.shade300,
                            width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text('VISA',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                          SizedBox(height: 4),
                          Text('Visa Card',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _cardType = 'mastercard'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardType == 'mastercard'
                            ? const Color(0xFFE8F0EA)
                            : Colors.white,
                        border: Border.all(
                            color: _cardType == 'mastercard'
                                ? darkGreen
                                : Colors.grey.shade300,
                            width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text('MC',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          SizedBox(height: 4),
                          Text('Mastercard',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── VISIBILITY FIXED: BLACK TEXT ───
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16)
              ],
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Card Number (16 digits)',
                labelStyle: TextStyle(color: Colors.black87),
                hintText: '0000 0000 0000 0000',
                hintStyle: TextStyle(color: Colors.black38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _holderController,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                labelStyle: TextStyle(color: Colors.black87),
                hintText: 'John Doe',
                hintStyle: TextStyle(color: Colors.black38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expiryController,
              keyboardType: TextInputType.datetime,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Expiry Date (MM/YY)',
                labelStyle: TextStyle(color: Colors.black87),
                hintText: '12/25',
                hintStyle: TextStyle(color: Colors.black38),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkGreen, width: 2)),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: gold)
                    : const Text('Save Card',
                        style: TextStyle(
                            color: gold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

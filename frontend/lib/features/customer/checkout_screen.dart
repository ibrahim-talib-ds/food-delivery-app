import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/api_client.dart';
import 'cart_state.dart';
import 'order_success_screen.dart';
import 'add_card_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'cash';
  bool _placing = false;
  bool _loadingPayment = true;
  double _walletBalance = 0.0;
  List<dynamic> _cards = [];

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final walletData = await ApiClient.get('/wallet/balance');
      final cardData = await ApiClient.get('/wallet/cards');
      setState(() {
        _walletBalance = double.parse(walletData['balance'].toString());
        _cards = cardData;
        // If cards exist, select the first one by default
        if (_cards.isNotEmpty) {
          _selectedPayment = 'card_${_cards[0]['id']}';
        }
      });
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
    } finally {
      if (mounted) setState(() => _loadingPayment = false);
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartState>().cart;
    if (cart == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Your cart is empty!')));
      return;
    }

    setState(() => _placing = true);
    final cartState = context.read<CartState>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final orderData = await ApiClient.post('/orders', {
        'address': '42 Main St, New York',
        'note': 'Apartment 4B, Near Central Park West',
      });
      final orderId = orderData['id'];

      // Map the selected payment to the provider string
      String provider = _selectedPayment;
      if (provider.startsWith('card_')) provider = 'card';

      await ApiClient.post('/payments/initiate', {
        'order_id': orderId,
        'provider': provider,
      });

      await cartState.clearCart();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        // Show error as a floating snackbar
        messenger.showSnackBar(SnackBar(
          content: Text('Could not place order: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  void _openAddCard() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddCardScreen()));
    if (result == true) {
      _fetchPaymentMethods(); // Refresh if a card was added
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>().cart;
    if (cart == null || cart.items.isEmpty) {
      return const Scaffold(body: Center(child: Text('Cart is empty')));
    }

    final subtotal = cart.subtotal;
    final delivery = cart.deliveryFee;
    final tax = subtotal * 0.053;
    final total = subtotal + delivery + tax;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        centerTitle: true,
        title: const Text('Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingPayment
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('DELIVER TO',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    letterSpacing: 1)),
                            GestureDetector(
                                onTap: () {},
                                child: const Text('Edit',
                                    style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0EA),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.location_on,
                                    color: darkGreen, size: 20)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('42 Main St, New York',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87)),
                                  Text('Apartment 4B, Near Central Park West',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods
                  const Text('Payment Method',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMethodCard(
                          'Cash', 'Pay on delivery', Icons.money, 'cash'),
                      _buildMethodCard(
                          'Wallet',
                          '\$${_walletBalance.toStringAsFixed(2)}',
                          Icons.wallet,
                          'wallet'),
                      ..._cards.map((card) => _buildMethodCard(
                            card['card_type'].toUpperCase(),
                            '**** ${card['card_number'].substring(card['card_number'].length - 4)}',
                            Icons.credit_card,
                            'card_${card['id']}',
                          )),
                      GestureDetector(
                        onTap: _openAddCard,
                        child: Container(
                          width: 110,
                          height: 100,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade300,
                                  style: BorderStyle.solid,
                                  width: 2)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: Colors.grey),
                              Text('Add Card',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Order Summary
                  const Text('Order Summary',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _summaryRow(
                            'Sub Total (${cart.itemCount} items)', subtotal),
                        const SizedBox(height: 8),
                        _summaryRow('Delivery Fee', delivery),
                        const SizedBox(height: 8),
                        _summaryRow('Taxes & Service (5.3%)', tax),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: darkGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
        ]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _placing
                  ? const CircularProgressIndicator(color: gold)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Place Order',
                            style: TextStyle(
                                color: gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.security, color: gold, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text('\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMethodCard(
      String title, String subtitle, IconData icon, String value) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        width: 110,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0EA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? darkGreen : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? darkGreen : Colors.black54, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? darkGreen : Colors.black87)),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.black45),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

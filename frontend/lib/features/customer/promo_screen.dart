import 'package:flutter/material.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({super.key});
  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.15)),
                child: const Icon(Icons.local_offer, color: gold, size: 100),
              ),
            ),
            const SizedBox(height: 40),
            const Text('Flat Rs 100 OFF',
                style: TextStyle(
                    color: gold,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.2),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('On all food orders above Rs 500.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: gold, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: Text('Use Code: ORDER100',
                      style: TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 16))),
            ),
            const Spacer(),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                child: const Text('Start Ordering',
                    style: TextStyle(
                        color: darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

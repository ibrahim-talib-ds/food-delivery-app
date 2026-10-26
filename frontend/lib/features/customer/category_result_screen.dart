import 'package:flutter/material.dart';
import '../../shared/models/restaurant.dart';
import '../../shared/services/api_client.dart';
import 'restaurant_detail_screen.dart';

class CategoryResultScreen extends StatefulWidget {
  final String title;
  final String? filterQuery;
  const CategoryResultScreen(
      {super.key, required this.title, this.filterQuery});
  @override
  State<CategoryResultScreen> createState() => _CategoryResultScreenState();
}

class _CategoryResultScreenState extends State<CategoryResultScreen> {
  List<Restaurant>? _results;
  bool _loading = true;
  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.get('/restaurants');
      final all = (data as List).map((j) => Restaurant.fromJson(j)).toList();
      if (widget.filterQuery == null || widget.filterQuery!.isEmpty) {
        setState(() => _results = all);
      } else {
        final q = widget.filterQuery!.toLowerCase();
        setState(() {
          _results = all
              .where((r) =>
                  r.name.toLowerCase().contains(q) ||
                  (r.description ?? '').toLowerCase().contains(q))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _results == null || _results!.isEmpty
              ? const Center(
                  child: Text('Nothing found.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final r = _results![index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantDetailScreen(restaurant: r))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&q=80'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: darkGreen)),
                                    Text(r.description ?? 'Delicious food',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text(
                                        '\$${r.deliveryFee.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: gold,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

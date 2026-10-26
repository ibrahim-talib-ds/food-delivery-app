import 'package:flutter/material.dart';
import '../../shared/models/restaurant.dart';
import '../../shared/services/api_client.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  List<Restaurant>? _results;
  bool _loading = false;
  String _query = '';

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  final List<String> _popularSearches = [
    'Pizza',
    'Burger',
    'Sushi',
    'Pasta',
    'Chicken',
    'Salad',
    'Coffee',
    'Dessert'
  ];
  final List<String> _recentSearches = ['Noodles', 'Tacos', 'Ice Cream'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      _query = widget.initialQuery;
      _search();
    }
  }

  Future<void> _search() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() {
      _loading = true;
      _query = _controller.text.trim();
    });
    try {
      final data = await ApiClient.get('/restaurants');
      final all = (data as List).map((j) => Restaurant.fromJson(j)).toList();
      final q = _query.toLowerCase();
      setState(() {
        _results = all
            .where((r) =>
                r.name.toLowerCase().contains(q) ||
                (r.description ?? '').toLowerCase().contains(q))
            .toList();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkGreen),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'Search restaurants, dishes...',
                hintStyle: TextStyle(color: Colors.black45),
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
          : _results == null
              ? _buildEmptyState()
              : _results!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No results for "$_query"',
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          const Text('Try a different keyword',
                              style: TextStyle(
                                  color: Colors.black38, fontSize: 13)),
                        ],
                      ),
                    )
                  : _buildResults(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Popular Right Now',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _popularSearches
              .map((s) => GestureDetector(
                    onTap: () {
                      _controller.text = s;
                      _search();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up,
                              color: darkGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(s,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 32),
        const Text('Recent Searches',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
        const SizedBox(height: 8),
        ..._recentSearches
            .map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Colors.black45),
                  title: Text(s, style: const TextStyle(color: Colors.black87)),
                  trailing: const Icon(Icons.arrow_outward,
                      color: Colors.black38, size: 18),
                  onTap: () {
                    _controller.text = s;
                    _search();
                  },
                ))
            .toList(),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final r = _results![index];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RestaurantDetailScreen(restaurant: r))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&q=80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(r.description ?? 'Delicious food',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          const Text('4.8',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(width: 12),
                          Text('\$${r.deliveryFee.toStringAsFixed(2)} delivery',
                              style: const TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

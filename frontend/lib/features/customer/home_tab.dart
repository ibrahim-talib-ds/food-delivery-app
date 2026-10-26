import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/menu_item.dart';
import '../../shared/services/api_client.dart';
import '../../shared/widgets/logo_widget.dart';
import 'food_details_screen.dart';
import 'location_state.dart';
import 'location_picker_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';
import 'cart_state.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<MenuItem>? _allProducts;
  List<MenuItem>? _displayProducts;
  bool _loading = true;
  String _selectedCategory = 'All';

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);
  static const lightGold = Color(0xFFF3E5AB);

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.restaurant_menu,
      'color': const Color(0xFFFFE0B2)
    },
    {
      'name': 'Burgers',
      'icon': Icons.fastfood,
      'color': const Color(0xFFFFFACD)
    },
    {
      'name': 'Pizza',
      'icon': Icons.local_pizza,
      'color': const Color(0xFFFFB6C1)
    },
    {
      'name': 'Chicken',
      'icon': Icons.set_meal,
      'color': const Color(0xFFFFDAB9)
    },
    {'name': 'Salads', 'icon': Icons.eco, 'color': const Color(0xFFD4EDDA)},
    {'name': 'Desserts', 'icon': Icons.cake, 'color': const Color(0xFFE1BEE7)},
    {'name': 'Coffee', 'icon': Icons.coffee, 'color': const Color(0xFFD3D3D3)},
    {'name': 'Sushi', 'icon': Icons.set_meal, 'color': const Color(0xFFFFCDD2)},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/menu/all');
      final products = (data as List)
          .map((j) => MenuItem.fromJson({
                ...j,
                'restaurant_id': j['restaurant_id'],
                'category_id': null,
                'sort_order': 0,
              }))
          .toList();

      setState(() {
        _allProducts = products;
        _displayProducts = products;
      });
    } catch (e) {
      debugPrint('Products error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _displayProducts = _allProducts;
      } else {
        _displayProducts = _allProducts
                ?.where((p) =>
                    p.name.toLowerCase().contains(category.toLowerCase()) ||
                    (p.description ?? '')
                        .toLowerCase()
                        .contains(category.toLowerCase()))
                .toList() ??
            [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationState>();
    return Scaffold(
      backgroundColor: darkGreen,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: gold,
          child: CustomScrollView(
            slivers: [
              // Top Bar with Logo
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const LogoWidget(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const LocationPickerScreen())),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DELIVERING TO',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: gold, size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                        loc.fullLocation.isNotEmpty
                                            ? loc.fullLocation
                                            : 'Select Location',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: lightGold),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: lightGold, size: 26),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen())),
                      ),
                    ],
                  ),
                ),
              ),

              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30)),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: darkGreen),
                          SizedBox(width: 12),
                          Text('Search for dishes...',
                              style: TextStyle(
                                  color: Colors.black45, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Categories — Now clickable filters
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => _filterByCategory(cat['name'] as String),
                        child: Container(
                          width: 75,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: cat['color'] as Color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: gold, width: 3)
                                      : null,
                                ),
                                child: Icon(cat['icon'] as IconData,
                                    color: darkGreen, size: 28),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['name'] as String,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected ? gold : Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          _selectedCategory == 'All'
                              ? 'Popular Dishes'
                              : _selectedCategory,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: gold)),
                      Text('${_displayProducts?.length ?? 0} items',
                          style:
                              const TextStyle(color: lightGold, fontSize: 13)),
                    ],
                  ),
                ),
              ),

              // Products Grid
              _loading
                  ? const SliverFillRemaining(
                      child:
                          Center(child: CircularProgressIndicator(color: gold)))
                  : _displayProducts == null || _displayProducts!.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                              child: Text('No products in this category',
                                  style: TextStyle(color: Colors.white54))))
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              mainAxisExtent: 260,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _displayProducts![index];
                                return _ProductCard(item: item);
                              },
                              childCount: _displayProducts!.length,
                            ),
                          ),
                        ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PRODUCT CARD with + button ───
class _ProductCard extends StatelessWidget {
  final MenuItem item;
  const _ProductCard({required this.item});

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => FoodDetailsScreen(item: item))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image container — small, fully visible
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: item.imageUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.network(item.imageUrl!,
                                  fit: BoxFit.contain),
                            )
                          : const Icon(Icons.restaurant,
                              color: Colors.grey, size: 60),
                    ),
                  ),
                  // + Button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        await context.read<CartState>().addItem(item.id, 1);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: darkGreen,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(Icons.add, color: gold, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const Row(
                          children: [
                            Icon(Icons.star, color: gold, size: 14),
                            SizedBox(width: 2),
                            Text('4.8',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

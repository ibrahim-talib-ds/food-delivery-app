import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/models/menu_item.dart';
import '../../shared/services/api_client.dart';
import 'cart_state.dart';
import '../../shared/utils/food_images.dart';

class FoodDetailsScreen extends StatefulWidget {
  final MenuItem item;
  const FoodDetailsScreen({super.key, required this.item});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  final int _quantity = 1;
  List<MenuItem>? _related;
  bool _loadingRelated = true;

  static const darkGreen = Color(0xFF0D2B1A);
  static const gold = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    try {
      final data = await ApiClient.get('/menu/related/${widget.item.id}');
      setState(() {
        _related = (data as List)
            .map((j) => MenuItem.fromJson({
                  ...j,
                  'category_id': null,
                  'sort_order': 0,
                }))
            .toList();
      });
    } catch (e) {
      debugPrint('Related error: $e');
    } finally {
      if (mounted) setState(() => _loadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.item.imageUrl ?? FoodImages.getImage(widget.item.name);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: darkGreen),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            ClipPath(
              clipper: BottomCurveClipper(),
              child: Container(
                height: 300,
                width: double.infinity,
                color: const Color(0xFFF5F5F5),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.name,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          height: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87)),
                      const Row(
                        children: [
                          Text('4.9',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 4),
                          Icon(Icons.star, color: gold, size: 20),
                          SizedBox(width: 4),
                          Text('(120)',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGreen)),
                  const SizedBox(height: 8),
                  Text(
                      widget.item.description ??
                          'Delicious dish prepared with fresh ingredients.',
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),

                  // Add to cart
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context
                            .read<CartState>()
                            .addItem(widget.item.id, _quantity);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart!')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: gold, width: 2)),
                        elevation: 0,
                      ),
                      child: const Text('Add to Cart',
                          style: TextStyle(
                              color: gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Related Products
                  const Text('You may also like',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGreen)),
                  const SizedBox(height: 12),
                  _loadingRelated
                      ? const Center(
                          child: CircularProgressIndicator(color: darkGreen))
                      : _related == null || _related!.isEmpty
                          ? const Text('No similar products',
                              style: TextStyle(color: Colors.black54))
                          : SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _related!.length,
                                itemBuilder: (context, index) {
                                  final r = _related![index];
                                  return GestureDetector(
                                    onTap: () => Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FoodDetailsScreen(item: r))),
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 8)
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            16)),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(16)),
                                                child: r.imageUrl != null
                                                    ? Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        child: Image.network(
                                                            r.imageUrl!,
                                                            fit: BoxFit.contain,
                                                            width: double
                                                                .infinity))
                                                    : const Icon(
                                                        Icons.restaurant,
                                                        color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(r.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color: Colors.black87),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                Text(
                                                    '\$${r.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                        color: darkGreen,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 40, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {
      'title': 'Pizza',
      'count': '25 items',
      'image':
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&q=80'
    },
    {
      'title': 'Salads',
      'count': '30 items',
      'image':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200&q=80'
    },
    {
      'title': 'Desserts',
      'count': '30 items',
      'image':
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200&q=80'
    },
    {
      'title': 'Pasta',
      'count': '44 items',
      'image':
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200&q=80'
    },
    {
      'title': 'Beverages',
      'count': '30 items',
      'image':
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=200&q=80'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ─── The Orange Vertical Stripe ───
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 80, // Width of the stripe
            child: Container(
              color: AppColors.primary,
            ),
          ),

          // ─── Content ───
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar (Menu Icon)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 32),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                    onPressed: () {},
                  ),
                ),

                // Category List
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 40), // Overlap the stripe
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () {
                          // Note: In a full app, this navigates to a filtered list of restaurants
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Opening ${cat['title']} category...')),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              // Text & Button Area
                              Padding(
                                padding: const EdgeInsets.only(left: 80),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat['title'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textMain,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cat['count'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Right Arrow Button
                                    Container(
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.arrow_forward_ios,
                                          color: AppColors.primary, size: 16),
                                    ),
                                  ],
                                ),
                              ),

                              // Floating Circular Image
                              Positioned(
                                left: -20, // Pushes it out of the card
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: NetworkImage(cat['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

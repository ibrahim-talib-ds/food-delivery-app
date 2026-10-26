class FoodImages {
  static String getImage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('burger')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80';
    }
    if (lower.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80';
    }
    if (lower.contains('salad')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80';
    }
    if (lower.contains('fries') || lower.contains('side')) {
      return 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&q=80';
    }
    if (lower.contains('chicken') || lower.contains('wing')) {
      return 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=600&q=80';
    }
    if (lower.contains('pasta') || lower.contains('noodle')) {
      return 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80';
    }
    if (lower.contains('coffee') ||
        lower.contains('drink') ||
        lower.contains('lemonade')) {
      return 'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=600&q=80';
    }
    if (lower.contains('cake') ||
        lower.contains('brownie') ||
        lower.contains('dessert')) {
      return 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=600&q=80';
    }
    if (lower.contains('taco')) {
      return 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600&q=80';
    }
    return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&q=80'; // Generic food
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'location_state.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  static const darkGreen = Color(0xFF0D2B1A);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);
    try {
      // Nominatim Search API - free, no key required
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=15',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'FoodDeliveryApp/1.0 (contact@fooddelivery.app)',
      });

      if (response.statusCode == 200) {
        setState(() => _results = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  Future<void> _selectPlace(dynamic place) async {
    final address = place['address'] ?? {};
    final city = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['county'] ??
        'Unknown';
    final country = address['country'] ?? 'Unknown';
    final displayName = place['display_name'] ?? '$city, $country';

    await context.read<LocationState>().updateLocation(
          newCountry: country,
          newCity: city,
          newPlace: displayName,
          authState: context.read(),
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: darkGreen,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search any city, country or place...',
                  hintStyle: const TextStyle(color: Colors.black45),
                  prefixIcon: const Icon(Icons.search, color: darkGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: darkGreen),
                          ),
                        )
                      : _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.black45),
                              onPressed: () {
                                _controller.clear();
                                setState(() => _results = []);
                              },
                            )
                          : null,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public, size: 80, color: Colors.black26),
                          SizedBox(height: 16),
                          Text(
                            'Search Anywhere in the World',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Type 3+ letters to find your city, country or neighborhood',
                            style: TextStyle(color: Colors.black38),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      final displayName = place['display_name'] ?? '';
                      final type = place['type'] ?? 'place';
                      final address = place['address'] ?? {};
                      final country = address['country'] ?? '';

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F0EA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              type == 'country'
                                  ? Icons.flag
                                  : type == 'city' || type == 'administrative'
                                      ? Icons.location_city
                                      : Icons.place,
                              color: darkGreen,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            displayName.split(',').first.trim(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            country.isNotEmpty
                                ? displayName
                                    .replaceAll(
                                        displayName.split(',').first, '')
                                    .replaceAll(RegExp(r'^,\s*'), '')
                                : displayName,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.black38),
                          onTap: () => _selectPlace(place),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

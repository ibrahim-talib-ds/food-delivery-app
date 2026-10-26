import 'package:flutter/foundation.dart';
import '../../shared/services/api_client.dart';
import '../auth/auth_state.dart';

class LocationState extends ChangeNotifier {
  String country = '';
  String city = '';
  String place = '';
  String fullAddress = '';

  String get fullLocation =>
      place.isNotEmpty ? '$place, $city' : '$city, $country';

  Future<void> updateLocation({
    required String newCountry,
    required String newCity,
    required String newPlace,
    AuthState? authState,
  }) async {
    country = newCountry;
    city = newCity;
    place = newPlace;
    fullAddress = '$newPlace, $newCity, $newCountry';
    notifyListeners();

    try {
      await ApiClient.patch('/auth/me', {
        'city': newCity,
        'country': newCountry,
        'place': newPlace,
        'full_address': fullAddress,
      });
      // Refresh AuthState so Profile shows the new address
      if (authState != null) {
        await authState.refreshUser();
      }
    } catch (e) {
      debugPrint('Failed to save location: $e');
    }
  }

  void loadFromUser({String? country, String? city, String? place}) {
    this.country = country ?? '';
    this.city = city ?? '';
    this.place = place ?? '';
    fullAddress = [place, city, country]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');
    notifyListeners();
  }
}

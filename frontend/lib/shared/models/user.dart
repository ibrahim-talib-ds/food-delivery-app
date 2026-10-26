class AppUser {
  final int id;
  final String phone;
  final String? email;
  final String fullName;
  final String role;
  final String? city;
  final String? country;
  final String languagePref;

  AppUser({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
    this.city,
    this.country,
    required this.languagePref,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        phone: j['phone'],
        email: j['email'],
        fullName: j['full_name'],
        role: j['role'],
        city: j['city'],
        country: j['country'],
        languagePref: j['language_pref'] ?? 'en',
      );
}

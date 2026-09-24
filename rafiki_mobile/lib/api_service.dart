// rafiki_mobile/lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final url = Uri.parse('$baseUrl/search/categories');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load categories (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getServices({
    String? query,
    String? category,
    String? county,
    String? subCounty,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool verifiedOnly = false,
    String sort = 'rating_desc',
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
      'offset': offset.toString(),
      'verified_only': verifiedOnly.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (category != null) params['category'] = category;
    if (county != null) params['county'] = county;
    if (subCounty != null) params['sub_county'] = subCounty;
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (minRating != null) params['min_rating'] = minRating.toString();

    final uri = Uri.parse('$baseUrl/search/services').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load services (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = _safeJson(response.body);
    throw Exception(body['detail'] ?? 'Login failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String county = 'Nairobi',
    String? subCounty,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'role': role,
        'county': county,
        'sub_county': subCounty,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = _safeJson(response.body);
    throw Exception(body['detail'] ?? 'Registration failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createBooking({
    required String token,
    required int serviceId,
    required String bookingType,
    DateTime? scheduledAt,
    String? address,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'service_id': serviceId,
      'booking_type': bookingType,
    };
    if (scheduledAt != null) body['scheduled_at'] = scheduledAt.toUtc().toIso8601String();
    if (address != null) body['address'] = address;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = _safeJson(response.body);
    throw Exception(err['detail']?.toString() ?? 'Booking failed (${response.statusCode})');
  }

  static Future<List<dynamic>> getMyBookings({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load bookings (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> initiateSTKPush({
    required String token,
    required String bookingReference,
    required String phone,
    String paymentType = 'full',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stkpush'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'booking_reference': bookingReference,
        'payment_type': paymentType,
        'phone': phone,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = _safeJson(response.body);
    throw Exception(err['detail']?.toString() ?? 'Payment failed (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getWhatsAppLink(String bookingReference) async {
    final response = await http.get(Uri.parse('$baseUrl/whatsapp/$bookingReference'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('WhatsApp link failed (${response.statusCode})');
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
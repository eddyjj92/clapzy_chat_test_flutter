// Archivo: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://backend.clapzy.app/api';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    print(email);
    print(password);
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'token': data['token'],
        'user': data['user'], // Evita crash si 'id' no existe
      };
    }
    return {'success': false};
  }

  static Future<Map<String, dynamic>> getUser(userId, token) async {
    final url = Uri.parse('$baseUrl/users/$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data['user']);
      return {
        'success': true,
        'user': data['user'], // Evita crash si 'id' no existe
      };
    }
    return {'success': false};
  }

  static Future<Map<String, dynamic>> getChatMessages(senderId, token) async {
    final url = Uri.parse('$baseUrl/chat_messages?sender_id=$senderId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data['messages']);

      final Map<String, int> unreadMessages = (data['not_read_messages'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
      ) ?? {};
      return {
        'success': true,
        'messages': data['messages'],
        'not_read_messages': unreadMessages,
      };
    }
    return {'success': false};
  }
}
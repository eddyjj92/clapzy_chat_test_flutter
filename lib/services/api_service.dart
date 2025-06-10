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
    Uri url = Uri.parse('$baseUrl/chat_messages');
    if(senderId != null){
      url = Uri.parse('$baseUrl/chat_messages?sender_id=$senderId');
    }
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

      Map<String, int> unreadMessages;
      try {
        unreadMessages = (data['not_read_messages'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toInt()),
        ) ?? {};
      } catch (e) {
        unreadMessages = {};
      }

      return {
        'success': true,
        'messages': data['messages'],
        'not_read_messages': unreadMessages,
      };
    }
    return {'success': false};
  }

  static Future<Map<String, dynamic>> markMessagesAsRead(int senderId, String token) async {
    print(senderId);
    print(token);
    final url = Uri.parse('$baseUrl/chat_messages/mark_as_read');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'sender_id': senderId,}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'],
      };
    }
    print(response.body);
    return {
      'success': false
    };
  }
}
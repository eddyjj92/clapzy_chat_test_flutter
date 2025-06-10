// Archivo: lib/providers/chat_provider.dart
import 'dart:convert';

import 'package:clapzy_chat_test_flutter/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _usersOnline = [];
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get usersOnline => _usersOnline;
  int get cantUsersOnline => _usersOnline.length;
  List<Map<String, dynamic>> get messages => _messages;
  bool isLoadingMessages = false;
  int? receiverId;
  Map<String, int> unreadMessagesCount = {};


  void addUser(String id, [String? token]) async {
    final user = await ApiService.getUser(id, token);
    print('user: $user');
    _usersOnline.add(user['user']);
    notifyListeners();
  }

  void removeUser(String id) {
    _usersOnline.removeWhere((user) => user['id'].toString() == id);
    notifyListeners();
  }

  void addMessage(String message, int senderId, receiverId,[String? token]) {
    _messages.add({
      "text" : message,
      "user_id": senderId,
    });
    notifyListeners();
    if(token != null){
      sendMessage(message, receiverId, token);
    }
  }

  Future<void> loadMessages(int? senderId, String token) async {
    try {
      isLoadingMessages = true;
      dynamic messagesFromApi = await ApiService.getChatMessages(null, token);
      if(senderId != null){
        messagesFromApi = await ApiService.getChatMessages(senderId, token);
      }

      final List<dynamic> rawMessages = messagesFromApi["messages"] ?? [];
      unreadMessagesCount = messagesFromApi["not_read_messages"];
      print(unreadMessagesCount);

      final List<Map<String, dynamic>> parsedMessages = rawMessages.map((msg) {
        return {
          'text': msg['text'].toString(),
          'user_id': msg['sender_id'], // asignas senderId aquí
        };
      }).toList();

      _messages.clear();
      _messages.addAll(parsedMessages);

      debugPrint(_messages.toString());

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando mensajes: $e');
    } finally {
      isLoadingMessages = false;
      notifyListeners();
    }
  }

  void setReceiverID(id){
    receiverId = id;
    notifyListeners();
  }

  void setUnreadMessagesCount(unreadMessagesCountUpdated){
    unreadMessagesCount = unreadMessagesCountUpdated;
    notifyListeners();
  }

  void clear() {
    _usersOnline.clear();
    _messages.clear();
  }

  // Enviar un mensaje al canal
  Future<void> sendMessage(text, receiverId, authToken) async {
    if (text.isEmpty) return;

    // Enviar el mensaje al backend
    try {
      final response = await http.post(
        Uri.parse('https://backend.clapzy.app/api/chat_messages/send_private'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({"message": text, "receiver_id": receiverId}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error al enviar mensaje: ${response.body}');
      }
    } catch (e) {
      debugPrint('Excepción al enviar mensaje: $e');
    }
  }
}


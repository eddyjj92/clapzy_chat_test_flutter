import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/ws_service.dart';
import 'chat_provider.dart';

class AuthProvider with ChangeNotifier {
  String? token;
  dynamic user;
  late WsService wsService;

  bool get isAuthenticated => token != null;

  Future<bool> login(String email, String password) async {
    final response = await ApiService.login(email, password);
    if (response['success'] == true && response['token'] != null && response['token'].toString().isNotEmpty) {
      token = response['token'];
      user = response['user'];
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    token = null;
    user = null;
    wsService.dispose();
    notifyListeners();
  }

}

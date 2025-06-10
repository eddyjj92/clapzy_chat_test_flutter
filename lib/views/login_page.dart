// Archivo: lib/views/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/ws_service.dart';
import 'chat_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Clapzy Chat Test",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () async {
                  setState(() => isLoading = true);

                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                  final success = await authProvider.login(emailController.text, passwordController.text);
                  setState(() => isLoading = false);

                  if (success && context.mounted) {

                    final token = authProvider.token!;
                    final userId = authProvider.user['id']!;
                    final wsService = WsService(token, userId);
                    authProvider.wsService = wsService;

                    wsService.connect(
                      onNewPrivateChatMessage: (message, senderId) {
                        if(chatProvider.receiverId == senderId){
                          chatProvider.addMessage(message, senderId, authProvider.user["id"] );
                        }
                      },
                      onNewPrivateChatNotificationMessage: (message) {
                        print(message);
                      },
                      onSubscriptionSucceeded: (data, total) {
                        for (var id in data["presence"]["ids"]) {
                          if(int.parse(id) != authProvider.user["id"]){
                            chatProvider.addUser(id, authProvider.token);
                          }
                        }
                      },
                      onMemberAdded: (userId, total) {
                        chatProvider.addUser(userId, token);
                      },
                      onMemberRemoved: (userId, total) {
                        chatProvider.removeUser(userId);
                      },
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatPage()),
                    );
                  } else {
                    showError('Email o contraseña incorrectos');
                  }
                },
                child: const Text("Iniciar sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

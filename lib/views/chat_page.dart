import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/ws_service.dart';
import 'login_page.dart';

class ChatPage extends StatefulWidget  {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _sendMessageController;
  bool _loadedMessages = false;


  @override
  void initState() {
    super.initState();
    _sendMessageController = TextEditingController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (!_loadedMessages && chatProvider.receiverId != null) {
      chatProvider.loadMessages(chatProvider.receiverId!, authProvider.token!);
      _loadedMessages = true;
    }else if(!_loadedMessages){
      chatProvider.loadMessages(null, authProvider.token!);
      _loadedMessages = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _sendMessageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    chatProvider.addMessage(trimmed, authProvider.user["id"], chatProvider.receiverId!, authProvider.token!);
    _sendMessageController.clear();
    _scrollToBottom();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Clapzy"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              chatProvider.clear();
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Usuarios conectados: ${chatProvider.cantUsersOnline}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: chatProvider.usersOnline.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  clipBehavior: Clip.none, // Permite que el badge se muestre fuera de los límites
                  children: [
                    ActionChip(
                      backgroundColor: Colors.greenAccent,
                      avatar: chatProvider.usersOnline[index]['id'] == chatProvider.receiverId
                          ? Icon(Icons.check, color: Colors.white)
                          : null,
                      label: Text(
                        chatProvider.usersOnline[index]['referred_code']?.toString() ?? 'Loading...',
                      ),
                      onPressed: () {
                        print('Chip clickeado: ${chatProvider.usersOnline[index]['id']}');
                        chatProvider.setReceiverID(chatProvider.usersOnline[index]['id']);
                        chatProvider.loadMessages(
                          chatProvider.receiverId!,
                          authProvider.token!,
                        );
                      },
                    ),
                    if ((chatProvider.unreadMessagesCount[chatProvider.usersOnline[index]['id'].toString()] ?? 0) > 0)
                      Positioned(
                        top: 0,
                        right: -5,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${chatProvider.unreadMessagesCount[chatProvider.usersOnline[index]['id'].toString()]}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                )

                ,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: chatProvider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final msg = chatProvider.messages[index];
                  final isMine = msg["user_id"] == authProvider.user["id"];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisAlignment:
                      isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft:
                              Radius.circular(isMine ? 12 : 0),
                              bottomRight:
                              Radius.circular(isMine ? 0 : 12),
                            ),
                          ),
                          child: Text(
                            msg["text"] ?? '',
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: chatProvider.receiverId != null,  // Deshabilita si receiverId es null
                    controller: _sendMessageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _sendMessage(_sendMessageController.text),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class WsService {
  final String authToken;
  final int userId;
  late PusherChannelsClient client;
  late PrivateChannel privateChannel;
  late PresenceChannel presenceChannel;

  StreamSubscription? connectionSub;
  StreamSubscription? privateMessageSub;
  StreamSubscription? presenceSucSub;
  StreamSubscription? presenceAddSub;
  StreamSubscription? presenceRemoveSub;

  WsService(this.authToken, this.userId);

  Future<void> connect({
    required Function(String message, int senderId) onNewPrivateMessage,
    required Function(Map<String, dynamic> userId, int total) onSubscriptionSucceeded,
    required Function(String userId, int total) onMemberAdded,
    required Function(String userId, int total) onMemberRemoved,
  }) async {
    PusherChannelsPackageLogger.enableLogs();

    const options = PusherChannelsOptions.fromHost(
      scheme: 'wss',
      host: 'backend.clapzy.app',
      key: '4lxc44meoqyije58ptrr',
      port: 443,
      shouldSupplyMetadataQueries: true,
      metadata: PusherChannelsOptionsMetadata.byDefault(),
    );

    client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        debugPrint('Error de conexión: $exception');
        await Future.delayed(const Duration(seconds: 5));
        refresh();
      },
    );


    privateChannel = client.privateChannel(
      'private-chat.$userId',
      authorizationDelegate:
      EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint:
        Uri.parse('https://backend.clapzy.app/api/broadcasting/auth'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
    );

    presenceChannel = client.presenceChannel(
      'presence-online',
      authorizationDelegate:
      EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
        authorizationEndpoint:
        Uri.parse('https://backend.clapzy.app/api/broadcasting/auth'),
        headers: {'Authorization': 'Bearer $authToken'},
      ),
    );

    privateMessageSub = privateChannel.bind('private-message').listen((event) {
      final data = jsonDecode(event.data);
      onNewPrivateMessage(data['message'], data['sender']['id']);
    });

    presenceSucSub = presenceChannel.whenSubscriptionSucceeded().listen((event) {
      print('event.data');
      print(jsonDecode(event.data)["presence"]);
      final count = presenceChannel.state?.members?.membersCount ?? 0;
      print(count);
      onSubscriptionSucceeded(jsonDecode(event.data), count);
    });

    presenceAddSub = presenceChannel.whenMemberAdded().listen((event) {
      print('event.data');
      print(event.data);
      print(event.data['user_id']);
      final count = presenceChannel.state?.members?.membersCount ?? 0;
      onMemberAdded(event.data['user_id'], count);
    });

    presenceRemoveSub = presenceChannel.whenMemberRemoved().listen((event) {
      print('event.data');
      print(event.data);
      print(event.data['user_id']);
      final count = presenceChannel.state?.members?.membersCount ?? 0;
      onMemberRemoved(event.data['user_id'], count);
    });

    connectionSub = client.onConnectionEstablished.listen((_) {
      privateChannel.subscribeIfNotUnsubscribed();
      presenceChannel.subscribeIfNotUnsubscribed();
    });

    unawaited(client.connect());
  }

  Future<void> sendMessage(String message, String receiverId) async {
    final url = Uri.parse('https://backend.clapzy.app/api/ws/chat/send-private');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({"message": message, "receiver_id": receiverId}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error al enviar mensaje: ${response.body}');
      }
    } catch (e) {
      debugPrint('Excepción al enviar mensaje: $e');
    }
  }

  void dispose() {
    connectionSub?.cancel();
    privateMessageSub?.cancel();
    presenceAddSub?.cancel();
    presenceRemoveSub?.cancel();
    client.dispose();
  }
}

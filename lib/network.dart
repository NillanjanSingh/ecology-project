import 'dart:async';
import 'package:ecology_project/log.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkManager {
  WebSocketChannel? channel;
  final String mDnsHostname;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  Function(String status)? onStatusUpdate;

  NetworkManager({this.mDnsHostname = "gigachad-esp.local"});

  Future<String?> resolveMdns(String hostname) async {
    final MDnsClient client = MDnsClient();
    await client.start();

    String? resolvedIp;

    try {
      await for (final IPAddressResourceRecord record
          in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(hostname),
          )) {
        resolvedIp = record.address.address;
        break;
      }
    } catch (e) {
      logger.e("mDNS Lookup failed: $e");
    } finally {
      client.stop();
    }

    return resolvedIp;
  }

  Future<String?> connect() async {
    try {
      onStatusUpdate?.call("Resolving $mDnsHostname...");
      String? ipAddress = await resolveMdns(mDnsHostname);

      if (ipAddress == null) {
        onStatusUpdate?.call("Failed to resolve $mDnsHostname");
        return null;
      }

      onStatusUpdate?.call("Connecting to $ipAddress...");

      channel = WebSocketChannel.connect(Uri.parse('ws://$ipAddress:81'));

      channel!.stream.listen(
        (message) {
          logger.i("RECEIVED: $message");
          _messageController.add(message.toString());
        },
        onError: (error) {
          logger.e("WS ERROR: $error");
          onStatusUpdate?.call("Error: $error");
        },
        onDone: () {
          logger.i("WS CLOSED");
          onStatusUpdate?.call("Connection closed");
        },
      );

      onStatusUpdate?.call("Connected via $ipAddress");
      return ipAddress;
    } catch (e) {
      onStatusUpdate?.call("Connection failed: $e");
      return null;
    }
  }

  void sendMessage(String message) {
    if (channel != null && message.isNotEmpty) {
      channel!.sink.add(message);
    }
  }

  void dispose() {
    channel?.sink.close();
    _messageController.close();
  }
}

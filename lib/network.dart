import 'package:ecology_project/log.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkManager {
  WebSocketChannel? channel;
  final String mDnsHostname;

  NetworkManager({this.mDnsHostname = "gigachad-esp.local"});

  Future<String?> resolveMdns(String hostname) async {
    final MDnsClient client = MDnsClient();
    await client.start();

    String? resolvedIp;

    try {
      // Look up the IPv4 address for the given hostname
      await for (final IPAddressResourceRecord record
          in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(hostname),
          )) {
        resolvedIp = record.address.address;
        break; // Stop after finding the first match
      }
    } catch (e) {
      logger.e("mDNS Lookup failed: $e");
    } finally {
      client.stop();
    }

    return resolvedIp;
  }

  Future<String?> connect({
    required Function(String status) onStatus,
    required Function(String message) onMessage,
    required Function(String error) onError,
    required Function() onDone,
  }) async {
    try {
      onStatus("Resolving $mDnsHostname...");
      String? ipAddress = await resolveMdns(mDnsHostname);

      if (ipAddress == null) {
        onStatus("Failed to resolve $mDnsHostname");
        return null;
      }

      onStatus("Connecting to $ipAddress...");

      channel = WebSocketChannel.connect(Uri.parse('ws://$ipAddress/ws'));

      channel!.stream.listen(
        (message) {
          logger.i("RECEIVED: $message");
          onMessage(message.toString());
        },
        onError: (error) {
          logger.e("WS ERROR: $error");
          onError(error.toString());
        },
        onDone: () {
          logger.i("WS CLOSED");
          onDone();
        },
      );

      onStatus("Connected via $ipAddress");
      return ipAddress;
    } catch (e) {
      onStatus("Connection failed: $e");
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
  }
}

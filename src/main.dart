import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'controller/guild_controller.dart';
import 'controller/player_controller.dart';

final playerController = PlayerController();
final guildController = GuildController();

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print(
    'The server is running on http://${server.address.address}:${server.port}',
  );

  await playLoop(server);
}

Future<void> playLoop(HttpServer server) async {
  await for (HttpRequest request in server) {
    try {
      await routeRequest(request);
    } catch (e) {
      print("Routing error: $e");
    }
  }
}

Future<void> routeRequest(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  print('Request received: ${request.method} ${request.uri.path}');

  if (segments.isEmpty) {
    request.response.write('Main page');
    await request.response.close();
    return;
  }

  switch (segments[0]) {
    case 'status':
      await getStatusAsync(request);
      break;

    case 'player':
      await playerController.handleRequest(request, segments);
      break;

    case 'guild':
      await guildController.handleRequest(request, segments);
      break;

    default:
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('The section was not found.');
      await request.response.close();
  }
}

Future<void> getStatusAsync(HttpRequest request) async {
  final serverStatus = {
    'status': 'online',
    'playersCount': Random().nextInt(100),
    'version': '1.0.8',
  };

  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(serverStatus));
  await request.response.close();
}

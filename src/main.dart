import 'dart:convert';
import 'dart:io';
import 'controller/player_controller.dart';

final playerController = PlayerController();

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
      print("Критическая ошибка роутинга: $e");
    }
  }
}

Future<void> routeRequest(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  print('Request received: ${request.method} ${request.uri.path}');

  if (segments.isEmpty) {
    request.response.write('Главная страница');
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

    default:
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Упс! Раздел не найден.');
      await request.response.close();
  }
}

Future<void> getStatusAsync(HttpRequest request) async {
  final serverStatus = {
    'status': 'online',
    'playersCount': 42,
    'version': '1.0.5',
  };

  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(serverStatus));
  await request.response.close();
}

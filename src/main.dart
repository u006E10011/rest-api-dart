import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'player_model.dart';
import 'test_data.dart';

final nick = Nick();

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('The server is running on http://${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    handleRequest(request);
  }
}

Future<void> handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  print('Получен запрос: $method $path');

  if (path == '/status' && method == 'GET') {
    getStatusAsync(request);
  } else if (path == "/player" && method == "GET") {
    getPlayerDataAsync(request);
  } else if (path == "/player" && method == "POST") {
    addPlayerAsync(request);
  } else {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Упс! Страница не найдена.');
    await request.response.close();
  }
}

// GET
Future<void> getStatusAsync(HttpRequest request) async {
  final serverStatus = {
    'status': 'online',
    'playersCount': 42,
    'version': '1.0.4',
  };

  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(serverStatus));
  await request.response.close();
}

Future<void> getPlayerDataAsync(HttpRequest request) async {
  final data = PlayerModel(
    name: nick.getRadnomNick(),
    level: Random().nextInt(100),
    inventory: Inventory().addItem(TestInventory().inventory!)
  );

  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(data.toJson()));
  await request.response.close();
}

// POST
Future<void> addPlayerAsync(HttpRequest request) async {
  try {
    final body = await utf8.decodeStream(request);
    final Map<String, dynamic> data = jsonDecode(body);
    final String name = data['name'];

    if (name.isNotEmpty) {
      nick.addNick(name);

      request.response
        ..statusCode = HttpStatus.created
        ..write(
          jsonEncode({
            "status": 201,
            "message": "Ник $name успешно добавлен!",
          }),
        );
    }
  } on FormatException {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode({"error": "Некорректный формат JSON"}));
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({"error": "Internal server error"}));
  } finally {
    await request.response.close();
  }
}

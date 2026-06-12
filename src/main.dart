import 'dart:convert';
import 'dart:io';
import 'debug.dart';
import 'player_model.dart';
import 'test_data.dart';

final nick = Nick();
final playerDatabase = PlayerDatabase();
final debug = Debug();

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print(
    'The server is running on http://${server.address.address}:${server.port}',
  );

  await for (HttpRequest request in server) {
    handleRequest(request);
  }
}

Future<void> handleRequest(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final method = request.method;

  print('Request received: $method ${request.uri.path}');

  if (segments.isNotEmpty && method == "GET") {
    if (segments[0] == 'status') {
      getStatusAsync(request);
    } else if (segments[0] == 'player' && segments.length == 2) {
      getPlayerDataAsync(request, segments[1]);
    }
  } else if (segments.isNotEmpty && method == "POST") {
    if (segments[0] == "player") {
      addPlayerAsync(request);
    }
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

Future<void> getPlayerDataAsync(HttpRequest request, String id) async {
  var player = playerDatabase.getPlayerById(id);

  if (player == null) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write({"error": "Player by id ($id) no found"});

    await request.response.close();
    return;
  }

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(player.toJson()));
  await request.response.close();
}

// POST
Future<void> addPlayerAsync(HttpRequest request) async {
  try {
    final body = await utf8.decodeStream(request);
    final Map<String, dynamic> data = jsonDecode(body);
    final player = PlayerModel(
      id: playerDatabase.getNewId(),
      name: data['name'],
      level: data['level'],
      inventory: Inventory(data['inventory']),
    );

    if (player.name.isNotEmpty) {
      playerDatabase.addPlayer(player);

      request.response
        ..statusCode = HttpStatus.created
        ..write(
          jsonEncode(debug.send({
            "status": 201,
            "message": "Ник ${player.name} успешно добавлен!",
          })),
        );
    }
  } on FormatException {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode(debug.send({"error": "Некорректный формат JSON"})));
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode(debug.send({"error": "Internal server error"})));
  } finally {
    await request.response.close();
  }
}

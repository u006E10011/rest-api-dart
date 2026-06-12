import 'dart:convert';
import 'dart:io';
import '../debug.dart';
import '../model/database_model.dart';
import '../model/player_model.dart';

class PlayerController {
  final Database<PlayerModel> _db = Database<PlayerModel>();
  final debug = Debug();

  Future<void> handleRequest(HttpRequest request, List<String> segments) async {
    final method = request.method;

    if (method == 'GET' &&
        segments.length == 2 &&
        int.tryParse(segments[1]) != null) {
      await _getById(request, segments[1]);
    } else if (method == 'POST' &&
        segments.length == 2 &&
        segments[1] == 'create') {
      await _create(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(
          jsonEncode(debug.send({"error": "Маршрут в /player не найден"})),
        );
      await request.response.close();
    }
  }

  Future<void> _getById(HttpRequest request, String id) async {
    final player = _db.getById(id);

    if (player == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(
          jsonEncode(debug.send({"message": "Player by id ($id) not found"})),
        );
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(debug.send(player.toJson())));
    await request.response.close();
  }

  Future<void> _create(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(body);

      final player = PlayerModel(
        id: _db.getNewId(),
        name: data['name'],
        level: data['level'],
        inventory: Inventory(data['inventory']),
      );

      if (player.name.isNotEmpty) {
        _db.add(player);

        request.response
          ..statusCode = HttpStatus.created
          ..write(
            jsonEncode(
              debug.send({
                "message": "Ник ${player.name}/${player.id} успешно добавлен!",
              }),
            ),
          );
      }
    } on FormatException {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode(debug.send({"message": "Некорректный формат JSON"})));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode(debug.send({"message": "Internal server error"})));
    } finally {
      await request.response.close();
    }
  }
}

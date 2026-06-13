import 'dart:convert';
import 'dart:io';
import '../utils/debug.dart';
import '../model/database_model.dart';
import '../model/player_model.dart';
import '../utils/extension.dart';

class PlayerController {
  final _db = Database<PlayerModel>(
    filePath: './data/player.json',
    fromJsonFactory: PlayerModel.fromJson,
  );
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
    } else if (method == 'PUT' &&
        segments.length == 2 &&
        int.tryParse(segments[1]) != null) {
      await _updatePut(request, segments[1]);
    } else if (method == 'PATCH' &&
        segments.length == 2 &&
        int.tryParse(segments[1]) != null) {
      await _updatePatch(request, segments[1]);
    } else if (method == 'DELETE' &&
        segments.length == 2 &&
        int.tryParse(segments[1]) != null) {
      await _delete(request, segments[1]);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(
          jsonEncode(
            debug.send({"error": "The route to /player was not found"}),
          ),
        );
      await request.response.close();
    }
  }

  // GET
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

  // POST
  Future<void> _create(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(body);

      if (await request.hasConflictTitle(_db, data['title'])) {
        return;
      }

      final player = PlayerModel(
        id: _db.getNewId(),
        title: data['title'],
        level: data['level'],
        inventory: Inventory(data['inventory']),
      );

      if (player.title.isNotEmpty) {
        _db.add(player);

        request.response
          ..statusCode = HttpStatus.created
          ..write(
            jsonEncode(
              debug.send({
                "message": "Ник ${player.title}/${player.id} успешно добавлен!",
              }),
            ),
          );
      }
    } on FormatException {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode(debug.formatException()));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode(debug.internalServerError()));
    } finally {
      await request.response.close();
    }
  }

  // PUT
  Future<void> _updatePut(HttpRequest request, String id) async {
    try {
      var item = _db.getById(id);

      if (item == null) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write(debug.send({"message": "Player not found by id: $id]"}));
        return;
      }

      if (await request.hasConflictTitle(_db, item.title)) {
        return;
      }

      final body = await utf8.decodeStream(request);
      final json = jsonDecode(body);
      final updateData = PlayerModel(
        id: id,
        title: json['title'] ?? '',
        level: json['level'] ?? "1",
        inventory: Inventory(json['inventory'] ?? {}),
      );

      _db.add(updateData);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
    } on FormatException {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode(debug.formatException()));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode(debug.internalServerError()));
    } finally {
      await request.response.close();
    }
  }

  // PATH
  Future<void> _updatePatch(HttpRequest request, String id) async {
    try {
      final player = _db.getById(id);

      if (player == null) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write(jsonEncode({"error": "Игрок не найден"}));
        return;
      }

      if (await request.hasConflictTitle(_db, player.title)) {
        return;
      }

      final body = await utf8.decodeStream(request);
      final Map<String, dynamic> data = jsonDecode(body);

      final updatedPlayer = PlayerModel(
        id: id,
        title: data['name'] ?? player.title,
        level: data['level'] ?? player.level,
        inventory: data['inventory'] != null
            ? Inventory(data['inventory'])
            : player.inventory,
      );

      _db.add(updatedPlayer);

      request.response
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode({"message": "Player data update (PATCH)"}));
    } catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(jsonEncode(debug.internalServerError()));
    } finally {
      await request.response.close();
    }
  }

  // DELETE
  Future<void> _delete(HttpRequest request, String id) async {
    final player = _db.getById(id);
    if (player == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(jsonEncode({"message": "Player not found"}));
      await request.response.close();
      return;
    }

    _db.delete(player);
    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({"message": "Player with ID $id deleted"}));
    await request.response.close();
  }
}

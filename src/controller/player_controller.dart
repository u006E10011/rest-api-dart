import 'dart:convert';
import 'dart:io';
import '../utils/debug.dart';
import '../model/database_model.dart';
import '../model/player_model.dart';

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

      if (data['title'].isNotEmpty) {
        bool hasTitle = false;
        _db.data.forEach(
          ((key, value) => {if (value.title == data['title']) hasTitle = true}),
        );

        if (hasTitle == false) {
          final player = PlayerModel(
            id: _db.getNewId(),
            title: data['title'],
            level: data['level'],
            inventory: Inventory(data['inventory']),
          );

          _db.add(player);

          request.response
            ..statusCode = HttpStatus.created
            ..write(
              jsonEncode(
                debug.send({
                  "message":
                      "Player ${player.title}/${player.id} successfully added!",
                }),
              ),
            );
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write(
              jsonEncode(
                debug.send({
                  "message":
                      "The player name is already taken [${data['title']}}]",
                }),
              ),
            );
        }
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
}

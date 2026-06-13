import 'dart:convert';
import 'dart:io';
import '../utils/debug.dart';
import '../model/database_model.dart';
import '../model/guild_model.dart';
import '../utils/extension.dart';

class GuildController {
  final _db = Database<GuildModel>(
    filePath: "./data/guild.json",
    fromJsonFactory: GuildModel.fromJson,
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
        segments[1] == "create") {
      await _create(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(
          jsonEncode(
            debug.send({"error": "The route to /guild was not found"}),
          ),
        );
      await request.response.close();
    }
  }

  // GET
  Future<void> _getById(HttpRequest request, String id) async {
    final guild = _db.getById(id);

    if (guild == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write(debug.send({'message': "Guild by id ($id) not found"}));
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..write(debug.send(guild.toJson()));

    await request.response.close();
  }

  // POST
  Future<void> _create(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final json = jsonDecode(body);
      final guild = GuildModel(id: _db.getNewId(), title: json['title']);

      if (await request.hasConflictTitle(_db, json['title'])) {
        return;
      }

      if (guild.title.isNotEmpty) {
        _db.add(guild);
        request.response
          ..statusCode = HttpStatus.created
          ..write(
            debug.send({
              'message': 'Register guild ${guild.title}/${guild.id}',
            }),
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
}

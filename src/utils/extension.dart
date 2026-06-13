import 'dart:convert';
import 'dart:io';
import '../model/database_model.dart';
import 'debug.dart';

extension HttpResponseHelpers on HttpRequest {
  Future<bool> hasConflictTitle(Database db, String? title) async {
    final cleanTitle = title ?? '';

    if (cleanTitle.isEmpty) {
      response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode(Debug().send({"message": "Title cannot be empty"})));

      await response.close();
      return true;
    }

    if (db.existingTitle(cleanTitle)) {
      response
        ..statusCode = HttpStatus.conflict
        ..write(jsonEncode(Debug().send({"message": "Existing title [$cleanTitle]"})));
      
      await response.close(); 
      return true;
    }

    return false;
  }
}

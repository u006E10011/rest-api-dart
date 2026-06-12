import 'dart:convert';
import 'dart:io';

abstract class Identifiable {
  String get id;
}

abstract class Describable {
  String get title;
}

class Database<T extends Identifiable> {
  final String filePath;
  final T Function(Map<String, dynamic>) fromJsonFactory;

  int index = 0;
  final Map<String, T> data = {};

  Database({required this.filePath, required this.fromJsonFactory}) {
    loadFromFileSync();
  }

  T? getById(String id) => data[id];

  void add(T item) {
    data[item.id] = item;
    saveToFile();
  }

  void delete(T item) {
    data.remove(item.id);
    saveToFile();
  }

  String getNewId() => (index++).toString();

  Future<void> saveToFile() async {
    final file = File(filePath);
    final Map<String, dynamic> rawData = data.map(
      (key, value) => MapEntry(key, (value as dynamic).toJson()),
    );
    await file.writeAsString(
      JsonEncoder.withIndent('  ').convert(rawData),
      mode: FileMode.write,
    );
    print("Save Database in $filePath");
  }

  void loadFromFileSync() {
    final file = File(filePath);
    if (!file.existsSync()) return;

    try {
      final content = file.readAsStringSync();
      if (content.isEmpty) return;

      final Map<String, dynamic> rawData = jsonDecode(content);

      rawData.forEach((key, value) {
        final item = fromJsonFactory(Map<String, dynamic>.from(value));
        data[key] = item;
      });

      if (data.isNotEmpty) {
        final ids = data.keys.map(int.parse);
        index = ids.reduce((curr, next) => curr > next ? curr : next) + 1;
      }
      print('Load Database in: $filePath (Find elements: ${data.length})');
    } catch (e) {
      print('Exception on load Database: $e');
    }
  }
}

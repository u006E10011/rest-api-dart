import 'database_model.dart';

class PlayerModel implements Identifiable {
  @override
  final String id;
  final String name;
  final int level;
  final Inventory inventory;

  PlayerModel({
    required this.id,
    required this.name,
    required this.level,
    required this.inventory,
  });

  PlayerModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      level = json['level'],
      inventory = json['inventory'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'inventory': inventory.toJson(),
    };
  }
}

class Inventory {
  final Map<String, int> _data = {};

  Inventory(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      _data.addAll(Map<String, int>.from(data));
    }
  }

  Map<String, int> toJson() => _data;

  int getitem(String id) {
    final count = _data[id];

    if (count != null && count > 0) {
      return count;
    }

    return 0;
  }

  Inventory addItem(Map<String, int> data) {
    if (data.isNotEmpty) {
      _data.addAll(data);
    }

    return this;
  }
}

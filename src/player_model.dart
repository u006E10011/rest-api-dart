class PlayerModel {
  final String name;
  final int level;
  final Inventory inventory;

  PlayerModel({
    required this.name,
    required this.level,
    required this.inventory,
  });

  PlayerModel.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      level = json['level'],
      inventory = json['inventory'];

  Map<String, dynamic> toJson() {
    return {'name': name, 'level': level, 'inventory': inventory.toJson()};
  }
}

class Inventory {
  final Map<String, int> data = {};

  Map<String, int> toJson() => data;

  int getitem(String id) {
    final count = data[id];

    if (count != null && count > 0) {
      return count;
    }

    return 0;
  }

  Inventory addItem(Map<String, int> data) {
    if (data.isNotEmpty) {
      data.addAll(data);
    }

    return this;
  }
}

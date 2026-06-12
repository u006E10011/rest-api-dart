abstract class Identifiable {
  String get id;
}

abstract class Describable {
  String get title;
}

class Database<T extends Identifiable> {
  int index = 0;
  final Map<String, T> _data = {};

  T? getById(String id) {
    return _data[id];
  }

  void add(T item) {
    _data[item.id] = item;
  }

  String getNewId() {
    return (index++).toString();
  }
}

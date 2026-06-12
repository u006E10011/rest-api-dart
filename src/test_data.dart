import 'dart:math';

class Nick {
  var nicks = [
    "ShadowBlade",
    "NeonRider",
    "CyberPanda",
    "IronGhost",
    "MidnightSun",
    "StarHunter",
    "SilentStorm",
    "PixelViking",
    "MysticRaven",
    "FrostBite",
  ];

  String getRadnomNick() {
    if (nicks.isEmpty) {
      return "Anonymous";
    }

    return nicks[Random().nextInt(nicks.length)];
  }

  void addNick(String nick) {
    if (nick.isNotEmpty) {
      nicks.add(nick);
    }
  }
}

class TestInventory {
  Map<String, int>? inventory;

  TestInventory() {
    inventory ??= {"Sword": 2, "Kit": 4, "Bow": 1, "Arrow": 34};
  }

  int getitem(String id) {
    final count = inventory?[id];

    if (count != null && count > 0) {
      return count;
    }

    return 0;
  }

  Map<String, int> getRareItems() {
    final list = inventory!.entries.where((x) => x.value > 2);
    return Map.fromEntries(list);
  }


}

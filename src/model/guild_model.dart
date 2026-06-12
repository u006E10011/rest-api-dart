import 'database_model.dart';

class GuildModel implements Identifiable, Describable {
  @override
  final String id;
  @override
  final String title;

  GuildModel({required this.id, required this.title});

  GuildModel.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'];

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }
}

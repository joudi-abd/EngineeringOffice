import 'package:ufuq_imperium/core/utils/json_utils.dart';

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.icon,
    this.imageUrl,
    this.active = true,
  });

  final int id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? icon;
  final String? imageUrl;
  final bool active;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
    id: jsonInt(json['id']),
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    shortDescription: jsonString(json['short_description']),
    description: jsonString(json['description']),
    icon: jsonString(json['icon']),
    imageUrl: jsonString(json['image_url']),
    active: json.containsKey('is_active') ? jsonBool(json['is_active']) : true,
  );

  Service copyWith({
    String? name,
    String? shortDescription,
    String? description,
  }) => Service(
    id: id,
    name: name ?? this.name,
    slug: slug,
    shortDescription: shortDescription ?? this.shortDescription,
    description: description ?? this.description,
    icon: icon,
    imageUrl: imageUrl,
    active: active,
  );
}

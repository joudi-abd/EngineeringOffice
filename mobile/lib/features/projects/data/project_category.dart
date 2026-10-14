import 'package:ufuq_imperium/core/utils/json_utils.dart';

class ProjectCategory {
  const ProjectCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.active = true,
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool active;

  factory ProjectCategory.fromJson(Map<String, dynamic> json) =>
      ProjectCategory(
        id: jsonInt(json['id']),
        name: '${json['name'] ?? ''}',
        slug: '${json['slug'] ?? ''}',
        description: jsonString(json['description']),
        active: json.containsKey('is_active')
            ? jsonBool(json['is_active'])
            : true,
      );

  ProjectCategory copyWith({String? name, String? description}) =>
      ProjectCategory(
        id: id,
        name: name ?? this.name,
        slug: slug,
        description: description ?? this.description,
        active: active,
      );
}

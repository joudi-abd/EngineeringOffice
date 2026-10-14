import 'package:ufuq_imperium/core/utils/json_utils.dart';

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.jobTitle,
    this.bio,
    this.image,
    this.imageUrl,
    this.active = true,
  });

  final int id;
  final String name;
  final String jobTitle;
  final String? bio;
  final String? image;
  final String? imageUrl;
  final bool active;

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: jsonInt(json['id']),
    name: '${json['name'] ?? ''}',
    jobTitle: '${json['job_title'] ?? ''}',
    bio: jsonString(json['bio']),
    image: jsonString(json['image']),
    imageUrl: jsonString(json['image_url']),
    active: json.containsKey('is_active') ? jsonBool(json['is_active']) : true,
  );

  TeamMember copyWith({String? name, String? jobTitle, String? bio}) =>
      TeamMember(
        id: id,
        name: name ?? this.name,
        jobTitle: jobTitle ?? this.jobTitle,
        bio: bio ?? this.bio,
        image: image,
        imageUrl: imageUrl,
        active: active,
      );
}

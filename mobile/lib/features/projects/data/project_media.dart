import 'package:ufuq_imperium/core/utils/json_utils.dart';

class ProjectImage {
  const ProjectImage({
    required this.id,
    required this.path,
    this.url,
    this.alt,
  });
  final int id;
  final String path;
  final String? url;
  final String? alt;

  factory ProjectImage.fromJson(Map<String, dynamic> json) => ProjectImage(
    id: jsonInt(json['id']),
    path: '${json['image_path'] ?? ''}',
    url: jsonString(json['image_url']),
    alt: jsonString(json['alt_text']),
  );

  ProjectImage copyWith({String? alt}) =>
      ProjectImage(id: id, path: path, url: url, alt: alt ?? this.alt);
}

class ProjectVideo {
  const ProjectVideo({
    required this.id,
    this.title,
    this.path,
    this.url,
    this.externalUrl,
  });
  final int id;
  final String? title;
  final String? path;
  final String? url;
  final String? externalUrl;

  factory ProjectVideo.fromJson(Map<String, dynamic> json) => ProjectVideo(
    id: jsonInt(json['id']),
    title: jsonString(json['title']),
    path: jsonString(json['video_path']),
    url: jsonString(json['video_url']),
    externalUrl: jsonString(json['external_url']),
  );

  ProjectVideo copyWith({String? title}) => ProjectVideo(
    id: id,
    title: title ?? this.title,
    path: path,
    url: url,
    externalUrl: externalUrl,
  );
}

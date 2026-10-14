import 'package:ufuq_imperium/core/utils/json_utils.dart';
import 'package:ufuq_imperium/features/projects/data/project_category.dart';
import 'package:ufuq_imperium/features/projects/data/project_media.dart';
import 'package:ufuq_imperium/features/services/data/service.dart';

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.description,
    this.location,
    this.area,
    this.year,
    this.status = 'completed',
    this.coverImage,
    this.featured = false,
    this.category,
    this.images = const [],
    this.videos = const [],
    this.services = const [],
  });

  final int id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? location;
  final int? area;
  final int? year;
  final String status;
  final String? coverImage;
  final bool featured;
  final ProjectCategory? category;
  final List<ProjectImage> images;
  final List<ProjectVideo> videos;
  final List<Service> services;

  factory Project.fromJson(Map<String, dynamic> json) {
    final category = jsonMap(json['category']);
    return Project(
      id: jsonInt(json['id']),
      title: '${json['title'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      shortDescription: jsonString(json['short_description']),
      description: jsonString(json['description']),
      location: jsonString(json['location']),
      area: jsonIntOrNull(json['area']),
      year: jsonIntOrNull(json['year']),
      status: '${json['status'] ?? 'completed'}',
      coverImage: jsonString(json['cover_image']),
      featured: jsonBool(json['is_featured']),
      category: category == null ? null : ProjectCategory.fromJson(category),
      images: jsonMaps(json['images']).map(ProjectImage.fromJson).toList(),
      videos: jsonMaps(json['videos']).map(ProjectVideo.fromJson).toList(),
      services: jsonMaps(json['services'])
          .map(Service.fromJson)
          .where((s) => s.active)
          .toList(),
    );
  }

  Project copyWith({
    String? title,
    String? shortDescription,
    String? description,
    String? location,
    ProjectCategory? category,
    List<ProjectImage>? images,
    List<ProjectVideo>? videos,
    List<Service>? services,
  }) => Project(
    id: id,
    title: title ?? this.title,
    slug: slug,
    shortDescription: shortDescription ?? this.shortDescription,
    description: description ?? this.description,
    location: location ?? this.location,
    area: area,
    year: year,
    status: status,
    coverImage: coverImage,
    featured: featured,
    category: category ?? this.category,
    images: images ?? this.images,
    videos: videos ?? this.videos,
    services: services ?? this.services,
  );
}

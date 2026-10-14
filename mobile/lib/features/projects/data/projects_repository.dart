import 'package:ufuq_imperium/core/network/api_client.dart';
import 'package:ufuq_imperium/core/network/api_exception.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/data/project_category.dart';
import 'package:ufuq_imperium/features/projects/data/review.dart';

class ProjectsRepository {
  ProjectsRepository(this._api);
  final ApiClient _api;

  Future<List<Project>> fetchAll() async =>
      (await _api.list('/projects')).map(Project.fromJson).toList();

  Future<List<ProjectCategory>> fetchCategories() async =>
      (await _api.list('/categories'))
          .map(ProjectCategory.fromJson)
          .where((c) => c.active)
          .toList();

  /// A single project with its full gallery; `null` when it does not exist (or is not published).
  Future<Project?> bySlug(String slug) async {
    if (slug.isEmpty) return null;
    try {
      final data = await _api.getData('/projects/${Uri.encodeComponent(slug)}');
      return data is Map
          ? Project.fromJson(Map<String, dynamic>.from(data))
          : null;
    } on ApiException catch (error) {
      if (error.isNotFound) return null;
      rethrow;
    }
  }

  Future<List<Review>> reviews(int projectId) async {
    try {
      final items = await _api.list('/projects/$projectId/testimonials');
      return items.map(Review.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> sendReview(
    int projectId, {
    required String name,
    required String email,
    required String content,
    required int rating,
  }) => _api.post('/projects/$projectId/testimonials', {
    'client_name': name,
    'client_email': email,
    'content': content,
    'rating': rating,
  });
}

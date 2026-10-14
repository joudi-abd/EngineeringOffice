import 'package:ufuq_imperium/core/state/localized_controller.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/data/project_category.dart';
import 'package:ufuq_imperium/features/projects/data/projects_repository.dart';
import 'package:ufuq_imperium/features/projects/data/review.dart';
import 'package:ufuq_imperium/features/projects/state/project_localizer.dart';

/// Projects and their categories, shown in the current language.
class ProjectsController extends LocalizedController {
  ProjectsController(this.repository, super.locale);
  final ProjectsRepository repository;

  List<Project> _projects = const [];
  List<ProjectCategory> _categories = const [];

  /// True when at least one of the two requests succeeded.
  Future<bool> load() async {
    var failures = 0;
    Future<T> safe<T>(Future<T> request, T fallback) async {
      try {
        return await request;
      } catch (_) {
        failures += 1;
        return fallback;
      }
    }

    final results = await Future.wait([
      safe<Object>(repository.fetchAll(), _projects),
      safe<Object>(repository.fetchCategories(), _categories),
    ]);
    _projects = results[0] as List<Project>;
    _categories = results[1] as List<ProjectCategory>;
    refresh();
    return failures < 2;
  }

  List<Project> get projects => cached(
    'projects',
    () => [for (final item in _projects) item.localized(translator)],
  );

  List<Project> get featured =>
      cached('featured', () => projects.where((p) => p.featured).toList());

  List<ProjectCategory> get categories => cached(
    'categories',
    () => [for (final item in _categories) item.localized(translator)],
  );

  Project localize(Project project) => project.localized(translator);
  Review localizeReview(Review review) => review.localized(translator);
}

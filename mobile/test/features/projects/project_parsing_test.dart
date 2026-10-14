import 'package:flutter_test/flutter_test.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';

void main() {
  test('Project.fromJson tolerates strings, nulls and missing keys', () {
    final project = Project.fromJson({
      'id': '7',
      'title': 'Villa',
      'slug': 'villa',
      'area': '620',
      'year': 2025,
      'is_featured': 1,
      'cover_image': null,
      'category': {'id': 1, 'name': 'Residential', 'slug': 'residential'},
      'images': [
        {'id': 1, 'image_url': 'a.jpg'},
        'garbage',
      ],
      'videos': null,
    });
    expect(project.id, 7);
    expect(project.area, 620);
    expect(project.featured, isTrue);
    expect(project.status, 'completed');
    expect(project.category?.slug, 'residential');
    expect(project.images, hasLength(1));
    expect(project.videos, isEmpty);
  });
}

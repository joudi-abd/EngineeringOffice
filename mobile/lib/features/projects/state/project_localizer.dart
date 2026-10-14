import 'package:ufuq_imperium/core/localization/translator.dart';
import 'package:ufuq_imperium/features/projects/data/project.dart';
import 'package:ufuq_imperium/features/projects/data/project_category.dart';
import 'package:ufuq_imperium/features/projects/data/review.dart';
import 'package:ufuq_imperium/features/services/state/service_localizer.dart';

extension ProjectCategoryLocalizer on ProjectCategory {
  ProjectCategory localized(Translator translator) => copyWith(
    name: translator.text(name),
    description: translator.maybe(description),
  );
}

extension ProjectLocalizer on Project {
  Project localized(Translator translator) => copyWith(
    title: translator.text(title),
    shortDescription: translator.maybe(shortDescription),
    description: translator.maybe(description),
    location: translator.maybe(location),
    category: category?.localized(translator),
    services: [for (final s in services) s.localized(translator)],
    images: [for (final i in images) i.copyWith(alt: translator.maybe(i.alt))],
    videos: [
      for (final v in videos) v.copyWith(title: translator.maybe(v.title)),
    ],
  );
}

extension ReviewLocalizer on Review {
  Review localized(Translator translator) => copyWith(
    clientName: translator.name(clientName),
    content: translator.text(content),
  );
}

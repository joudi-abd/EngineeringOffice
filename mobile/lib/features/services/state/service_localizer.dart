import 'package:ufuq_imperium/core/localization/translator.dart';
import 'package:ufuq_imperium/features/services/data/service.dart';

extension ServiceLocalizer on Service {
  Service localized(Translator translator) => copyWith(
    name: translator.text(name),
    shortDescription: translator.maybe(shortDescription),
    description: translator.maybe(description),
  );
}

import 'package:get/get.dart';

import 'languages/en_us.dart';
import 'languages/es_es.dart';


class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys {
    return {'en_US': _capitalize(enUS), 'es_ES': _capitalize(esES)};
  }

  Map<String, String> _capitalize(Map<String, String> map) {
    return map.map((key, value) => MapEntry(key, value.toUpperCase()));
  }
}

import 'package:ufuq_imperium/core/utils/json_utils.dart';

class Setting {
  const Setting({required this.key, required this.value});
  final String key;
  final String? value;

  factory Setting.fromJson(Map<String, dynamic> json) =>
      Setting(key: '${json['key']}', value: jsonString(json['value']));
}

/// Defensive JSON readers: the backend returns numbers as strings in places and `null` in others.
bool jsonBool(Object? value) => value == true || value == 1 || value == '1';

String? jsonString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text;
}

int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? jsonIntOrNull(Object? value) {
  if (value == null || value == '') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? double.tryParse('$value')?.toInt();
}

Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> jsonMaps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : const [];

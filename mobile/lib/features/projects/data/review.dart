import 'package:ufuq_imperium/core/utils/json_utils.dart';

class Review {
  const Review({
    required this.id,
    required this.clientName,
    required this.content,
    required this.rating,
  });
  final int id;
  final String clientName;
  final String content;
  final int rating;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: jsonInt(json['id']),
    clientName: '${json['client_name'] ?? ''}',
    content: '${json['content'] ?? ''}',
    rating: jsonInt(json['rating']).clamp(0, 5),
  );

  Review copyWith({String? clientName, String? content}) => Review(
    id: id,
    clientName: clientName ?? this.clientName,
    content: content ?? this.content,
    rating: rating,
  );
}

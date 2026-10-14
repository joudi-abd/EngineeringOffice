import 'package:ufuq_imperium/core/network/api_client.dart';

class ContactRepository {
  ContactRepository(this._api);
  final ApiClient _api;

  Future<void> sendMessage({
    required String name,
    required String email,
    String? phone,
    required String subject,
    required String message,
  }) => _api.post('/contact-messages', {
    'name': name,
    'email': email,
    'phone': phone,
    'subject': subject,
    'message': message,
  });
}

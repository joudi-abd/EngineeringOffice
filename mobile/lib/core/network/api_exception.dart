class ApiException implements Exception {
  ApiException(this.status, [this.message]);
  final int status;
  final String? message;

  bool get isConflict => status == 409;
  bool get isNotFound => status == 404;

  @override
  String toString() =>
      'ApiException($status${message == null ? '' : ': $message'})';
}

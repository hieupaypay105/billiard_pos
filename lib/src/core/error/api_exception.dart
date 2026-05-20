class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors});
  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => message;
}

import 'package:dio/dio.dart';
void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://dev.anholding.com/api', headers: {'Authorization': 'Bearer ...'}));
  // Need valid token... wait, we cannot test seamlessly without token.
}

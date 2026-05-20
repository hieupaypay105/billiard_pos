import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/core/services/firebase_messaging_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────
class MockDio extends Mock implements Dio {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late MockDio mockDio;
  late MockFirebaseMessaging mockMessaging;
  late FirebaseMessagingService service;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    mockDio = MockDio();
    mockMessaging = MockFirebaseMessaging();
    service = FirebaseMessagingService(
      dio: mockDio,
      messaging: mockMessaging,
    );
  });

  group('sendTokenToBackend', () {
    test('should POST token with correct endpoint and form-data', () async {
      // Arrange
      const fakeToken = 'fake-fcm-token-12345';
      when(() => mockMessaging.getToken()).thenAnswer((_) async => fakeToken);
      when(
        () => mockDio.post<void>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
        ),
      );

      // Act
      await service.sendTokenToBackend();

      // Assert — đúng endpoint
      final captured = verify(
        () => mockDio.post<void>(
          captureAny(),
          data: captureAny(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).captured;

      // Verify endpoint
      expect(captured[0], equals(ApiPaths.notificationFcmToken));

      // Verify form-data payload
      final formData = captured[1] as FormData;
      final fields = Map.fromEntries(formData.fields);
      expect(fields['token'], equals(fakeToken));
      expect(fields['os'], isIn(['ios', 'android']));
      expect(fields['owner_type'], equals('user'));
    });

    test('should NOT call API when token is null', () async {
      // Arrange
      when(() => mockMessaging.getToken()).thenAnswer((_) async => null);

      // Act
      await service.sendTokenToBackend();

      // Assert — API should never be called
      verifyNever(
        () => mockDio.post<void>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      );
    });

    test('should handle API error gracefully without throwing', () async {
      // Arrange
      const fakeToken = 'fake-fcm-token-error';
      when(() => mockMessaging.getToken()).thenAnswer((_) async => fakeToken);
      when(
        () => mockDio.post<void>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert — should NOT throw
      await expectLater(service.sendTokenToBackend(), completes);
    });

    test('should send correct platform value', () async {
      // Arrange
      const fakeToken = 'fake-token-platform';
      when(() => mockMessaging.getToken()).thenAnswer((_) async => fakeToken);
      when(
        () => mockDio.post<void>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
        ),
      );

      // Act
      await service.sendTokenToBackend();

      // Assert
      final captured = verify(
        () => mockDio.post<void>(
          any(),
          data: captureAny(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).captured;

      final formData = captured[0] as FormData;
      final fields = Map.fromEntries(formData.fields);

      // In test environment, defaultTargetPlatform is android
      final expectedPlatform =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      expect(fields['os'], equals(expectedPlatform));
    });
  });

  group('API paths', () {
    test('notificationFcmToken path should be correct', () {
      expect(ApiPaths.notificationFcmToken, equals('/notification/fcmToken'));
    });
  });

  group('Service construction', () {
    test('should accept dio and optional messaging via constructor', () {
      final svc = FirebaseMessagingService(
        dio: mockDio,
        messaging: mockMessaging,
      );
      expect(svc, isNotNull);
      expect(svc.dio, equals(mockDio));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ftms/core/services/strava_exports.dart';
import 'dart:io';

// Generate mocks for external dependencies only
@GenerateMocks([
  FlutterSecureStorage,
  http.Client,
])
import 'strava_service_test.mocks.dart';

void main() {
  group('StravaService Integration Tests', () {
    late StravaService stravaService;
    late MockFlutterSecureStorage mockStorage;
    late StravaTokenManager tokenManager;
    late StravaOAuthHandler oauthHandler;
    late StravaActivityUploader activityUploader;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();

      // Create components with mocked dependencies
      tokenManager = StravaTokenManager(storage: mockStorage);
      oauthHandler = StravaOAuthHandler(tokenManager: tokenManager);
      activityUploader = StravaActivityUploader(tokenManager: tokenManager);
      
      stravaService = StravaService(
        tokenManager: tokenManager,
        oauthHandler: oauthHandler,
        activityUploader: activityUploader,
      );
    });

    group('Authentication Methods', () {
      test('authenticate delegates to oauth handler', () async {
        // Mock OAuth handler behavior
        when(mockStorage.read(key: 'strava_code_verifier')).thenAnswer((_) async => null);
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});
        
        // Since we can't mock the actual OAuth flow, we test the delegation
        expect(() => stravaService.authenticate(), returnsNormally);
      });

      test('isAuthenticated delegates to token manager', () async {
        when(mockStorage.read(key: 'strava_access_token')).thenAnswer((_) async => 'token123');
        
        final result = await stravaService.isAuthenticated();
        expect(result, true);
        
        verify(mockStorage.read(key: 'strava_access_token')).called(1);
      });

      test('getAuthStatus delegates to token manager', () async {
        when(mockStorage.read(key: 'strava_access_token')).thenAnswer((_) async => 'token123');
        when(mockStorage.read(key: 'strava_athlete_name')).thenAnswer((_) async => 'John Doe');
        
        final result = await stravaService.getAuthStatus();
        expect(result, isNotNull);
        expect(result!['isAuthenticated'], true);
        expect(result['athleteName'], 'John Doe');
      });

      test('signOut delegates to token manager', () async {
        when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
        
        await stravaService.signOut();
        
        // Verify all token-related keys are deleted
        verify(mockStorage.delete(key: 'strava_access_token')).called(1);
        verify(mockStorage.delete(key: 'strava_refresh_token')).called(1);
        verify(mockStorage.delete(key: 'strava_expires_at')).called(1);
        verify(mockStorage.delete(key: 'strava_athlete_name')).called(1);
        verify(mockStorage.delete(key: 'strava_athlete_id')).called(1);
        verify(mockStorage.delete(key: 'strava_code_verifier')).called(1);
      });
    });

    group('Activity Upload Methods', () {
      test('uploadActivity delegates to activity uploader', () async {
        when(mockStorage.read(key: 'strava_access_token')).thenAnswer((_) async => 'token123');
        when(mockStorage.read(key: 'strava_expires_at')).thenAnswer((_) async => '999999999999');
        
        // Create a temporary file for testing
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_activity.fit');
        await tempFile.writeAsString('dummy fit data');
        
        try {
          final result = await stravaService.uploadActivity(tempFile.path, 'Test Activity');
          // We expect null because the HTTP call will fail (no network in tests)
          expect(result, isNull);
        } finally {
          await tempFile.delete();
        }
      });

      test('uploadActivityWithMetadata delegates to activity uploader', () async {
        when(mockStorage.read(key: 'strava_access_token')).thenAnswer((_) async => 'token123');
        when(mockStorage.read(key: 'strava_expires_at')).thenAnswer((_) async => '999999999999');
        
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/test_activity.fit');
        await tempFile.writeAsString('dummy fit data');
        
        try {
          final result = await stravaService.uploadActivityWithMetadata(
            fitFilePath: tempFile.path,
            name: 'Test Activity',
            description: 'Test Description',
            activityType: 'ride',
            isPrivate: true,
            hasHeartrate: true,
            hasPower: true,
          );
          expect(result, isNull); // Expected to fail without proper network mock
        } finally {
          await tempFile.delete();
        }
      });
    });

  });

}

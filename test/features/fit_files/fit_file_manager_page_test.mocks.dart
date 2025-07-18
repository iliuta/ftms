// Mocks generated by Mockito 5.4.6 from annotations
// in ftms/test/features/fit_files/fit_file_manager_page_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;

import 'package:ftms/core/services/fit/fit_file_manager.dart' as _i5;
import 'package:ftms/core/services/strava/strava_activity_uploader.dart' as _i4;
import 'package:ftms/core/services/strava/strava_oauth_handler.dart' as _i3;
import 'package:ftms/core/services/strava/strava_service.dart' as _i7;
import 'package:ftms/core/services/strava/strava_token_manager.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeStravaTokenManager_0 extends _i1.SmartFake
    implements _i2.StravaTokenManager {
  _FakeStravaTokenManager_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStravaOAuthHandler_1 extends _i1.SmartFake
    implements _i3.StravaOAuthHandler {
  _FakeStravaOAuthHandler_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStravaActivityUploader_2 extends _i1.SmartFake
    implements _i4.StravaActivityUploader {
  _FakeStravaActivityUploader_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [FitFileManager].
///
/// See the documentation for Mockito's code generation for more information.
class MockFitFileManager extends _i1.Mock implements _i5.FitFileManager {
  MockFitFileManager() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<List<_i5.FitFileInfo>> getAllFitFiles() => (super.noSuchMethod(
        Invocation.method(
          #getAllFitFiles,
          [],
        ),
        returnValue:
            _i6.Future<List<_i5.FitFileInfo>>.value(<_i5.FitFileInfo>[]),
      ) as _i6.Future<List<_i5.FitFileInfo>>);

  @override
  _i6.Future<bool> deleteFitFile(String? filePath) => (super.noSuchMethod(
        Invocation.method(
          #deleteFitFile,
          [filePath],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<List<String>> deleteFitFiles(List<String>? filePaths) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteFitFiles,
          [filePaths],
        ),
        returnValue: _i6.Future<List<String>>.value(<String>[]),
      ) as _i6.Future<List<String>>);

  @override
  _i6.Future<int> getFitFileCount() => (super.noSuchMethod(
        Invocation.method(
          #getFitFileCount,
          [],
        ),
        returnValue: _i6.Future<int>.value(0),
      ) as _i6.Future<int>);

  @override
  _i6.Future<int> getTotalFitFileSize() => (super.noSuchMethod(
        Invocation.method(
          #getTotalFitFileSize,
          [],
        ),
        returnValue: _i6.Future<int>.value(0),
      ) as _i6.Future<int>);
}

/// A class which mocks [StravaService].
///
/// See the documentation for Mockito's code generation for more information.
class MockStravaService extends _i1.Mock implements _i7.StravaService {
  MockStravaService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.StravaTokenManager get tokenManager => (super.noSuchMethod(
        Invocation.getter(#tokenManager),
        returnValue: _FakeStravaTokenManager_0(
          this,
          Invocation.getter(#tokenManager),
        ),
      ) as _i2.StravaTokenManager);

  @override
  _i3.StravaOAuthHandler get oauthHandler => (super.noSuchMethod(
        Invocation.getter(#oauthHandler),
        returnValue: _FakeStravaOAuthHandler_1(
          this,
          Invocation.getter(#oauthHandler),
        ),
      ) as _i3.StravaOAuthHandler);

  @override
  _i4.StravaActivityUploader get activityUploader => (super.noSuchMethod(
        Invocation.getter(#activityUploader),
        returnValue: _FakeStravaActivityUploader_2(
          this,
          Invocation.getter(#activityUploader),
        ),
      ) as _i4.StravaActivityUploader);

  @override
  _i6.Future<bool> authenticate() => (super.noSuchMethod(
        Invocation.method(
          #authenticate,
          [],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<bool> isAuthenticated() => (super.noSuchMethod(
        Invocation.method(
          #isAuthenticated,
          [],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<Map<String, dynamic>?> getAuthStatus() => (super.noSuchMethod(
        Invocation.method(
          #getAuthStatus,
          [],
        ),
        returnValue: _i6.Future<Map<String, dynamic>?>.value(),
      ) as _i6.Future<Map<String, dynamic>?>);

  @override
  _i6.Future<void> signOut() => (super.noSuchMethod(
        Invocation.method(
          #signOut,
          [],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  _i6.Future<Map<String, dynamic>?> uploadActivity(
    String? fitFilePath,
    String? activityName, {
    String? activityType = 'workout',
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #uploadActivity,
          [
            fitFilePath,
            activityName,
          ],
          {#activityType: activityType},
        ),
        returnValue: _i6.Future<Map<String, dynamic>?>.value(),
      ) as _i6.Future<Map<String, dynamic>?>);

  @override
  _i6.Future<Map<String, dynamic>?> uploadActivityWithMetadata({
    required String? fitFilePath,
    required String? name,
    String? description,
    String? activityType = 'workout',
    bool? isPrivate = false,
    bool? hasHeartrate = false,
    bool? hasPower = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #uploadActivityWithMetadata,
          [],
          {
            #fitFilePath: fitFilePath,
            #name: name,
            #description: description,
            #activityType: activityType,
            #isPrivate: isPrivate,
            #hasHeartrate: hasHeartrate,
            #hasPower: hasPower,
          },
        ),
        returnValue: _i6.Future<Map<String, dynamic>?>.value(),
      ) as _i6.Future<Map<String, dynamic>?>);
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../utils/logger.dart';
import 'strava_config.dart';

/// Manages Strava authentication tokens and their lifecycle
class StravaTokenManager {
  final FlutterSecureStorage _storage;
  
  StravaTokenManager({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();
  
  // Storage keys
  static const String _accessTokenKey = 'strava_access_token';
  static const String _refreshTokenKey = 'strava_refresh_token';
  static const String _expiresAtKey = 'strava_expires_at';
  static const String _athleteNameKey = 'strava_athlete_name';
  static const String _athleteIdKey = 'strava_athlete_id';
  static const String _codeVerifierKey = 'strava_code_verifier';
  
  /// Checks if user has a valid access token
  Future<bool> isAuthenticated() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null;
  }
  
  /// Gets current authentication status with user info
  Future<Map<String, dynamic>?> getAuthStatus() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final athleteName = await _storage.read(key: _athleteNameKey);
    
    if (accessToken != null) {
      return {
        'isAuthenticated': true,
        'athleteName': athleteName ?? 'Unknown',
      };
    }
    return null;
  }
  
  /// Stores authentication tokens securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresAt,
    Map<String, dynamic>? athleteInfo,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _expiresAtKey, value: expiresAt.toString());
    
    if (athleteInfo != null) {
      final fullName = '${athleteInfo['firstname']} ${athleteInfo['lastname']}';
      await _storage.write(key: _athleteNameKey, value: fullName);
      await _storage.write(key: _athleteIdKey, value: athleteInfo['id'].toString());
    }
  }
  
  /// Gets the current access token, refreshing if necessary
  Future<String?> getValidAccessToken() async {
    final tokenRefreshed = await _refreshTokenIfNeeded();
    if (!tokenRefreshed) return null;
    
    return await _storage.read(key: _accessTokenKey);
  }
  
  /// Stores code verifier temporarily during OAuth flow
  Future<void> storeCodeVerifier(String verifier) async {
    await _storage.write(key: _codeVerifierKey, value: verifier);
  }
  
  /// Retrieves and removes code verifier
  Future<String?> getAndRemoveCodeVerifier() async {
    final verifier = await _storage.read(key: _codeVerifierKey);
    if (verifier != null) {
      await _storage.delete(key: _codeVerifierKey);
    }
    return verifier;
  }
  
  /// Refreshes access token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      final expiresAtStr = await _storage.read(key: _expiresAtKey);
      if (expiresAtStr == null) return false;
      
      final expiresAt = int.parse(expiresAtStr);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // If token is valid for at least the buffer time, no need to refresh
      if (expiresAt > (now + StravaConfig.tokenRefreshBufferSeconds)) return true;
      
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;
      
      logger.i('🔄 Refreshing Strava access token...');
      
      final response = await http.post(
        Uri.parse(StravaConfig.tokenRefreshUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': StravaConfig.clientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );
      
      if (response.statusCode != 200) {
        logger.e('❌ Failed to refresh token: ${response.statusCode}');
        return false;
      }
      
      final tokenData = jsonDecode(response.body);
      
      await _storage.write(key: _accessTokenKey, value: tokenData['access_token']);
      await _storage.write(key: _refreshTokenKey, value: tokenData['refresh_token']);
      await _storage.write(key: _expiresAtKey, value: tokenData['expires_at'].toString());
      
      logger.i('✅ Token refreshed successfully');
      return true;
    } catch (e) {
      logger.e('❌ Error refreshing token: $e');
      return false;
    }
  }
  
  /// Clears all stored authentication data
  Future<void> clearTokens() async {
    logger.i('🚪 Clearing Strava tokens');
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _athleteNameKey);
    await _storage.delete(key: _athleteIdKey);
    await _storage.delete(key: _codeVerifierKey);
  }
}
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../utils/logger.dart';

class StravaService {
  // Configuration
  static const String _clientId = '3929'; // Replace with your Client ID
  // unfortunately, Strava requires client_secret for token exchange even with PKCE
  // TODO: Consider using a backend to handle this securely
  static const String _clientSecret = 'strava_client_secret'; // Remplace par ton vrai client_secret
  static const String _redirectUri = 'ftmsapp://strava/callback';
  static const String _authUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _uploadUrl = 'https://www.strava.com/api/v3/uploads';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Generate PKCE code verifier and challenge
  String _generateCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // Check if user is authenticated with Strava
  Future<bool> isAuthenticated() async {
    final accessToken = await _storage.read(key: 'strava_access_token');
    return accessToken != null;
  }

  // Get current authentication status with user info
  Future<Map<String, dynamic>?> getAuthStatus() async {
    final accessToken = await _storage.read(key: 'strava_access_token');
    final athleteName = await _storage.read(key: 'strava_athlete_name');

    if (accessToken != null) {
      return {
        'isAuthenticated': true,
        'athleteName': athleteName ?? 'Unknown',
      };
    }
    return null;
  }

  // Authenticate with Strava using OAuth2 with PKCE
  Future<bool> authenticate() async {
    logger.i('🔎 [DEBUG] authenticate() called');

    try {
      // Generate PKCE parameters
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Store code verifier for later use
      await _storage.write(key: 'strava_code_verifier', value: codeVerifier);

      // Construct the authorization URL with PKCE parameters
      final authUrl = Uri.parse('$_authUrl'
          '?client_id=$_clientId'
          '&response_type=code'
          '&redirect_uri=$_redirectUri'
          '&approval_prompt=force'
          '&scope=activity:write,read'
          '&code_challenge=$codeChallenge'
          '&code_challenge_method=S256');

      logger.i('Starting Strava OAuth PKCE flow: $authUrl');

      // Lancer le navigateur externe pour l'authentification
      if (!await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      )) {
        logger.e("❌ Impossible d'ouvrir le navigateur");
        return false;
      }

      logger.i('🌐 Browser opened with authorization URL');
      logger.i('⏳ Waiting for deep link callback...');
      logger.i('💡 IMPORTANT: After authorizing, you will be redirected to the app.');

      // Initialiser AppLinks pour écouter les deep links
      final appLinks = AppLinks();

      // Attendre la réception du deep link (max 3 minutes)
      final completer = Completer<Uri?>();

      // Écouteur pour les deep links
      final subscription = appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null && uri.toString().startsWith(_redirectUri)) {
          logger.i('✅ Received callback URI: $uri');
          completer.complete(uri);
        }
      }, onError: (error) {
        logger.e('❌ Deep link error: $error');
        completer.completeError(error);
      });

      // Attendre la réception du deep link ou le timeout
      Uri? receivedUri;
      try {
        receivedUri = await completer.future.timeout(
          Duration(minutes: 3),
          onTimeout: () {
            logger.e('⏱️ Authentication timeout after 3 minutes');
            throw TimeoutException('Authentication timeout');
          },
        );
      } finally {
        subscription.cancel();
      }

      if (receivedUri == null) {
        logger.e('❌ No valid URI received');
        return false;
      }

      // Extraire le code d'autorisation du deep link
      final code = receivedUri.queryParameters['code'];
      if (code == null) {
        logger.e('❌ No authorization code in redirect URI');
        logger.e('🔍 URI params: ${receivedUri.queryParameters}');
        return false;
      }

      logger.i('✅ Authorization code received: ${code.substring(0, 5)}...');

      // Récupérer le code verifier pour l'échange
      final storedCodeVerifier = await _storage.read(key: 'strava_code_verifier');
      if (storedCodeVerifier == null) {
        logger.e('❌ Code verifier not found in storage');
        return false;
      }

      // Échanger le code contre un token
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret, // Nécessaire pour Strava même avec PKCE
          'code': code,
          'grant_type': 'authorization_code',
          'code_verifier': storedCodeVerifier,
        },
      );

      // Nettoyer le code verifier
      await _storage.delete(key: 'strava_code_verifier');

      if (tokenResponse.statusCode != 200) {
        logger.e('❌ Failed to exchange code for token: ${tokenResponse.statusCode}');
        logger.e('Response: ${tokenResponse.body}');
        return false;
      }

      // Analyser la réponse de token
      final tokenData = jsonDecode(tokenResponse.body);

      // Stocker les tokens de manière sécurisée
      await _storage.write(key: 'strava_access_token', value: tokenData['access_token']);
      await _storage.write(key: 'strava_refresh_token', value: tokenData['refresh_token']);
      await _storage.write(key: 'strava_expires_at', value: tokenData['expires_at'].toString());

      // Stocker les informations de l'athlète si disponibles
      if (tokenData['athlete'] != null) {
        final athlete = tokenData['athlete'];
        final fullName = '${athlete['firstname']} ${athlete['lastname']}';
        await _storage.write(key: 'strava_athlete_name', value: fullName);
        await _storage.write(key: 'strava_athlete_id', value: athlete['id'].toString());

        logger.i('✅ Authentication successful for athlete: $fullName');
      } else {
        logger.i('✅ Authentication successful (no athlete info)');
      }

      return true;
    } catch (e) {
      logger.e('❌ Error during authentication: $e');
      await _storage.delete(key: 'strava_code_verifier');
      return false;
    }
  }

  // Rafraîchir le token si nécessaire
  Future<bool> _refreshTokenIfNeeded() async {
    try {
      final expiresAtStr = await _storage.read(key: 'strava_expires_at');
      if (expiresAtStr == null) return false;

      final expiresAt = int.parse(expiresAtStr);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Si le token est encore valide pour au moins 5 minutes, pas besoin de le rafraîchir
      if (expiresAt > (now + 300)) return true;

      final refreshToken = await _storage.read(key: 'strava_refresh_token');
      if (refreshToken == null) return false;

      logger.i('🔄 Refreshing Strava access token...');

      // Échanger le refresh token pour un nouveau token d'accès
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (tokenResponse.statusCode != 200) {
        logger.e('❌ Failed to refresh token: ${tokenResponse.statusCode}');
        return false;
      }

      final tokenData = jsonDecode(tokenResponse.body);

      // Mise à jour des tokens stockés
      await _storage.write(key: 'strava_access_token', value: tokenData['access_token']);
      await _storage.write(key: 'strava_refresh_token', value: tokenData['refresh_token']);
      await _storage.write(key: 'strava_expires_at', value: tokenData['expires_at'].toString());

      logger.i('✅ Token refreshed successfully');
      return true;
    } catch (e) {
      logger.e('❌ Error refreshing token: $e');
      return false;
    }
  }

  // Télécharger un fichier FIT sur Strava
  Future<Map<String, dynamic>?> uploadActivity(String fitFilePath, String activityName) async {
    try {
      // S'assurer que nous avons un token d'accès valide
      final tokenValid = await _refreshTokenIfNeeded();
      if (!tokenValid) {
        logger.e('❌ No valid Strava access token available');
        return null;
      }

      final accessToken = await _storage.read(key: 'strava_access_token');

      logger.i('📤 Uploading activity to Strava: $activityName');

      // Créer une requête multipart pour télécharger le fichier
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Ajouter l'en-tête d'autorisation
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Ajouter le fichier à la requête
      final file = await http.MultipartFile.fromPath('file', fitFilePath);
      request.files.add(file);

      // Ajouter d'autres champs requis
      request.fields['name'] = activityName;
      request.fields['data_type'] = 'fit';
      request.fields['activity_type'] = 'workout';

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        logger.i('✅ Activity uploaded successfully: ${responseData['id']}');
        return responseData;
      } else {
        logger.e('❌ Failed to upload activity: ${response.statusCode}');
        logger.e('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Error uploading activity: $e');
      return null;
    }
  }

  // Se déconnecter et effacer les tokens stockés
  Future<void> signOut() async {
    logger.i('🚪 Signing out from Strava');
    await _storage.delete(key: 'strava_access_token');
    await _storage.delete(key: 'strava_refresh_token');
    await _storage.delete(key: 'strava_expires_at');
    await _storage.delete(key: 'strava_athlete_name');
    await _storage.delete(key: 'strava_athlete_id');
  }

}

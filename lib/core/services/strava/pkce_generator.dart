import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Generates PKCE (Proof Key for Code Exchange) parameters for OAuth2 security
class PkceGenerator {
  static const String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  
  /// Generates a cryptographically secure code verifier
  String generateCodeVerifier() {
    final random = Random.secure();
    return List.generate(128, (_) => _charset[random.nextInt(_charset.length)]).join();
  }
  
  /// Generates a code challenge from a verifier using SHA256
  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
  
  /// Generates both verifier and challenge as a pair
  PkceParams generatePkceParams() {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);
    return PkceParams(verifier: verifier, challenge: challenge);
  }
}

/// Data class to hold PKCE parameters
class PkceParams {
  final String verifier;
  final String challenge;
  
  const PkceParams({
    required this.verifier,
    required this.challenge,
  });
}
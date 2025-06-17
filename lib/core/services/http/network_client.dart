import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../utils/logger.dart';

/// Custom HTTP client configuration for better Android compatibility
class NetworkClient {
  static http.Client? _client;
  
  /// Gets a configured HTTP client with proper settings for Android release mode
  static http.Client get client {
    if (_client == null) {
      _setupHttpClient();
    }
    return _client!;
  }
  
  /// Sets up HTTP client with Android-friendly configuration
  static void _setupHttpClient() {
    try {
      // Configure HttpClient for better Android compatibility
      final httpClient = HttpClient();
      
      // Set timeouts
      httpClient.connectionTimeout = const Duration(seconds: 15);
      httpClient.idleTimeout = const Duration(seconds: 30);
      
      // Enable HTTP/2 and compression
      httpClient.autoUncompress = true;
      
      // Configure user agent
      httpClient.userAgent = 'FTMS-App-Android/1.0';
      
      _client = IOClient(httpClient);
      logger.i('✅ HTTP client configured successfully');      
    } catch (e) {
      logger.e('❌ Failed to configure HTTP client: $e');
      // Fallback to default client
      _client = http.Client();
    }
  }
  
  /// Disposes the HTTP client
  static void dispose() {
    _client?.close();
    _client = null;
  }
}

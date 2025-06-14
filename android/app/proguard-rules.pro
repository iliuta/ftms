# Flutter Secure Storage ProGuard Rules
# These rules prevent obfuscation of classes needed by flutter_secure_storage

# Keep flutter_secure_storage classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep cipher classes
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }

# Keep keystore classes
-keep class java.security.KeyStore { *; }
-keep class java.security.KeyStore$** { *; }
-keep class android.security.keystore.** { *; }

# Keep android keystore classes
-keep class android.security.KeyPairGeneratorSpec { *; }
-keep class android.security.KeyPairGeneratorSpec$Builder { *; }

# Keep key generation classes
-dontwarn javax.crypto.**
-dontwarn java.security.**

# Android Keystore system
-keep class android.security.keystore.KeyGenParameterSpec { *; }
-keep class android.security.keystore.KeyGenParameterSpec$Builder { *; }
-keep class android.security.keystore.KeyProperties { *; }

# For SharedPreferences encryption
-keep class androidx.security.crypto.** { *; }

# HTTP Client and Network requests - CRITICAL for Strava authentication
-keep class dart.io.** { *; }
-keep class io.flutter.plugin.http.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# JSON serialization for token exchange
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }

# URL Launcher for OAuth flow
-keep class io.flutter.plugins.urllauncher.** { *; }

# App Links for OAuth callback
-keep class com.llfbandit.app_links.** { *; }

# Crypto operations for token handling
-keep class dart.convert.** { *; }
-keep class dart.typed_data.** { *; }

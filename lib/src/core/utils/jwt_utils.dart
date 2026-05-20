import 'dart:convert';

/// Utility to decode and inspect JWT tokens without signature verification.
sealed class JwtUtils {
  /// Decode the payload (second segment) of a JWT token.
  /// Returns null if the token is not a valid JWT format.
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Check if a JWT token is expired or about to expire.
  ///
  /// [bufferSeconds] — refresh early by this many seconds (default 30s).
  /// Returns `false` if the token can't be decoded or has no `exp` claim.
  static bool isExpired(String token, {int bufferSeconds = 30}) {
    final payload = decodePayload(token);
    if (payload == null) return false;

    final exp = payload['exp'];
    if (exp == null) return false;

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      (exp as num).toInt() * 1000,
    );
    final buffer = Duration(seconds: bufferSeconds);
    return DateTime.now().isAfter(expiryTime.subtract(buffer));
  }

  /// Get the expiry DateTime from a JWT token.
  /// Returns null if can't decode or no `exp` claim.
  static DateTime? getExpiryTime(String token) {
    final payload = decodePayload(token);
    if (payload == null) return null;

    final exp = payload['exp'];
    if (exp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(
      (exp as num).toInt() * 1000,
    );
  }
}

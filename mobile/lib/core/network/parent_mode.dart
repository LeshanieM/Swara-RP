/// The parent-mode token from POST /api/auth/parent-mode, kept in memory only.
/// The API client sends it as X-Parent-Token while it is valid.
class ParentMode {
  static String? _token;
  static DateTime? _expiresAt;

  static bool get isActive =>
      _token != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!);

  static String? get token => isActive ? _token : null;

  static void start(String token, int expiresInSec) {
    _token = token;
    // A small margin so a request never leaves with a token that expires in flight.
    _expiresAt = DateTime.now().add(Duration(seconds: expiresInSec - 30));
  }

  static void end() {
    _token = null;
    _expiresAt = null;
  }
}

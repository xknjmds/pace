import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Read-only access to the owner's calendar. Nothing else is asked for.
const calendarScopes = ['https://www.googleapis.com/auth/calendar.readonly'];

/// The OAuth web client id from the owner's Google Cloud project, passed at
/// build time: `--dart-define=PACE_GOOGLE_CLIENT_ID=...`. Never committed.
const googleClientId = String.fromEnvironment('PACE_GOOGLE_CLIENT_ID');

/// Getting an access token for [calendarScopes]. Behind an interface so
/// tests never reach Google.
abstract interface class CalendarAuth {
  /// False when the build has no client id; the screen explains the setup.
  bool get configured;

  /// A token without showing anything, or null when the owner has to
  /// approve again.
  Future<String?> silentToken();

  /// Asks the owner (from a button press). Throws when they decline.
  Future<String> interactiveToken();

  /// Drops a token Google rejected, so the next request asks again.
  Future<void> forgetToken(String token);

  Future<void> signOut();
}

class GoogleCalendarAuth implements CalendarAuth {
  GoogleCalendarAuth();

  Future<void>? _init;

  @override
  bool get configured => googleClientId.isNotEmpty;

  Future<void> _ready() => _init ??= GoogleSignIn.instance.initialize(
    // The web needs the client id itself; Android needs it as the
    // "server" (web) client id, alongside the app's SHA-1 registration.
    clientId: kIsWeb ? googleClientId : null,
    serverClientId: kIsWeb ? null : googleClientId,
  );

  GoogleSignInAuthorizationClient get _client =>
      GoogleSignIn.instance.authorizationClient;

  @override
  Future<String?> silentToken() async {
    if (!configured) return null;
    await _ready();
    return (await _client.authorizationForScopes(calendarScopes))?.accessToken;
  }

  @override
  Future<String> interactiveToken() async {
    await _ready();
    return (await _client.authorizeScopes(calendarScopes)).accessToken;
  }

  @override
  Future<void> forgetToken(String token) async {
    await _ready();
    await _client.clearAuthorizationToken(accessToken: token);
  }

  @override
  Future<void> signOut() async {
    if (!configured) return;
    await _ready();
    await GoogleSignIn.instance.disconnect();
  }
}

/// Desktop: no Google sign-in plugin exists there.
class NoCalendarAuth implements CalendarAuth {
  const NoCalendarAuth();

  @override
  bool get configured => false;
  @override
  Future<String?> silentToken() async => null;
  @override
  Future<String> interactiveToken() =>
      Future.error(UnsupportedError('Calendar sync is not available here'));
  @override
  Future<void> forgetToken(String token) async {}
  @override
  Future<void> signOut() async {}
}

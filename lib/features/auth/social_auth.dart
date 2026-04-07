import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Вход через Google и Apple.
///
/// В обоих случаях получаем credential и передаём его в FirebaseAuth.
/// После этого FirebaseAuth.instance.currentUser != null,
/// и можно вызвать user.getIdToken() для запросов к бэкенду.
class SocialAuth {
  static final _google = GoogleSignIn(scopes: ['email', 'profile']);
  static final _auth = FirebaseAuth.instance;

  /// Возвращает [User] или null если пользователь отменил вход.
  static Future<User?> signInWithGoogle() async {
    // 1. Google-диалог выбора аккаунта
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // отменил

    // 2. Получаем токены Google
    final googleAuth = await googleUser.authentication;

    // 3. Конвертируем в Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Входим в Firebase — теперь currentUser != null
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// Возвращает [User] или null если что-то пошло не так.
  static Future<User?> signInWithApple() async {
    // 1. Apple-диалог
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // 2. Конвертируем в Firebase OAuth credential
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    // 3. Входим в Firebase
    final result = await _auth.signInWithCredential(oauthCredential);
    return result.user;
  }

  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}

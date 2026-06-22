import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/firebase_config.dart';
import '../services/firebase_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  User? _currentUser;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  bool get isAuthenticated => _isAuthenticated;

  User? get currentUser => _currentUser;

  String? get errorMessage => _errorMessage;

  String? get userId => _currentUser?.uid;

  String? get userEmail => _currentUser?.email;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    FirebaseService.userStream.listen((User? user) {
      _currentUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await FirebaseService.signUpWithEmail(
        email,
        password,
      );

      if (userCredential?.user != null) {
        // Update user profile
        await FirebaseService.updateUserProfile(displayName: name);

        // Save user ID to secure storage
        await SecureStorageService.saveUserId(userCredential!.user!.uid);

        // Save user data to Firebase
        await FirebaseService.saveUserData(
          userId: userCredential.user!.uid,
          userData: {
            'uid': userCredential.user!.uid,
            'email': email,
            'name': name,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        Logger.info('User signed up successfully: ${userCredential.user?.uid}');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Sign up failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      Logger.error('Sign up error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      Logger.error('Sign up unexpected error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await FirebaseService.signInWithEmail(
        email,
        password,
      );

      if (userCredential?.user != null) {
        await SecureStorageService.saveUserId(userCredential!.user!.uid);
        Logger.info('User signed in successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Sign in failed';
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      Logger.error('Sign in error: ${e.code} - ${e.message}');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      Logger.error('Sign in unexpected error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseService.signOut();
      await SecureStorageService.clearAuthTokens();

      _currentUser = null;
      _isAuthenticated = false;
      Logger.info('User signed out successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign out failed';
      Logger.error('Sign out error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseService.resetPassword(email);
      Logger.info('Password reset email sent');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      Logger.error('Password reset error: ${e.code}');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Password reset failed';
      Logger.error('Password reset error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await FirebaseService.changePassword(newPassword);
      Logger.info('Password changed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getAuthErrorMessage(e.code);
      Logger.error('Change password error: ${e.code}');
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Password change failed';
      Logger.error('Change password error: $e');
      notifyListeners();
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'Email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Email address is invalid.';
      case 'operation-not-allowed':
        return 'Sign up is currently disabled.';
      case 'user-disabled':
        return 'User account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      case 'account-exists-with-different-credential':
        return 'Account exists with different credential.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

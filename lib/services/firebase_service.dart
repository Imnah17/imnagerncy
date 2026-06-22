import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Auth Methods
  static Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info('User signed up successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Logger.error('Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.info('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Logger.error('Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      Logger.info('User signed out successfully');
    } catch (e) {
      Logger.error('Sign out error: $e');
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Logger.info('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      Logger.error('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<void> updateUserProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
        Logger.info('User profile updated');
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Profile update error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        Logger.info('Password changed successfully');
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('Password change error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // User Stream
  static Stream<User?> get userStream => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static String? get currentUserId => _auth.currentUser?.uid;

  static bool get isUserLoggedIn => _auth.currentUser != null;

  // Realtime Database Methods
  static Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _database.ref('users/$userId').set(userData);
      Logger.info('User data saved to database');
    } catch (e) {
      Logger.error('Save user data error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      Logger.error('Get user data error: $e');
      rethrow;
    }
  }

  static Stream<DatabaseEvent> getUserDataStream(String userId) {
    return _database.ref('users/$userId').onValue;
  }

  static Future<void> saveGeofence({
    required String userId,
    required String geofenceId,
    required Map<String, dynamic> geofenceData,
  }) async {
    try {
      await _database
          .ref('users/$userId/geofences/$geofenceId')
          .set(geofenceData);
      Logger.info('Geofence saved to database');
    } catch (e) {
      Logger.error('Save geofence error: $e');
      rethrow;
    }
  }

  static Stream<DatabaseEvent> getGeofencesStream(String userId) {
    return _database.ref('users/$userId/geofences').onValue;
  }

  static Future<void> deleteGeofence(
    String userId,
    String geofenceId,
  ) async {
    try {
      await _database.ref('users/$userId/geofences/$geofenceId').remove();
      Logger.info('Geofence deleted from database');
    } catch (e) {
      Logger.error('Delete geofence error: $e');
      rethrow;
    }
  }

  static Future<void> saveEmergencyContact({
    required String userId,
    required String contactId,
    required Map<String, dynamic> contactData,
  }) async {
    try {
      await _database
          .ref('users/$userId/emergencyContacts/$contactId')
          .set(contactData);
      Logger.info('Emergency contact saved to database');
    } catch (e) {
      Logger.error('Save emergency contact error: $e');
      rethrow;
    }
  }

  static Stream<DatabaseEvent> getEmergencyContactsStream(String userId) {
    return _database.ref('users/$userId/emergencyContacts').onValue;
  }

  static Future<void> deleteEmergencyContact(
    String userId,
    String contactId,
  ) async {
    try {
      await _database
          .ref('users/$userId/emergencyContacts/$contactId')
          .remove();
      Logger.info('Emergency contact deleted from database');
    } catch (e) {
      Logger.error('Delete emergency contact error: $e');
      rethrow;
    }
  }

  static Future<void> logAlertEvent({
    required String userId,
    required Map<String, dynamic> alertData,
  }) async {
    try {
      await _database
          .ref('users/$userId/alerts')
          .push()
          .set(alertData);
      Logger.info('Alert event logged to database');
    } catch (e) {
      Logger.error('Log alert event error: $e');
      rethrow;
    }
  }

  // Storage Methods
  static Future<String> uploadPhoto({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      final ref = _storage.ref('users/$userId/photos/$fileName');
      final uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      Logger.info('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Upload photo error: $e');
      rethrow;
    }
  }

  static Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(photoUrl);
      await ref.delete();
      Logger.info('Photo deleted successfully');
    } catch (e) {
      Logger.error('Delete photo error: $e');
      rethrow;
    }
  }

  static Future<List<String>> getUserPhotos(String userId) async {
    try {
      final listResult = await _storage.ref('users/$userId/photos').listAll();
      final urls = <String>[];
      for (var item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      return urls;
    } catch (e) {
      Logger.error('Get user photos error: $e');
      rethrow;
    }
  }
}

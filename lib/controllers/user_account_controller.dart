import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/reusables.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:csv/csv.dart';

class UserAccountController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<Map<String, dynamic>> login(String email, String password, BuildContext context) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User currentUser = credential.user!;
      final String uid = currentUser.uid;

      await _handleFCMToken(uid);

      return {'uid': uid, 'success': true};
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      showErrorDialog(context, errorMessage);
      return {'uid': null, 'success': false};
    }
  }

  Future<List<Map<String, dynamic>>> _loadPersonalListFromCSV() async {
    try {
      String csvData = await rootBundle.loadString('assets/caffeine.csv');

      List<List<dynamic>> csvList = const CsvToListConverter().convert(csvData);

      if (csvList.isEmpty) return [];

      final List<String> headers = csvList.first.map((e) => e.toString().trim()).toList();

      if (!headers.contains("Product") ||
          !headers.contains("Caffiene value (mg)") ||
          !headers.contains("Category") ||
          !headers.contains("Size (ml)")) {
        print("Error: Required headers missing in CSV");
        return [];
      }

      int nameIndex = headers.indexOf("Product");
      int caffeineIndex = headers.indexOf("Caffiene value (mg)");
      int categoryIndex = headers.indexOf("Category");
      int sizeIndex = headers.indexOf("Size (ml)");
      int relatedTermsIndex = headers.indexWhere((h) => h.contains("Related terms"));

      return csvList.skip(1).where((row) => row.length >= 4).map((row) {
        return {
          "name": row[nameIndex]?.toString().trim() ?? "Unknown",
          "caffeineAmount": double.tryParse(row[caffeineIndex]?.toString().trim() ?? "0.0") ?? 0.0,
          "category": row[categoryIndex]?.toString().trim() ?? "Unknown",
          "size": double.tryParse(row[sizeIndex]?.toString().trim() ?? "0.0") ?? 0.0,
          "relatedTerms": relatedTermsIndex != -1 && row.length > relatedTermsIndex
              ? row[relatedTermsIndex]?.toString().trim().split(';') ?? []
              : []
        };
      }).toList();
    } catch (e) {
      print("Error loading CSV: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    required double height,
    required double weight,
    required BuildContext context,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User currentUser = credential.user!;
      final String uid = currentUser.uid;

      List<Map<String, dynamic>> personalListItems = await _loadPersonalListFromCSV();

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "username": username,
        "height": height,
        "weight": weight,
      });

      await FirebaseFirestore.instance.collection("caffeine").doc(uid).set({
        "cafEnd": DateTime.now(),
        "totalMins": 0,
      });

      await FirebaseFirestore.instance.collection("hydration").doc(uid).set({
        "waterConsumed": 0,
        "lastDrink": Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection("hydrationHistory").doc(uid).set({
        "drinksConsumed": []
      });
      await FirebaseFirestore.instance.collection("caffeineHistory").doc(uid).set({
        "itemsConsumed": []
      });

      await FirebaseFirestore.instance.collection("personalList").doc(uid).set({
        "items": personalListItems,
      });

      // Initialize the FCM token when a new user signs up
      await _handleFCMToken(uid);

      return {'uid': uid, 'success': true};
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getSignUpErrorMessage(e.code);
      showErrorDialog(context, errorMessage);
      return {'uid': null, 'success': false};
    }
  }

  Future<void> _handleFCMToken(String uid) async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();

      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        print("FCM Token registered: $token");
      } else {
        print("FCM Token is null.");
      }
    } else {
      print("User denied notifications permission.");
    }
  }


  List<Map<String, dynamic>> parseCsv(String csvData) {
    final lines = const LineSplitter().convert(csvData);
    final headers = lines.first.split(',');

    return lines.skip(1).map((line) {
      final values = line.split(',');
      return Map.fromIterables(
        headers.map((header) => header.trim()),
        values.map((value) => value.trim()),
      );
    }).toList();
  }

  String _getSignUpErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'The email address is already in use.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        print(errorCode);
        return 'An unknown error occurred.';
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'invalid-login-credentials':
        return 'Incorrect password for that account.';
      case 'invalid-credential':
        return 'Incorrect password for that account.';
      case 'too-many-requests':
        return 'Too many attempts. You have been locked out temporarily.';
      case 'missing-password':
        return 'Please enter a password.';
      default:
        print(errorCode);
        return 'An unknown error occurred.';
    }
  }

  Future<Map<String, dynamic>> deleteAccount(BuildContext context) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No authenticated user found.',
        );
      }

      final String uid = currentUser.uid;

      // Delete user-related data from Firestore
      await _deleteUserDataFromFirestore(uid);

      // Delete the user from Firebase Auth
      await currentUser.delete();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      showErrorDialog(context, errorMessage);
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      showErrorDialog(context, 'An unexpected error occurred while deleting the account.');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _deleteUserDataFromFirestore(String uid) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Delete user's data from "users" collection
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    batch.delete(userDocRef);

    // Delete user's data from "caffeine" collection
    final caffeineDocRef = FirebaseFirestore.instance.collection('caffeine').doc(uid);
    batch.delete(caffeineDocRef);

    // Delete user's data from "caffeineHistory" collection
    final caffeineHistoryDocRef = FirebaseFirestore.instance.collection('caffeineHistory').doc(uid);
    batch.delete(caffeineHistoryDocRef);

    // Delete user's data from "hydration" collection
    final hydrationDocRef = FirebaseFirestore.instance.collection('hydration').doc(uid);
    batch.delete(hydrationDocRef);

    // Delete user's data from "hydrationHistory" collection
    final hydrationHistoryDocRef = FirebaseFirestore.instance.collection('hydrationHistory').doc(uid);
    batch.delete(hydrationHistoryDocRef);

    // Delete user's personalList collection
    final personalListDocRef = FirebaseFirestore.instance.collection('personalList').doc(uid);
    DocumentSnapshot doc = await personalListDocRef.get();
    batch.delete(personalListDocRef);

    // Commit all deletions
    await batch.commit();
  }
}

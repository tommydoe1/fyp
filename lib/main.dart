import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for iOS (if necessary)
  await messaging.requestPermission();

  // Set up background message handler (if your app is terminated or in the background)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize the local notifications plugin for foreground notifications
  NotificationService().initializeNotifications();

  // Handle foreground notifications
  handleForegroundMessages();

  // Get and save FCM token to Firestore for the user
  messaging.getToken().then((String? token) {
    if (token != null && FirebaseAuth.instance.currentUser != null) {
      // Save the token in Firestore under the user's document
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Caffeine App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Check if the user is signed in and show the appropriate page
      home: AuthWrapper(),
    );
  }
}

// A wrapper widget to handle the user's auth state and redirect accordingly
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes and navigate accordingly
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is signed in, navigate to the MenuPage with the UID, else show the WelcomePage
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // User is signed in, pass the UID to the MenuPage
            return MenuPage(uid: snapshot.data!.uid);  // Pass the user's UID to MenuPage
          } else {
            return WelcomePage();  // Show welcome page if user is not signed in
          }
        }
        return Center(child: CircularProgressIndicator());  // Show loading indicator while checking auth state
      },
    );
  }
}

// Background message handler (for when the app is closed or in the background)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.notification?.title}');
  // You can show a background notification here as well.
  NotificationService().showNotification(message); // This can show a notification even in the background
}

// Show notification in the foreground using local notifications
class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize notifications settings
  Future<void> initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show a notification
  Future<void> showNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    // Show a notification with a unique ID
    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
    );
  }
}

// Handle foreground messages
void handleForegroundMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received notification in the foreground: ${message.notification?.title}');
    // Show notification using local notifications
    NotificationService().showNotification(message);
  });
}

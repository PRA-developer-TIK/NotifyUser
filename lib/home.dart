import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:http/http.dart" as http;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  /// Create a [AndroidNotificationChannel] for heads up notifications
  late AndroidNotificationChannel channel;

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  TextEditingController userName = new TextEditingController();

  String? newToken = "";

  @override
  void initState() {
    super.initState();

    requestPermission();

    loadFCM();

    listenFCM();

    getToken();

    //we can also create topics
    FirebaseMessaging.instance.subscribeToTopic("Animal");
  }

  void sendMessage(String token) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAI48xSF0:APA91bE_MD19RM3JlX2Jd8NsL5EmOnvEqFLQXCeLoOW_L4M9anyVLjocKTn_6HsYTOrwk273fMQ2vkIw8df6WJ_zT7jvWNdy7hEuVp571FBJJf3f22gxv5R7auy72ejEHSZhidIbBNrS',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': 'Test Body',
              'title': 'Test Title 2'
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
            // "to": "/topics/Animal",
            "to": token,
          },
        ),
      );
    } catch (e) {
      print("error push notification");
    }
  }

  //to get token

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        this.newToken = token;
      });
      print("Token: $token");
      saveToken(token!);
    });
  }

  void getTokenFromFireStore() async {}

  //to save token
  void saveToken(String token) async {
    await FirebaseFirestore.instance.collection("Users").doc("User1").set({
      "token": token,
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      print("User denied permission");
    }
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,

              // TODO add a proper drawable resource to android, for now using
              //      one that already exists in example app.
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
  }

  void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title

        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      /// Create an Android Notification Channel.
      ///
      /// We use this channel in the `AndroidManifest.xml` file to override the
      /// default FCM channel to enable heads up notifications.
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      /// Update the iOS foreground notification presentation options to allow
      /// heads up notifications.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(
            controller: userName,
            decoration: InputDecoration(
              hintText: "Enter your name",
            ),
          ),
          GestureDetector(
            onTap: () async {
              String name = userName.text.trim();

              if (name != "") {
                DocumentSnapshot snap = await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(name)
                    .get();

                String token = snap['token'];
                print("token" + token);
                sendMessage(token);
              }
            },
            child: Container(
              height: 40,
              width: 200,
              color: Colors.red,
              child: const Center(
                child: Text('Home'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

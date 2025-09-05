import 'dart:async';
import 'dart:convert';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/Login.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/maps/environment.dart';
import 'package:bus_desk_pro/maps/here_new/common/ui_style.dart';
import 'package:bus_desk_pro/menu/motifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'menu/home.dart';
import 'menu/messages.dart';
import 'menu/documents.dart';
import 'menu/profile.dart';
import 'menu/more.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  /*runApp(MaterialApp(
    home: PermissionCheckScreen(),
    debugShowCheckedModeBanner: false, // optional
  ));*/
  runApp(_BusDeskPro());
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();

  // Beispiel: Prüfe ob alle erlaubt wurden
  bool allGranted = statuses.values.every((status) => status.isGranted);

  if (!allGranted) {
    // Hinweis anzeigen oder auf App-Einstellungen verweisen
    openAppSettings(); // optional
  }
}

class _BusDeskPro extends StatefulWidget {

  const _BusDeskPro({super.key});

  @override
  State<_BusDeskPro> createState() => BusDeskPro();
}

class BusDeskPro extends State<_BusDeskPro> {

  bool _isError = false;

  Future<void> _initSDK() async {
    try {
      SdkContext.init();
      await SDKNativeEngine.makeSharedInstance(
        SDKOptions.withAuthenticationMode(
          AuthenticationMode.withKeySecret(
            Environment.accessKeyId,
            Environment.accessKeySecret,
          ),
        ),
      );
      print('SDKNativueEngine created successflly!');
    } catch (e) {
      print('Failed to create SDKNativeEngine: $e');
      setState(() => _isError = true);
    }
  }

  @override
  void initState() {
    _initSDK();
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (_isError) return const InitErrorScreen();
    return MaterialApp(
      title: 'BusDesk Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.grey,
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
      ),
      //home: const MyHomePage(title: 'BusDesk Pro'),
      home: PermissionCheckScreen()
    );
  }
}

class InitErrorScreen extends StatelessWidget {
  const InitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(UIStyle.contentMarginExtraHuge),
                child: Text(
                  "HERE SDK konnte auf Deinem Gerät nicht geladen werden...",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          );
        },
      ),
      theme: UIStyle.lightTheme
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  @override
  _PermissionCheckScreenState createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    final statuses = await [Permission.location].request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      //setState(() => _permissionsGranted = true);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginCacheChecker()
          )
      );
    } else {
      // Dialog anzeigen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showPermissionDialog();
      });
    }
  }

  void showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Berechtigung benötigt'),
        content: Text(
          'Diese App benötigt Zugriff auf den Standort. Bitte erteile die Berechtigung in den App-Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: Text('Zu den Einstellungen'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //if (!_permissionsGranted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0), // optional für etwas Abstand
                child: Text(
                  'Berechtigung wird geprüft...\n\nSollten Sie die Berechtigungen gerade erst im Zuge des ersten Startvorgangs gesetzt haben, starten Sie die App bitte neu\n\n (Die App startet nicht von alleine neu)',
                  textAlign: TextAlign.center, // <--- das ist entscheidend
                  style: TextStyle(fontSize: 16), // optional: bessere Lesbarkeit
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    //}
  }
}

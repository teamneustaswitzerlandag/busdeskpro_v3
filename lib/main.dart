import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/Login.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/maps/environment.dart';
import 'package:bus_desk_pro/maps/here_new/common/ui_style.dart';
import 'package:bus_desk_pro/menu/motifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Systemleiste komplett verstecken für alle Android-Versionen
  if (Platform.isAndroid) {
    // Systemleiste komplett ausblenden
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  runApp(const _BusDeskPro());
}

// Hilfsfunktion um Systemleiste bei Bedarf wieder anzuzeigen
void showSystemUI() {
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);
  }
}

// Hilfsfunktion um Systemleiste wieder zu verstecken
void hideSystemUI() {
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
}

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();

  bool allGranted = statuses.values.every((status) => status.isGranted);

  if (!allGranted) {
    await openAppSettings(); // optional: öffne App-Einstellungen
  }
}

class _BusDeskPro extends StatefulWidget {
  const _BusDeskPro({super.key});

  @override
  State<_BusDeskPro> createState() => BusDeskPro();
}

class BusDeskPro extends State<_BusDeskPro> {
  bool _isError = false;
  bool _isSdkInitialized = false;

  @override
  void initState() {
    super.initState();

    // SDK Initialisierung nach dem ersten Frame, um UI-Blockade zu vermeiden
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSDK();
    });
  }

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
      print('SDKNativeEngine created successfully!');
      setState(() {
        _isSdkInitialized = true;
      });
    } catch (e) {
      print('Failed to create SDKNativeEngine: $e');
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) return const InitErrorScreen();

    // Solange SDK noch nicht fertig ist, zeige einen Lade-Bildschirm
    if (!_isSdkInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('App wird vorbereitet...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BusDesk Pro',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
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
      home: const PermissionCheckScreen(),
    );
  }
}

class InitErrorScreen extends StatelessWidget {
  const InitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UIStyle.lightTheme,
      home: Scaffold(
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(UIStyle.contentMarginExtraHuge),
              child: Text(
                "HERE SDK konnte auf Deinem Gerät nicht geladen werden...",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  _PermissionCheckScreenState createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [Permission.location].request();
    final allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Wenn Berechtigungen da sind, direkt navigieren
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginCacheChecker()),
      );
    } else {
      // Berechtigungsdialog nach Frame zeigen, UI bleibt sichtbar
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }

    setState(() {
      _checking = false;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Berechtigung benötigt'),
        content: const Text(
          'Diese App benötigt Zugriff auf den Standort. Bitte erteile die Berechtigung in den App-Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
            },
            child: const Text('Zu den Einstellungen'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _checking
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Berechtigung wird geprüft...\n\nSollten Sie die Berechtigungen gerade erst im Zuge des ersten Startvorgangs gesetzt haben, starten Sie die App bitte neu\n\n(Die App startet nicht von alleine neu)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        )
            : const SizedBox.shrink(), // leer falls fertig geprüft
      ),
    );
  }
}
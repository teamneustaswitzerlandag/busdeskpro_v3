import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bus_desk_pro/Login.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:bus_desk_pro/menu/motifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:bus_desk_pro/widgets/curved_bottom_nav.dart';
import 'package:bus_desk_pro/widgets/mandant_config_dialog.dart';

class LandingPage extends StatefulWidget {

  final String? phonenumber;
  final String? mandant;

  const LandingPage({super.key, required this.title, this.phonenumber, this.mandant});

  final String title;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    // Performance-Optimierung: Nur bei tatsächlicher Änderung
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  final _storage = FlutterSecureStorage();

  late List<Widget> _pages = [];

  Timer? _newsTimer;

  final String apkUrl = 'http://vcs-demo.westeurope.cloudapp.azure.com/busdeskpro/app-release-${AppVersionDashed}.apk'; // Ersetze dies mit deiner tatsächlichen URL

  @override
  void initState() {
    super.initState();
    _pages = [
      TourListScreen(),
      NotificationsPage(),
      if (checkIfAnyModuleIsActive('Chat') == true)
        MessagesPage(),
      if (checkIfAnyModuleIsActive('Documents') == true)
        DocumentListPage(),
      ProfilePage(),
      MorePage(),
    ];
  }

  @override
  void dispose() {
    _newsTimer?.cancel(); // Timer beenden
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Flexible( // Flexible statt ConstrainedBox
              child: Image.memory(
                base64Decode(getLogo('logo')),
                fit: BoxFit.contain,
                height: 40,
                cacheWidth: 200, // Speicher-Optimierung
                cacheHeight: 40,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_alt),
            tooltip: 'Mandanteneinstellungen anzeigen',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MandantConfigDialog(),
              );
            }
          ),
          IconButton(
            icon: Icon(Icons.system_update),
            tooltip: 'Neue Version herunterladen',
            onPressed: () => _showUpdateDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              MandantAuth = "";
              PhoneNumberAuth = "";
              cacheTourList = false;
              AllToursGbl = [];
              FilteredToursGbl = [];
              ExpandedToursGbl = [];
              isLoading = true;
              await _storage.write(key: 'deviceCachedPhonenumber', value: null);
              await _storage.write(key: 'deviceCachedTenant', value: null);
              await _storage.write(key: 'deviceCachedMandant', value: null);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            }
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Alle Seiten werden im Speicher gehalten
      ),
      bottomNavigationBar: CurvedBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        showChat: checkIfAnyModuleIsActive('Chat') == true,
        showDocuments: checkIfAnyModuleIsActive('Documents') == true,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.info),
        label: 'Dienste',
      ),
    ];

    if (checkIfAnyModuleIsActive('Chat') == true) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Chat',
      ));
    }

    if (checkIfAnyModuleIsActive('Documents') == true) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Dok',
      ));
    }

    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Mehr',
      ),
    ]);

    return items;
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Version herunterladen'),
          content: const Text('Um die aktuellste Version von BusDesk Pro zu laden, klicke nachfolgend auf "Jetzt herunterladen".'),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => launchUrlString(apkUrl),
                child: const Text('Jetzt herunterladen', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }
}

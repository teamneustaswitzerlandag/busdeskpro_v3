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
    setState(() {
      _currentIndex = index;
    });
  }

  final _storage = FlutterSecureStorage();

  late List<Widget> _pages = [];

  Timer? _newsTimer;

  final String apkUrl = 'http://vcs-demo.westeurope.cloudapp.azure.com/busdeskpro/app-release-prod-${MandantAuth}.apk'; // Ersetze dies mit deiner tatsächlichen URL

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
    super.dispose();
  }

  int _newsCount = 0;
  String? _currentCount = '';
  void startNewsCountTimer(int intervalInSeconds) {
    _newsTimer = Timer.periodic(Duration(seconds: intervalInSeconds), (Timer timer) async {
      try {
        final storage = FlutterSecureStorage();
        _currentCount = await storage.read(key: 'gbl_notifications_amount');
        print('TimerNews');
        newsCount = await fetchNewsCount();

        if (!mounted) return;

        setState(() {
          _newsCount = newsCount;
        });
        print(newsCount);
        print(_currentCount);
      } catch (e) {
        print('Fehler beim Abrufen der Nachrichtenanzahl: $e');
      }
    });
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
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 200, // Setze hier die gewünschte maximale Breite
              ),
              child: Image.memory(
                base64Decode(getLogo('logo')),
                fit: BoxFit.contain,
                height: 50,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_alt),
            tooltip: 'Mandanteneinstellungen neu syncronisieren',
            onPressed: () async {
              showCustomDialog(context, "Bitte warten...", "Die Einstellungen zu Ihrem Mandanten werden auf Ihr Gerät neu syncronisiert.\n\nDies kann ein par Minuten dauern...", []);
              final response = await http.get(Uri.parse('http://bus-dashboard.dxp.azure.neusta.cloud:7698/getTenants'));
              if (response.statusCode == 200) {
                final decoded = json.decode(response.body); // Typ: Map<String, dynamic>
                List<dynamic> tenants = decoded['body'];
                for (var tenant in tenants) {
                  if (tenant['name'] == MandantAuth) {
                    await _storage.write(key: 'deviceCachedTenant', value: jsonEncode(tenant));
                  }
                }
              } else {
                throw Exception('Failed to load tenants');
              }
              Navigator.pop(context);
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
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),/*Stack(
              children: <Widget>[
                Icon(Icons.info),
                if (_currentCount != _newsCount.toString())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                    ),
                  ),
              ],
            ),*/
            label: 'Dienste',
          ),
          if (checkIfAnyModuleIsActive('Chat') == true)
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
          if (checkIfAnyModuleIsActive('Documents') == true)
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Dok',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Mehr',
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Version herunterladen'),
          content: Text('Um die aktuellste Version von BusDesk Pro zu laden, klicke nachfolgend auf "Jetzt herunterladen".'),
          actions: <Widget>[
            Container(
                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Abbrechen', style: TextStyle(color: Colors.white)),
                )),
            Container(
                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                  onPressed: () async {
                    launchUrlString(apkUrl);
                  },
                  child: Text('Jetzt herunterladen', style: TextStyle(color: Colors.white)),
                )),
          ],
        );
      },
    );
  }
}

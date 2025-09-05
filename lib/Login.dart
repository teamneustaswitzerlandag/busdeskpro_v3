import 'dart:convert';
import 'dart:math';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/Login2.dart';
import 'package:bus_desk_pro/libaries/blinking_point.dart';
import 'package:bus_desk_pro/libaries/countdown_loader.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:bus_desk_pro/libaries/tour.dart';
import 'package:bus_desk_pro/main.dart';
//import 'package:bus_desk_pro/maps/maps-base-kopie-example2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

//const String flavor = String.fromEnvironment('flavor', defaultValue: 'prod');

class LoginCacheChecker extends StatefulWidget {
  LoginCacheChecker({Key? key}) : super(key: key);

  @override
  _CheckConditionWidgetState createState() => _CheckConditionWidgetState();
}

class _CheckConditionWidgetState extends State<LoginCacheChecker> {

  @override
  void initState() {
    super.initState();
    _executeCustomLogic();
  }

  void _executeCustomLogic() async {
    final _storage = FlutterSecureStorage();
    var storedPhonenumber = await _storage.read(key: 'deviceCachedPhonenumber');
    var storedMandant = await _storage.read(key: 'deviceCachedMandant');
    var storedTenant = await _storage.read(key: 'deviceCachedTenant');
    startLocationUpdates();
    Timer(Duration(seconds: 3), () {
      if (storedPhonenumber == null && storedTenant == null && storedMandant == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        PhoneNumberAuth = storedPhonenumber?? '';
        MandantAuth = storedMandant?? '';
        GblTenant = jsonDecode(storedTenant??'');
        InitUniqueAppUserId();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LandingPage(
                title: 'BusDesk Pro',
              ),
            )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Hintergrundfarbe auf weiß setzen
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text(
                'App wird geladen...',
                style: TextStyle(fontSize: 18, color: Colors.black), // Textfarbe auf schwarz setzen
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //LoginScreen({Key? key}) : super(key: key);

  void initState() {
    super.initState();
  }

  final TextEditingController tenantController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  String selectedCountryCode = "+49";
  final _storage = FlutterSecureStorage();

  bool isLoading2FAGbl = true;

  Future<void> checkTenant(String tenantName) async {
    GblTenant = null;
    final response = await http.get(Uri.parse('http://bus-dashboard.dxp.azure.neusta.cloud:7698/getTenants'));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body); // Typ: Map<String, dynamic>
      List<dynamic> tenants = decoded['body'];
      for (var tenant in tenants) {
        if (tenant['name'] == tenantName) {
          GblTenant = tenant;
          await _storage.write(key: 'deviceCachedTenant', value: jsonEncode(tenant));
          return;
        }
      }
      print('Tenant not found');
    } else {
      throw Exception('Failed to load tenants');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    /*appBar: AppBar(
        backgroundColor: Colors.white,
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            //Text(widget.title),
            Image.asset(
                'lib/assets/app_logo.png',
                fit: BoxFit.contain,
                width: 200,
                height: 50
            )
          ],
        ),
        actions: [],
      ),*/
      body: Stack(
        children: [
          // Hintergrundbild
          Positioned.fill(
            child: Image.asset(
              'lib/assets/app_tile_2.png', // Dein Hintergrundbild hier
              fit: BoxFit.cover,
            ),
          ),
          // Weißes Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.9), // Halbtransparentes weißes Overlay
            ),
          ),
          // Dein Inhalt
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Text(
                  "",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Mandant",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                /*const Text(
                  "Die Ihnen zur Verfügung gestellte Mandant-ID",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),*/
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  child: TextField(
                    controller: tenantController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      hintText: "Mandant eingeben",
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Mobilfunknummer",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                /*const Text(
                  "Ihre Mobilnummer, welche bei Ihrer Organisation gemeldet ist. Dies wird benötigt, um Sie als Fahrer zu identifizieren",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),*/
                const SizedBox(height: 8),
                Container(
                  height: 50,
                  child: Row(
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: DropdownButton<String>(
                          value: selectedCountryCode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: "+49",
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 16),
                                  SizedBox(width: 8),
                                  Text("+49"),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "+1",
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 16),
                                  SizedBox(width: 8),
                                  Text("+1"),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "+91",
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 16),
                                  SizedBox(width: 8),
                                  Text("+91"),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              selectedCountryCode = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          child: TextField(
                            controller: phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              hintText: "Rufnummer eingeben",
                              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            void sendHandler() async {
                              isLoading2FAGbl = true;
                              statusMessageGbl = "Authentifizierungscode wird gesendet...";
                              String phoneNumber = "$selectedCountryCode ${phoneNumberController.text}";
                              String phoneNumberForCM = "$selectedCountryCode${phoneNumberController.text}".replaceAll("+", "00");
                              verificationCodeGbl = (1000 + Random().nextInt(9000)).toString();

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) =>
                                    StatefulBuilder(
                                      builder: (context, setStateModal) =>
                                          AlertDialog(
                                              title: Text("2FA Authentifizierung"),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text("Wir senden einen Code an Ihre Rufnummer..."),
                                                ],
                                              ),
                                              actions: []
                                          ),
                                    ),
                              );

                              final url = Uri.parse(
                                  'https://gw.messaging.cm.com/v1.0/message');
                              final headers = {
                                'accept': 'application/json',
                                'content-type': 'application/json',
                                'X-CM-PRODUCTTOKEN': '0aae9b97-db6e-4c8f-9c27-d10d0a63da1e',
                              };
                              final body = jsonEncode({
                                "messages": {
                                  "msg": [
                                    {
                                      "from": "2FA",
                                      "to": [{"number": phoneNumberForCM}],
                                      "body": {
                                        "type": "auto",
                                        "content": "Dein Code lautet: $verificationCodeGbl"
                                      },
                                      "reference": "my_reference_${DateTime.now().millisecondsSinceEpoch}"
                                    }
                                  ]
                                }
                              });

                              try {
                                final response = await http.post(url, headers: headers, body: body);
                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  showCustomDialog(context, "Überprüfung Mandant", "Wir prüfen die Gültigkeit des Mandanten.\n\n Dieser Vorgang ist einmalig pro Login und kann ein paar Minuten dauern.", []);
                                  await checkTenant(tenantController.text);
                                  Navigator.pop(context);
                                  if (GblTenant == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Mandant ungültig!')),
                                    );
                                    return;
                                  }
                                  InitUniqueAppUserId();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        StatefulBuilder(
                                          builder: (context, setStateModal) =>
                                              AlertDialog(
                                                title: Text("2FA Authentifizierung"),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text("Ein Authentifizierungscode wurde an $phoneNumber gesendet."),
                                                  ],
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                                                    onPressed: () async {
                                                      Navigator.of(context).pop();
                                                      PhoneNumberAuth = "$selectedCountryCode${phoneNumberController.text}";
                                                      MandantAuth = tenantController.text;
                                                      await _storage.write(key: 'deviceCachedPhonenumber', value: PhoneNumberAuth);
                                                      print('LOGIN2');
                                                      print(PhoneNumberAuth);
                                                      await _storage.write(key: 'deviceCachedMandant', value: MandantAuth);
                                                      sendLogs("login_step1", "$selectedCountryCode${phoneNumberController.text}");
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => CodeInputScreen(),
                                                          )
                                                      );
                                                    },
                                                    child: Text("Code eingeben", style: TextStyle(color: Colors.white)),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                      sendHandler();
                                                    },
                                                    child: Text("Neuen Code anfordern", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                        ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                        StatefulBuilder(
                                          builder: (context, setStateModal) =>
                                              AlertDialog(
                                                title: Text("2FA Authentifizierung"),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text("Ein Fehler beim Senden ist augetreten. Bitte versuchen Sie es erneut."),
                                                  ],
                                                ),
                                                actions: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red,),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                      sendHandler();
                                                    },
                                                    child: Text("Erneut versuchen", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                        ),
                                  );
                                }
                              } catch (e) {
                                isLoading = false;
                                setState(() {
                                  isLoading2FAGbl = false;
                                  statusMessageGbl = "Fehler: $e";
                                });
                              }

                              /*final tenant = tenantController.text;
                            final phoneNumber =
                                "$selectedCountryCode ${phoneNumberController.text}";
                            if (phoneNumber == null || phoneNumber == "" || phoneNumber.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Bitte gebe Deine Telefonnummer an!')),
                              );
                              return;
                            }
                            if (tenant == null || tenant == "") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Bitte gebe Deinen Mandanten an!')),
                              );
                              return;
                            }

                            showCustomDialog(context, "Überprüfung Mandant", "Wir prüfen die Gültigkeit des Mandanten.\n\n Dieser Vorgang ist einmalig pro Login und kann ein paar Minuten dauern.", []);
                            await checkTenant(tenant);
                            Navigator.pop(context);
                            if (GblTenant == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Mandant ungültig!')),
                              );
                              return;
                            }
                            InitUniqueAppUserId();
                            showDialogNotification(context, "$selectedCountryCode${phoneNumberController.text}", tenantController.text);
                            */
                            }
                            sendHandler();
                          },
                          child: Text('Authentifizierungscode anfordern', style: TextStyle(color: Colors.white)),
                        ),
                      )),
                /*TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SampleNavigationApp24(),
                        )
                    );
                  },
                  child: Text('Test'),
                ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showDialogNotification(BuildContext context, String phonenumber, String mandant) {
    int code = Random().nextInt(9000) + 1000;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Bitte kopiere folgenden Code',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
              )
          ),
          content: Text(
              code.toString(),
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
              )
          ),
          actions: [
          Container(
            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
            child:
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  Clipboard.setData(ClipboardData(text: code.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code wurde kopiert!')),
                  );
                  Navigator.of(context).pop();
                  AuthCode = code.toString();
                  PhoneNumberAuth = phonenumber;
                  MandantAuth = mandant;
                  await _storage.write(key: 'deviceCachedPhonenumber', value: PhoneNumberAuth);
                  print('LOGIN2');
                  print(PhoneNumberAuth);
                  await _storage.write(key: 'deviceCachedMandant', value: MandantAuth);
                  sendLogs("login_step1", phonenumber);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CodeInputScreen(),
                      )
                  );
                },
                child: Text('kopieren', style: TextStyle(color: Colors.white)),
            )),
          ],
        );
      },
    );
  }
}
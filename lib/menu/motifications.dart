import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/others/BeforeDrive.dart';
import 'package:bus_desk_pro/others/Order.dart';
//import 'package:bus_desk_pro/others/QRToMaterial.dart';
//import 'package:bus_desk_pro/others/QRToVehicle.dart';
//import 'package:bus_desk_pro/others/VehicleToMaterial.dart';
import 'package:bus_desk_pro/others/accident.dart';
import 'package:bus_desk_pro/others/lost_found.dart';
import 'package:bus_desk_pro/others/materialdashboard.dart';
import 'package:bus_desk_pro/others/newsboard.dart';
import 'package:bus_desk_pro/others/servicerepair.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _KachelGridState createState() => _KachelGridState();
}

class _KachelGridState extends State<NotificationsPage> {
  // Labels für die Buttons
  String button1Label = 'schwarzes Brett';
  String button2Label = 'Lost + Found';
  String button3Label = 'Servicereparatur';
  String button4Label = 'Unfallmeldung';
  String button5Label = 'Kleiderbestellung';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Meldungen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
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
          Center(
            child: GridView.count(
              crossAxisCount: 2, // 2 Spalten
              mainAxisSpacing: 16.0, // Abstand zwischen den Zeilen
              crossAxisSpacing: 16.0, // Abstand zwischen den Spalten
              padding: EdgeInsets.all(16.0), // Außenabstand
              childAspectRatio: 1, // Kachelproportion (1 = quadratisch)
              children: [
                if (checkIfAnyModuleIsActive('Notifications') == true)
                  buildKachel(
                    icon: Icons.info,
                    label: button1Label,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsBoard(),
                        ),
                      );
                    },
                  ),
                if (checkIfAnyModuleIsActive('LostFound') == true)
                  buildKachel(
                    icon: Icons.find_replace,
                    label: button2Label,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostAndFoundForm(),
                        ),
                      );
                    },
                  ),
                if (checkIfAnyModuleIsActive('ServiceRepair') == true)
                  buildKachel(
                    icon: Icons.build,
                    label: button3Label,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Servicerepair(),
                        ),
                      );
                    },
                  ),
                if (checkIfAnyModuleIsActive('AccidentReport') == true)
                  buildKachel(
                    icon: Icons.car_crash,
                    label: button4Label,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EuropeanAccidentReport(),
                        ),
                      );
                    },
                  ),
                if (checkIfAnyModuleIsActive('ClothOrders') == true)
                  buildKachel(
                    icon: Icons.checkroom,
                    label: button5Label,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderPage(),
                        ),
                      );
                    },
                  ),
                if (checkIfAnyModuleIsActive('MaterialMapping') == true)
                  buildKachel(
                    icon: Icons.qr_code,
                    label: 'Material/ Fahrzeug',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaterialDashboard(),
                        ),
                      );
                    },
                  ),
                buildKachel(
                  icon: Icons.gas_meter,
                  label: 'Tankvorgang starten',
                  onPressed: () {
                    startVorgangDialog(context, 'Tankvorgang');
                  },
                ),
                buildKachel(
                  icon: Icons.wash,
                  label: 'Waschvorgang starten',
                  onPressed: () {
                    startVorgangDialog(context, 'Waschvorgang');
                  },
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  void startVorgangDialog(BuildContext context, String vorgangsName) {
    final TextEditingController controller = TextEditingController();
    bool isButtonEnabled = false;
    var vehicle = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Gebe die Kennung deines Fahrzeuges ein'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'Kennung'),
                onChanged: (value) {
                  setState(() {
                    isButtonEnabled = value.trim().isNotEmpty;
                    vehicle = value.trim();
                  });
                },
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                  onPressed: isButtonEnabled
                      ? () {
                    Navigator.of(context).pop(); // Eingabe-Dialog schließen
                    _showVorgangLaeuftDialog(context, vorgangsName);
                    sendLogs('started_${vorgangsName}', '${vehicle}');
                  }
                      : null,
                  child: Text('Jetzt $vorgangsName starten', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVorgangLaeuftDialog(BuildContext context, String vorgangsName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('$vorgangsName läuft'),
          content: Text('\n\n'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
              onPressed: () {
                Navigator.of(context).pop(); // Vorgang beenden
              },
              child: Text('Jetzt $vorgangsName beenden', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget buildKachel({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 40, color: HexColor.fromHex(getColor('primary'))),
          onPressed: onPressed,
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
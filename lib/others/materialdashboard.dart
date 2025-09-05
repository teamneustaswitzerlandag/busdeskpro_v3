import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/others/BeforeDrive.dart';
import 'package:bus_desk_pro/others/Order.dart';
//import 'package:bus_desk_pro/others/QRToMaterial.dart';
//import 'package:bus_desk_pro/others/QRToVehicle.dart';
//import 'package:bus_desk_pro/others/VehicleToMaterial.dart';
import 'package:bus_desk_pro/others/accident.dart';
import 'package:bus_desk_pro/others/lost_found.dart';
import 'package:bus_desk_pro/others/newsboard.dart';
import 'package:bus_desk_pro/others/servicerepair.dart';
import 'package:flutter/material.dart';

class MaterialDashboard extends StatefulWidget {
  @override
  _KachelGridState2 createState() => _KachelGridState2();
}

class _KachelGridState2 extends State<MaterialDashboard> {
  // Labels für die Buttons
  String button1Label = 'schwarzes Brett';
  String button2Label = 'Lost + Found';
  String button3Label = 'Servicereparatur';
  String button4Label = 'Unfallmeldung';
  String button5Label = 'Kleiderbestellung';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material/ Fahrzeug', style: TextStyle(color: Colors.white)),
        backgroundColor: HexColor.fromHex(getColor('primary')),
      ),
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
                buildKachel(
                  icon: Icons.car_rental,
                  label: 'Fahrzeug',
                  onPressed: () {
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScannerVehicle(),
                      ),
                    );*/
                  },
                ),
                buildKachel(
                  icon: Icons.account_box,
                  label: 'Material',
                  onPressed: () {
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScannerMaterial(),
                      ),
                    );*/
                  },
                ),
                buildKachel(
                  icon: Icons.private_connectivity,
                  label: 'Material in Fahrzeug',
                  onPressed: () {
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRScannerVehicleMaterial(),
                      ),
                    );*/
                  },
                ),

              ],
            ),
          ),
        ],
      ),
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
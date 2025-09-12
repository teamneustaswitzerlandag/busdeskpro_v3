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
import 'package:bus_desk_pro/config/globals.dart';

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
  void initState() {
    super.initState();
  }

  // Optimierte Navigation mit Preloading
  void _navigateToPage(BuildContext context, Widget page, String pageName) {
    // Sofortige Navigation ohne Animation-Delay
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration(milliseconds: 150), // Schnellere Transition
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Services',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Hintergrundbild - Optimiert
          Positioned.fill(
            child: RepaintBoundary( // Isoliert das Hintergrundbild
              child: Image.asset(
                'lib/assets/app_tile_2.png',
                fit: BoxFit.cover,
                cacheWidth: MediaQuery.of(context).size.width.toInt(),
                cacheHeight: MediaQuery.of(context).size.height.toInt(),
              ),
            ),
          ),
          // Weißes Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          // Content - Optimiert
          Center(
            child: RepaintBoundary( // Isoliert den Grid
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                padding: EdgeInsets.all(16.0),
                childAspectRatio: 1,
                children: [
                  if (checkIfAnyModuleIsActive('Notifications') == true)
                    _buildOptimizedKachel(
                      icon: Icons.info,
                      label: button1Label,
                      onPressed: () => _navigateToPage(context, NewsBoard(), 'NewsBoard'),
                    ),
                  if (checkIfAnyModuleIsActive('LostFound') == true)
                    _buildOptimizedKachel(
                      icon: Icons.find_replace,
                      label: button2Label,
                      onPressed: () => _navigateToPage(context, LostAndFoundForm(), 'LostFound'),
                    ),
                  if (checkIfAnyModuleIsActive('ServiceRepair') == true)
                    _buildOptimizedKachel(
                      icon: Icons.build,
                      label: button3Label,
                      onPressed: () => _navigateToPage(context, Servicerepair(), 'ServiceRepair'),
                    ),
                  if (checkIfAnyModuleIsActive('AccidentReport') == true)
                    _buildOptimizedKachel(
                      icon: Icons.car_crash,
                      label: button4Label,
                      onPressed: () => _navigateToPage(context, EuropeanAccidentReport(), 'AccidentReport'),
                    ),
                  if (checkIfAnyModuleIsActive('ClothOrders') == true)
                    _buildOptimizedKachel(
                      icon: Icons.checkroom,
                      label: button5Label,
                      onPressed: () => _navigateToPage(context, OrderPage(), 'ClothOrders'),
                    ),
                  if (checkIfAnyModuleIsActive('MaterialMapping') == true)
                    _buildOptimizedKachel(
                      icon: Icons.qr_code,
                      label: 'Material/ Fahrzeug',
                      onPressed: () => _navigateToPage(context, MaterialDashboard(), 'MaterialMapping'),
                    ),
                  _buildOptimizedKachel(
                    icon: Icons.gas_meter,
                    label: 'Tankvorgang starten',
                    onPressed: () => startVorgangDialog(context, 'Tankvorgang'),
                  ),
                  _buildOptimizedKachel(
                    icon: Icons.wash,
                    label: 'Waschvorgang starten',
                    onPressed: () => startVorgangDialog(context, 'Waschvorgang'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Optimierte Kachel-Erstellung
  Widget _buildOptimizedKachel({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return RepaintBoundary( // Jede Kachel isoliert
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: HexColor.fromHex(getColor('primary')),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimierte Dialog-Methoden
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
                  style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary'))),
                  onPressed: isButtonEnabled
                      ? () {
                    Navigator.of(context).pop();
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
              style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary'))),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Jetzt $vorgangsName beenden', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
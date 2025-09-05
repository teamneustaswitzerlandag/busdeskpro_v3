import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeoRadiusScreen extends StatefulWidget {
  @override
  _GeoRadiusScreenState createState() => _GeoRadiusScreenState();
}

class _GeoRadiusScreenState extends State<GeoRadiusScreen> {
  late TextEditingController _radiusController;

  int geoRadius = 20; // Beispiel-Initialwert
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadGeoRadiusSetting();
  }

  Future<void> loadGeoRadiusSetting() async {
    var geoRadiusSetting = await _storage.read(key: 'geoRadiusSetting');
    setState(() {
      geoRadius = int.parse(geoRadiusSetting??'0');
    });
    _radiusController = TextEditingController(text: geoRadius.toString());
  }

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  void _saveRadius() async {
    await _storage.write(key: 'geoRadiusSetting', value: _radiusController.text);
    setState(() {
      geoRadius = int.tryParse(_radiusController.text) ?? geoRadius;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Geo-Radius auf $geoRadius Meter gesetzt")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: const Text(
          'Geo-Radius setzen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Geo-Radius (in Metern)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Radius eingeben",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: HexColor.fromHex(getColor('primary')),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // keine runden Ecken
            ),
          ),
          onPressed: _saveRadius,
          child: const Text(
            "Radius speichern",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
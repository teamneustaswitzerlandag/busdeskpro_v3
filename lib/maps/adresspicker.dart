import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/main.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:bus_desk_pro/menu/home.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../maps/mapEngine.dart';

/*class AdressPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adresse zu Koordinaten',
      home: AddressAutocompleteView(),
    );
  }
}*/

class AdressPicker extends StatefulWidget {
  @override
  _AddressAutocompleteViewState createState() =>
      _AddressAutocompleteViewState();
}

class _AddressAutocompleteViewState extends State<AdressPicker> {
  final TextEditingController _addressController = TextEditingController();
  List<String> _suggestions = [];
  String _latitude = '';
  String _longitude = '';
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _fetchSuggestions(String input) async {
    const String apiKey = 'AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg'; // Ersetze mit deinem API-Schlüssel
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = (data['predictions'] as List)
                .map((prediction) => prediction['description'] as String)
                .toList();
          });
        } else {
          setState(() {
            _suggestions = [];
          });
        }
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _getCoordinates(String address) async {
    const String apiKey = 'AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg'; // Ersetze mit deinem API-Schlüssel
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['results'][0]['geometry']['location'];
          setState(() {
            _latitude = location['lat'].toString();
            _longitude = location['lng'].toString();
            _errorMessage = '';
          });
        } else {
          setState(() {
            _errorMessage = 'Adresse konnte nicht gefunden werden.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Fehler bei der API-Anfrage: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ein Fehler ist aufgetreten: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Row(
          children: [
            /*IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(title: "BusDes Pro"),
                    ),
                  )
                }
            ),*/
            Text(
              'Individuelles Ziel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.0,
              ),
            )
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Gebe Deine gewünschte Zieladresse ein. Während Deiner Eingabe bekommst Du Vorschläge angezeigt.', style: TextStyle(color: Colors.black)),
            SizedBox(height: 8),
            TextField(
              controller: _addressController,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _fetchSuggestions(value);
                } else {
                  setState(() {
                    _suggestions = [];
                  });
                }
              },
              decoration: InputDecoration(
                //labelText: 'Adresse eingeben',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            if (_suggestions.isNotEmpty)
              Container(
                height: 150,
                child: ListView.builder(
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_suggestions[index]),
                      onTap: () {
                        setState(() {
                          _addressController.text = _suggestions[index];
                          _suggestions = [];
                        });
                        _getCoordinates(_addressController.text);
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor.fromHex(getColor('primary')),
                ),
                onPressed: () {
                  final address = _addressController.text.trim();
                  if (address.isNotEmpty) {
                    _getCoordinates(address);
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitNavigationMap(
                        lat: double.parse(_latitude.replaceAll(",", ".")),
                        long: double.parse(_longitude.replaceAll(",", ".")),
                        isFreeDrive: true
                      ),
                    ),
                  );
                },
                child: Text('Ziel festlegen und Navigation starten', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              CircularProgressIndicator(),
            if (_latitude.isNotEmpty && _longitude.isNotEmpty)
              Column(
                children: [
                  Text('Breitengrad: $_latitude'),
                  Text('Längengrad: $_longitude'),
                ],
              ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
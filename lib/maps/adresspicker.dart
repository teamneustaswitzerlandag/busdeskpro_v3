import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/main.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:bus_desk_pro/menu/home.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../maps/mapEngine.dart';
import 'package:bus_desk_pro/config/globals.dart';

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
    const String apiKey = 'AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Individuelles Ziel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Geben Sie Ihre gewünschte Zieladresse ein. Während der Eingabe erhalten Sie Vorschläge.',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Suchfeld
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
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
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Adresse eingeben...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search_rounded, color: HexColor.fromHex(getColor('primary'))),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Vorschläge
            if (_suggestions.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: HexColor.fromHex(getColor('primary')), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Vorschläge',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
                      separatorBuilder: (context, index) => Divider(height: 1, indent: 48),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.place_rounded,
                              color: HexColor.fromHex(getColor('primary')),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _suggestions[index],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
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
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // Navigation Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor.fromHex(getColor('primary')),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : () async {
                  final address = _addressController.text.trim();
                  if (address.isEmpty) {
                    setState(() {
                      _errorMessage = 'Bitte geben Sie eine Adresse ein.';
                    });
                    return;
                  }
                  
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  
                  await _getCoordinates(address);
                  
                  if (!mounted) return;
                  
                  if (_latitude.isNotEmpty && _longitude.isNotEmpty) {
                    setState(() {
                      _isLoading = false;
                    });
                    
                    // Für freie Navigation: GblStops wie bei Tour-Navigation füllen
                    // Stop 0: Aktueller Standort
                    // Stop 1: Ziel (die ausgewählte Adresse)
                    final destinationLat = double.parse(_latitude.replaceAll(",", "."));
                    final destinationLong = double.parse(_longitude.replaceAll(",", "."));
                    
                    // Aktuelles Datum/Zeit für isostring
                    final now = DateTime.now();
                    final isoString = now.toIso8601String();
                    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    
                    // Erstelle zwei Stops mit allen benötigten Properties
                    GblStops = [
                      {
                        'lat': currentPosition?.latitude?.toString() ?? '0',
                        'long': currentPosition?.longitude?.toString() ?? '0',
                        'lng': currentPosition?.longitude?.toString() ?? '0',
                        'address': 'Aktueller Standort',
                        'time': timeString,
                        'firstname': '',
                        'lastname': 'Freies Routing Fahrerstart',
                        'station_id': 1,
                        'isostring': isoString,
                        'stopp_type': 99,
                        'canceled': false,
                      },
                      {
                        'lat': destinationLat.toString(),
                        'long': destinationLong.toString(),
                        'lng': destinationLong.toString(),
                        'address': _addressController.text.trim(),
                        'time': timeString,
                        'firstname': '',
                        'lastname': 'Freies Routing',
                        'station_id': 2,
                        'isostring': isoString,
                        'stopp_type': 99,
                        'canceled': false,
                      }
                    ];
                    TourNameGbl = 'Freie Navigation';
                    ArrivalTimesReal = [];
                    currentStoppIndex = 1; // Navigiere zum zweiten Stop (Index 1), also dem Ziel
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InitNavigationMap(
                          lat: destinationLat,
                          long: destinationLong,
                          isFreeDrive: false
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _isLoading = false;
                      if (_errorMessage.isEmpty) {
                        _errorMessage = 'Koordinaten konnten nicht ermittelt werden.';
                      }
                    });
                  }
                },
                child: _isLoading 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Wird geladen...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Navigation starten',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
            
            // Koordinaten Info (wenn vorhanden)
            if (_latitude.isNotEmpty && _longitude.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adresse gefunden',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Koordinaten: $_latitude, $_longitude',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Fehlermeldung
            if (_errorMessage.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
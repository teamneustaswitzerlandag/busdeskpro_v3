import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bus_desk_pro/libaries/logs.dart';

class WCFinderModule {
  static double _searchRadius = 1000.0;
  static LatLng? _currentLocation;
  static bool _isLoadingLocation = false;
  static Set<Marker> _wcMarkers = {};
  static GoogleMapController? _mapController;
  static List<Map<String, dynamic>> _currentWCs = [];
  static StateSetter? _dialogStateSetter;
  static Map<String, String> _addressCache = {};
  static bool _isSearchingWCs = false;

  static void showWCFinderPopup(BuildContext context, Map<String, dynamic> travel) {
    // Standort beim Öffnen abrufen
    _getCurrentLocation();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            _dialogStateSetter = setDialogState;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: HexColor.fromHex(getColor('primary')),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wc_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'WC-Finder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.my_location_rounded, color: Colors.white),
                            onPressed: () => _getCurrentLocation(),
                            tooltip: 'Standort aktualisieren',
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Column(
                        children: [
                          // Google Maps Karte
                          Container(
                            height: 250,
                            margin: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _currentLocation == null
                                  ? Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_isLoadingLocation) ...[
                                              CircularProgressIndicator(
                                                color: HexColor.fromHex(getColor('primary')),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Standort wird ermittelt...',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ] else ...[
                                              Icon(
                                                Icons.location_off_rounded,
                                                size: 48,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Standort nicht verfügbar',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Verwende Fallback-Standort (Berlin)',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              ElevatedButton.icon(
                                                onPressed: () => _getCurrentLocation(),
                                                icon: Icon(Icons.refresh_rounded, size: 16),
                                                label: Text('Erneut versuchen'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: HexColor.fromHex(getColor('primary')),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )
                                  : GoogleMap(
                                      onMapCreated: (GoogleMapController controller) {
                                        _mapController = controller;
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: _currentLocation!,
                                        zoom: 14.0,
                                      ),
                                      markers: _wcMarkers,
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: true,
                                      zoomControlsEnabled: true,
                                      mapType: MapType.normal,
                                    ),
                            ),
                          ),
                          // Radius-Slider
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Suchradius-Slider
                                Row(
                                  children: [
                                    Icon(Icons.tune_rounded, color: Colors.grey[600], size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Suchradius: ${(_searchRadius / 1000).toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: HexColor.fromHex(getColor('primary')),
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbColor: HexColor.fromHex(getColor('primary')),
                                    overlayColor: HexColor.fromHex(getColor('primary')).withOpacity(0.2),
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _searchRadius,
                                    min: 500.0,
                                    max: 5000.0,
                                    divisions: 9,
                                    onChanged: (double value) {
                                      setDialogState(() {
                                        _searchRadius = value;
                                      });
                                    },
                                    onChangeEnd: (double value) {
                                      if (_currentLocation != null) {
                                        _searchNearbyWCs(_currentLocation!);
                                      }
                                    },
                                  ),
                                ),
                                // Standort-Button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _centerOnLocation(),
                                    icon: Icon(Icons.my_location_rounded, size: 16),
                                    label: Text('Zum Standort'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HexColor.fromHex(getColor('primary')),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                           // WC-Ergebnis Bereich
                           Flexible(
                             child: Container(
                               padding: EdgeInsets.all(16),
                               child: _isSearchingWCs
                                 ? Container(
                                     padding: EdgeInsets.all(16),
                                     decoration: BoxDecoration(
                                       color: Colors.blue[50],
                                       borderRadius: BorderRadius.circular(12),
                                       border: Border.all(color: Colors.blue[200]!),
                                     ),
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         SizedBox(
                                           height: 24,
                                           width: 24,
                                           child: CircularProgressIndicator(
                                             color: HexColor.fromHex(getColor('primary')),
                                             strokeWidth: 2.5,
                                           ),
                                         ),
                                         SizedBox(height: 8),
                                         Text(
                                           'Suche WCs...',
                                           style: TextStyle(
                                             fontSize: 14,
                                             fontWeight: FontWeight.w500,
                                             color: Colors.blue[800],
                                           ),
                                           textAlign: TextAlign.center,
                                         ),
                                         SizedBox(height: 4),
                                         Text(
                                           'Radius: ${(_searchRadius / 1000).toStringAsFixed(1)} km',
                                           style: TextStyle(
                                             fontSize: 12,
                                             color: Colors.blue[600],
                                           ),
                                           textAlign: TextAlign.center,
                                         ),
                                       ],
                                     ),
                                   )
                                 : _currentWCs.isEmpty
                                     ? Container(
                                         padding: EdgeInsets.all(16),
                                         decoration: BoxDecoration(
                                           color: Colors.grey[100],
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(color: Colors.grey[300]!),
                                         ),
                                         child: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Icon(
                                               Icons.search_off_rounded,
                                               size: 32,
                                               color: Colors.grey[400],
                                             ),
                                             SizedBox(height: 8),
                                             Text(
                                               'Keine WCs gefunden',
                                               style: TextStyle(
                                                 fontSize: 14,
                                                 fontWeight: FontWeight.w500,
                                                 color: Colors.grey[600],
                                               ),
                                               textAlign: TextAlign.center,
                                             ),
                                             SizedBox(height: 4),
                                             Text(
                                               'Versuche einen größeren Suchradius',
                                               style: TextStyle(
                                                 fontSize: 12,
                                                 color: Colors.grey[500],
                                               ),
                                               textAlign: TextAlign.center,
                                             ),
                                           ],
                                         ),
                                       )
                                 : Container(
                                     padding: EdgeInsets.all(16),
                                     decoration: BoxDecoration(
                                       color: Colors.green[50],
                                       borderRadius: BorderRadius.circular(12),
                                       border: Border.all(color: Colors.green[200]!),
                                     ),
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         Row(
                                           children: [
                                             Icon(
                                               Icons.wc_rounded,
                                               color: Colors.green[600],
                                               size: 24,
                                             ),
                                             SizedBox(width: 12),
                                             Expanded(
                                               child: Text(
                                                 '${_currentWCs.length} WC${_currentWCs.length == 1 ? '' : 's'} gefunden',
                                                 style: TextStyle(
                                                   fontSize: 16,
                                                   fontWeight: FontWeight.w600,
                                                   color: Colors.green[800],
                                                 ),
                                               ),
                                             ),
                                             TextButton(
                                               onPressed: () => _showWCListPopup(context),
                                               style: TextButton.styleFrom(
                                                 foregroundColor: Colors.green[700],
                                                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                               ),
                                               child: Text(
                                                 'Anzeigen',
                                                 style: TextStyle(
                                                   fontWeight: FontWeight.w600,
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                         if (_currentWCs.isNotEmpty) ...[
                                           SizedBox(height: 8),
                                           Text(
                                             'Nächstes: ${_currentWCs.first['address']} (${_currentWCs.first['distance']})',
                                             style: TextStyle(
                                               fontSize: 14,
                                               color: Colors.green[600],
                                             ),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ],
                                       ],
                                     ),
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
          },
        );
      },
    );
  }

  static Widget _buildWCCard(Map<String, dynamic> wc, {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wc_rounded,
                  color: HexColor.fromHex(getColor('primary')),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wc['address'] ?? 'Unbekannte Adresse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    wc['distance'] ?? '0 km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: HexColor.fromHex(getColor('primary')),
                    ),
                  ),
                ),
              ],
            ),
            if (wc['features'] != null && (wc['features'] as List).isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (wc['features'] as List<String>).map((feature) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 8),
            Text(
              'Kosten: ${wc['price'] ?? 'Unbekannt'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  static void _showWCListPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Gefundene WCs (${_currentWCs.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // WC Liste
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _currentWCs.length,
                    itemBuilder: (context, index) {
                      final wc = _currentWCs[index];
                      return _buildWCCard(wc, onTap: () {
                        _navigateToWC(wc);
                        Navigator.pop(context); // Popup schließen nach Navigation
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _navigateToWC(Map<String, dynamic> wc) {
    if (_mapController != null) {
      final lat = wc['latitude'] as double;
      final lon = wc['longitude'] as double;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lon),
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  static Future<void> _getCurrentLocation() async {
    _isLoadingLocation = true;
    if (_dialogStateSetter != null) {
      _dialogStateSetter!(() {});
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
      
      if (_dialogStateSetter != null) {
        _dialogStateSetter!(() {});
      }

      _searchNearbyWCs(_currentLocation!);

      print('Standort gefunden: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Fehler beim Abrufen des Standorts: $e');
      _useFallbackLocation();
    }
  }

  static void _useFallbackLocation() {
    _currentLocation = LatLng(52.5200, 13.4050); // Berlin
    _isLoadingLocation = false;
    
    if (_dialogStateSetter != null) {
      _dialogStateSetter!(() {});
    }
    
    _searchNearbyWCs(_currentLocation!);
    print('Fallback-Standort verwendet: Berlin (52.5200, 13.4050)');
  }

  static void _centerOnLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation!,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  static Future<void> _searchNearbyWCs(LatLng location) async {
    _isSearchingWCs = true;
    _wcMarkers.clear();
    _currentWCs.clear();
    
    // Standort-Marker (blau) sofort hinzufügen
    if (_currentLocation != null) {
      _wcMarkers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(
            title: 'Mein Standort',
            snippet: 'Aktuelle Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // UI sofort aktualisieren (Loading-State anzeigen)
    if (_dialogStateSetter != null) {
      _dialogStateSetter!(() {});
    }

    try {
      final wcs = await _fetchNearbyWCs(location.latitude, location.longitude, _searchRadius);
      _isSearchingWCs = false;
      _updateWCMarkers(wcs);
    } catch (e) {
      print('Fehler beim Suchen der WCs: $e');
      _isSearchingWCs = false;
      // Auch bei Fehlern UI aktualisieren
      if (_dialogStateSetter != null) {
        _dialogStateSetter!(() {});
      }
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchNearbyWCs(double lat, double lon, double radius) async {
    final String overpassUrl = 'https://overpass-api.de/api/interpreter';
    
    final String query = '''
    [out:json][timeout:25];
    (
      node["amenity"="toilets"](around:$radius,$lat,$lon);
    );
    out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=' + Uri.encodeComponent(query),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> wcs = [];

        for (var element in data['elements']) {
          if (element['lat'] != null && element['lon'] != null) {
            final wcLat = element['lat'].toDouble();
            final wcLon = element['lon'].toDouble();
            
            final distance = Geolocator.distanceBetween(lat, lon, wcLat, wcLon);
            final distanceKm = (distance / 1000).toStringAsFixed(1);

            final tags = element['tags'] ?? {};
            
             // Adresse über Reverse Geocoding abrufen
             String address = await _getAddressFromCoordinates(wcLat, wcLon);
             if (address.isEmpty) {
               address = _buildAddress(tags); // Fallback zu OSM-Tags
             }
             
             wcs.add({
               'id': element['id'],
               'address': address,
               'distance': '$distanceKm km',
               'price': tags['fee'] == 'yes' ? 'Gebühr' : 'Kostenlos',
               'openingHours': tags['opening_hours'] ?? 'Unbekannt',
               'latitude': wcLat,
               'longitude': wcLon,
               'features': _buildFeatures(tags),
             });
          }
        }

        wcs.sort((a, b) {
          double distA = double.parse(a['distance'].toString().replaceAll(' km', ''));
          double distB = double.parse(b['distance'].toString().replaceAll(' km', ''));
          return distA.compareTo(distB);
        });

        return wcs.take(10).toList();
      }
    } catch (e) {
      print('Fehler bei der WC-Suche: $e');
    }

    return [];
  }

  static Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    // Cache-Key erstellen (auf 3 Dezimalstellen gerundet für bessere Cache-Hits)
    String cacheKey = '${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';
    
    // Cache prüfen
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }
    
    try {
      // Rate Limiting: 300ms Pause zwischen Anfragen
      await Future.delayed(Duration(milliseconds: 300));
      
      // Nominatim Reverse Geocoding API verwenden
      final String nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';
      final response = await http.get(
        Uri.parse('$nominatimUrl?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'),
        headers: {
          'User-Agent': 'BusDeskPro/1.0 (WC-Finder)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['address'] != null) {
          final address = data['address'];
          List<String> addressParts = [];
          
          // Straße und Hausnummer
          if (address['road'] != null) {
            String street = address['road'];
            if (address['house_number'] != null) {
              street += ' ${address['house_number']}';
            }
            addressParts.add(street);
          }
          
          // Stadt oder Stadtteil
          if (address['city'] != null) {
            addressParts.add(address['city']);
          } else if (address['town'] != null) {
            addressParts.add(address['town']);
          } else if (address['village'] != null) {
            addressParts.add(address['village']);
          } else if (address['suburb'] != null) {
            addressParts.add(address['suburb']);
          }
          
          if (addressParts.isNotEmpty) {
            String address = addressParts.join(', ');
            _addressCache[cacheKey] = address; // Cache speichern
            return address;
          }
        }
        
        // Fallback: display_name verwenden
        if (data['display_name'] != null) {
          String displayName = data['display_name'];
          List<String> parts = displayName.split(', ');
          String address;
          if (parts.length >= 2) {
            address = '${parts[0]}, ${parts[1]}';
          } else {
            address = parts.first;
          }
          _addressCache[cacheKey] = address; // Cache speichern
          return address;
        }
      }
    } catch (e) {
      print('Fehler beim Reverse Geocoding: $e');
    }
    
    return ''; // Leerer String bei Fehler
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];
    
    if (tags['addr:street'] != null && tags['addr:street'].toString().trim().isNotEmpty) {
      String street = tags['addr:street'].toString().trim();
      if (tags['addr:housenumber'] != null && tags['addr:housenumber'].toString().trim().isNotEmpty) {
        street += ' ' + tags['addr:housenumber'].toString().trim();
      }
      addressParts.add(street);
    }
    
    if (tags['addr:city'] != null && tags['addr:city'].toString().trim().isNotEmpty) {
      addressParts.add(tags['addr:city'].toString().trim());
    } else if (tags['addr:postcode'] != null && tags['addr:postcode'].toString().trim().isNotEmpty) {
      addressParts.add(tags['addr:postcode'].toString().trim());
    }
    
    if (addressParts.isEmpty) {
      if (tags['name'] != null && tags['name'].toString().trim().isNotEmpty && tags['name'] != 'Öffentliches WC') {
        addressParts.add(tags['name'].toString().trim());
      } else if (tags['operator'] != null && tags['operator'].toString().trim().isNotEmpty) {
        addressParts.add(tags['operator'].toString().trim());
      } else if (tags['brand'] != null && tags['brand'].toString().trim().isNotEmpty) {
        addressParts.add(tags['brand'].toString().trim());
      } else if (tags['ref'] != null && tags['ref'].toString().trim().isNotEmpty) {
        addressParts.add(tags['ref'].toString().trim());
      } else if (tags['note'] != null && tags['note'].toString().trim().isNotEmpty) {
        addressParts.add(tags['note'].toString().trim());
      } else {
        addressParts.add('Öffentliches WC');
      }
    }
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Adresse unbekannt';
  }

  static List<String> _buildFeatures(Map<String, dynamic> tags) {
    List<String> features = [];
    
    if (tags['wheelchair'] == 'yes') features.add('Rollstuhlgerecht');
    if (tags['changing_table'] == 'yes') features.add('Wickeltisch');
    if (tags['fee'] == 'yes') {
      features.add('Kostenpflichtig');
    } else {
      features.add('Kostenlos');
    }
    if (tags['access'] == 'public') features.add('Öffentlich');
    if (tags['toilets:disposal'] == 'flush') features.add('Spülung');
    
    return features;
  }

  static void _updateWCMarkers(List<Map<String, dynamic>> wcs) {
    // Standort-Marker behalten, nur WC-Marker löschen
    _wcMarkers.removeWhere((marker) => marker.markerId.value.startsWith('wc_'));
    _currentWCs = List.from(wcs);
    
    // Standort-Marker hinzufügen falls nicht vorhanden
    bool hasLocationMarker = _wcMarkers.any((marker) => marker.markerId.value == 'current_location');
    if (_currentLocation != null && !hasLocationMarker) {
      _wcMarkers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(
            title: 'Mein Standort',
            snippet: 'Aktuelle Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // WC-Marker (rot) hinzufügen
    for (var wc in wcs) {
      _wcMarkers.add(
        Marker(
          markerId: MarkerId('wc_${wc['id']}'),
          position: LatLng(wc['latitude'], wc['longitude']),
          infoWindow: InfoWindow(
            title: wc['address'],
            snippet: '${wc['distance']} • ${wc['price']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    
    // Auto-Zoom: Karte so zoomen, dass Standort und nächstes WC sichtbar sind
    if (_mapController != null && _currentLocation != null && wcs.isNotEmpty) {
      _autoZoomToFitMarkers(wcs);
    }
    
    // Dialog aktualisieren
    if (_dialogStateSetter != null) {
      _dialogStateSetter!(() {});
    }
  }
  
  static void _autoZoomToFitMarkers(List<Map<String, dynamic>> wcs) {
    if (_mapController == null || _currentLocation == null || wcs.isEmpty) return;
    
    // Nächstes WC finden
    final nearestWC = wcs.first;
    final wcLocation = LatLng(nearestWC['latitude'], nearestWC['longitude']);
    
    // Bounds berechnen
    double minLat = _currentLocation!.latitude < wcLocation.latitude 
        ? _currentLocation!.latitude : wcLocation.latitude;
    double maxLat = _currentLocation!.latitude > wcLocation.latitude 
        ? _currentLocation!.latitude : wcLocation.latitude;
    double minLng = _currentLocation!.longitude < wcLocation.longitude 
        ? _currentLocation!.longitude : wcLocation.longitude;
    double maxLng = _currentLocation!.longitude > wcLocation.longitude 
        ? _currentLocation!.longitude : wcLocation.longitude;
    
    // Padding hinzufügen
    double padding = 0.001;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    // Kamera zu den Bounds bewegen
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // Padding
      ),
    );
  }
}

import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum KnowledgeStatus {
  valid,
  expiringSoon,
  expired,
  noExpiry,
  unknown,
}

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuickLinksView(),
    );
  }
}

class QuickLinksView extends StatefulWidget {
  @override
  _QuickLinksViewState createState() => _QuickLinksViewState();
}

class _QuickLinksViewState extends State<QuickLinksView> with WidgetsBindingObserver {
  List<Knowledge> knowledgeList = [];
  List<ClothingOrder> clothingOrderList = [];
  String? savedFirstName;
  String? savedLastName;
  bool _isLoading = false;
  DateTime? _lastLoadTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedName();
    // Lade Daten beim ersten Öffnen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Lade Daten neu, wenn die App wieder aktiv wird
    if (state == AppLifecycleState.resumed) {
      _loadAllData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lade Daten jedes Mal, wenn die Seite sichtbar wird (mit Debounce)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      final now = DateTime.now();
      // Lade nur, wenn die letzte Ladung mehr als 1 Sekunde her ist (verhindert zu häufiges Laden)
      if (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isLoading) {
            _loadAllData();
          }
        });
      }
    }
  }

  // Lädt alle Daten (Kenntnisse und Kleiderbestellungen)
  Future<void> _loadAllData() async {
    if (_isLoading) return; // Verhindert mehrfaches gleichzeitiges Laden
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        fetchKnowledge(),
        fetchClothingOrders(),
      ]);
      _lastLoadTime = DateTime.now();
    } catch (e) {
      print('Fehler beim Laden der Daten: $e');
      // Optional: SnackBar für Fehler anzeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Daten'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedFirstName = prefs.getString('driver_first_name');
      savedLastName = prefs.getString('driver_last_name');
    });
  }

  Future<void> _saveName(String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_first_name', firstName);
    await prefs.setString('driver_last_name', lastName);
    setState(() {
      savedFirstName = firstName;
      savedLastName = lastName;
    });
  }

  void _showNameInputDialog() {
    final firstNameController = TextEditingController(text: savedFirstName ?? '');
    final lastNameController = TextEditingController(text: savedLastName ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: HexColor.fromHex(getColor('primary')),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fahrername eingeben',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Input Fields
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Vorname',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HexColor.fromHex(getColor('primary')), width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: HexColor.fromHex(getColor('primary'))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Nachname',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HexColor.fromHex(getColor('primary')), width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: HexColor.fromHex(getColor('primary'))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (firstNameController.text.trim().isNotEmpty && 
                              lastNameController.text.trim().isNotEmpty) {
                            _saveName(
                              firstNameController.text.trim(),
                              lastNameController.text.trim(),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bitte geben Sie Vor- und Nachname ein'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor.fromHex(getColor('primary')),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchKnowledge() async {
    try {
      print(getUrl('get-knowledge'));
      final response = await http.get(Uri.parse((getUrl('get-knowledge')).replaceAll('{fullname}', PhoneNumberAuth)));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            knowledgeList = data.map((json) => Knowledge.fromJson(json)).toList();
          });
        }
      } else {
        throw Exception('Failed to load knowledge: ${response.statusCode}');
      }
    } catch (e) {
      print('Fehler beim Laden der Kenntnisse: $e');
      rethrow;
    }
  }

  Future<void> fetchClothingOrders() async {
    try {
      final response = await http.get(Uri.parse(getUrl('get-orders').replaceAll('{fullname}', PhoneNumberAuth)));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(data);
        if (mounted) {
          setState(() {
            clothingOrderList = data.map((json) => ClothingOrder.fromJson(json)).toList();
          });
        }
      } else {
        throw Exception('Failed to load clothing orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Fehler beim Laden der Kleiderbestellungen: $e');
      rethrow;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'nicht angegeben';
    }
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  // Prüft den Status einer Kleiderbestellung
  Map<String, dynamic> getClothingStatus(ClothingOrder order) {
    final status = order.status?.toLowerCase() ?? '';
    
    switch (status) {
      case 'ausgegeben':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle_rounded,
          'text': 'Ausgegeben',
          'backgroundColor': Colors.green.shade50,
        };
      case 'bestellt':
        return {
          'color': Colors.blue,
          'icon': Icons.shopping_cart_rounded,
          'text': 'Bestellt',
          'backgroundColor': Colors.blue.shade50,
        };
      case 'offen':
        return {
          'color': Colors.orange,
          'icon': Icons.pending_rounded,
          'text': 'Offen',
          'backgroundColor': Colors.orange.shade50,
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline_rounded,
          'text': order.status ?? 'Unbekannt',
          'backgroundColor': Colors.grey.shade50,
        };
    }
  }

  // Prüft den Status einer Kenntnis
  KnowledgeStatus getKnowledgeStatus(Knowledge knowledge) {
    if (knowledge.validityTo == null) {
      return KnowledgeStatus.noExpiry; // Kein Ablaufdatum
    }

    try {
      final expiryDate = DateTime.parse(knowledge.validityTo!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
      final daysUntilExpiry = expiry.difference(today).inDays;

      if (daysUntilExpiry < 0) {
        return KnowledgeStatus.expired; // Abgelaufen
      } else if (daysUntilExpiry <= 30) {
        return KnowledgeStatus.expiringSoon; // Läuft bald ab (innerhalb von 30 Tagen)
      } else {
        return KnowledgeStatus.valid; // Gültig
      }
    } catch (e) {
      return KnowledgeStatus.unknown; // Fehler beim Parsen
    }
  }

  Widget _buildClothingCard(ClothingOrder order) {
    final statusInfo = getClothingStatus(order);
    final statusColor = statusInfo['color'] as Color;
    final statusIcon = statusInfo['icon'] as IconData;
    final statusText = statusInfo['text'] as String;
    final backgroundColor = statusInfo['backgroundColor'] as Color;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status-Badge oben
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Name der Kleidung darunter
            Text(
              order.clothes ?? 'nicht angegeben',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeCard(Knowledge knowledge, KnowledgeStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color backgroundColor;

    switch (status) {
      case KnowledgeStatus.expired:
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        statusText = 'Abgelaufen';
        backgroundColor = Colors.red.shade50;
        break;
      case KnowledgeStatus.expiringSoon:
        statusColor = Colors.orange;
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Läuft bald ab';
        backgroundColor = Colors.orange.shade50;
        break;
      case KnowledgeStatus.valid:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Gültig';
        backgroundColor = Colors.green.shade50;
        break;
      case KnowledgeStatus.noExpiry:
        statusColor = Colors.blue;
        statusIcon = Icons.info_rounded;
        statusText = 'Kein Ablaufdatum';
        backgroundColor = Colors.blue.shade50;
        break;
      case KnowledgeStatus.unknown:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusText = 'Unbekannt';
        backgroundColor = Colors.grey.shade50;
        break;
    }

    // Berechne Tage bis Ablauf
    String daysUntilExpiry = '';
    if (knowledge.validityTo != null) {
      try {
        final expiryDate = DateTime.parse(knowledge.validityTo!);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        final days = expiry.difference(today).inDays;
        
        if (days < 0) {
          daysUntilExpiry = 'vor ${days.abs()} Tagen abgelaufen';
        } else if (days == 0) {
          daysUntilExpiry = 'läuft heute ab';
        } else if (days == 1) {
          daysUntilExpiry = 'läuft morgen ab';
        } else {
          daysUntilExpiry = 'noch $days Tage gültig';
        }
      } catch (e) {
        // Fehler beim Parsen
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status-Badge oben
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Name der Zertifizierung darunter
            Text(
              knowledge.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            SizedBox(height: 12),
            // Gültigkeitsdaten
            if (knowledge.validityFrom != null || knowledge.validityTo != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (knowledge.validityFrom != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 6),
                          Text(
                            'Von: ${formatDate(knowledge.validityFrom)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (knowledge.validityTo != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == KnowledgeStatus.expired || status == KnowledgeStatus.expiringSoon
                                  ? Icons.warning_rounded
                                  : Icons.event_rounded,
                              size: 14,
                              color: status == KnowledgeStatus.expired || status == KnowledgeStatus.expiringSoon
                                  ? statusColor
                                  : Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Bis: ${formatDate(knowledge.validityTo)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: status == KnowledgeStatus.expired || status == KnowledgeStatus.expiringSoon
                                      ? statusColor
                                      : Colors.grey[700],
                                  fontWeight: status == KnowledgeStatus.expired || status == KnowledgeStatus.expiringSoon
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (daysUntilExpiry.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 20, top: 4),
                            child: Text(
                              daysUntilExpiry,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              )
            else
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 6),
                    Text(
                      'Keine Gültigkeitsdaten verfügbar',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
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

  String _getDriverName() {
    // Zuerst prüfen ob ein Fahrername aus den Touren vorhanden ist
    if (AllToursGbl.length > 0 && 
        AllToursGbl[0]['general']['driver'] != null && 
        AllToursGbl[0]['general']['driver'].toString().isNotEmpty) {
      return AllToursGbl[0]['general']['driver'];
    }
    
    // Falls kein Fahrername aus Touren, dann gespeicherten Namen verwenden
    if (savedFirstName != null && savedLastName != null) {
      return '$savedFirstName $savedLastName';
    }
    
    // Falls nichts vorhanden, Hinweis anzeigen
    return 'Kein Fahrername hinterlegt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Weißer Hintergrund
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        automaticallyImplyLeading: false,
        elevation: 0,
        /*leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),*/
        title: Row(
          children: [
            Icon(Icons.person_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _isLoading ? null : _loadAllData,
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: HexColor.fromHex(getColor('primary')),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(), // Ermöglicht Pull-to-Refresh auch wenn Content klein ist
            child: Card(
            color: Colors.white, // Weiße Card-Farbe
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Text(
                          'Fahrer:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Spacer(),
                        if (AllToursGbl.length == 0 || AllToursGbl[0]['general']['driver'] == null || AllToursGbl[0]['general']['driver'].toString().isEmpty)
                          IconButton(
                            onPressed: _showNameInputDialog,
                            icon: Icon(Icons.edit_rounded, color: HexColor.fromHex(getColor('primary'))),
                            tooltip: 'Fahrername eingeben',
                          ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(14.0),
                    child: Text(
                      _getDriverName(),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(
                      'Rufnummer:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(PhoneNumberAuth, style: TextStyle(fontSize: 16)),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  if (checkIfAnyModuleIsActive('Knowledge') == true)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        unselectedWidgetColor: Colors.black,
                        colorScheme: ColorScheme.light(
                          primary: Colors.black,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Icon(Icons.school_rounded, size: 20, color: HexColor.fromHex(getColor('primary'))),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kenntnisse & Zertifizierungen',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (knowledgeList.any((k) => getKnowledgeStatus(k) == KnowledgeStatus.expired || getKnowledgeStatus(k) == KnowledgeStatus.expiringSoon))
                              Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '!',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        children: knowledgeList.isEmpty
                            ? [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Keine Kenntnisse vorhanden',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ]
                            : knowledgeList.map((knowledge) {
                                final status = getKnowledgeStatus(knowledge);
                                return _buildKnowledgeCard(knowledge, status);
                              }).toList(),
                      ),
                    ),
                  SizedBox(height: 16),
                  if (checkIfAnyModuleIsActive('ClothOrders') == true)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        unselectedWidgetColor: Colors.black,
                        colorScheme: ColorScheme.light(
                          primary: Colors.black,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Icon(Icons.checkroom_rounded, size: 20, color: HexColor.fromHex(getColor('primary'))),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kleiderbestellungen',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        children: clothingOrderList.isEmpty
                            ? [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Keine Kleiderbestellungen vorhanden',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ]
                            : clothingOrderList.map((order) {
                                return _buildClothingCard(order);
                              }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class Knowledge {
  final String value; // UUID
  final String name;
  final String? validityFrom;
  final String? validityTo;

  Knowledge({
    required this.value,
    required this.name,
    this.validityFrom,
    this.validityTo,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      value: json['value'] ?? '',
      name: json['knowledge'] ?? 'nicht angegeben',
      validityFrom: json['valid_from'],
      validityTo: json['valid_to'],
    );
  }
}

class ClothingOrder {
  final String value; // UUID
  final String? clothes;
  final String? status;

  ClothingOrder({
    required this.value,
    this.clothes,
    this.status,
  });

  factory ClothingOrder.fromJson(Map<String, dynamic> json) {
    return ClothingOrder(
      value: json['value'] ?? '',
      clothes: json['clothes'],
      status: json['status'],
    );
  }
}
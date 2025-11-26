import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/maps/mapEngine.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/checklist_item.dart';
import '../models/damage_report.dart';

// Hauptscreen - Kategorieübersicht
class BeforeDriveView extends StatefulWidget {
  final double? lat;
  final double? long;
  final List? stops;

  const BeforeDriveView({super.key, this.lat, this.long, this.stops});

  @override
  _BeforeDriveViewState createState() => _BeforeDriveViewState();
}

class _BeforeDriveViewState extends State<BeforeDriveView> {
  List<ChecklistItem> checklistItems = [];
  Map<String, CategoryStatus> categoryStatuses = {};
  Map<String, DamageReport> damageReports = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      // Debug: Mandanten-Info ausgeben
      print('=== BeforeDrive Debug ===');
      print('GblTenant: $GblTenant');
      print('GblTenant is null: ${GblTenant == null}');
      
      if (GblTenant == null) {
        throw Exception('Mandant nicht geladen. Bitte erneut einloggen.');
      }
      
      // URL vom Mandanten holen
      String apiUrl = getUrl('get-beforedrivecheck');
      print('API URL: $apiUrl');
      
      if (apiUrl.isEmpty) {
        throw Exception('Keine URL für get-beforedrivecheck konfiguriert. Bitte Mandanten-Konfiguration prüfen.');
      }
      
      print('Fetching checklist from: $apiUrl');
      
      final response = await http.get(Uri.parse(apiUrl));
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Response data keys: ${responseData.keys}');
        
        if (responseData['checklist'] == null) {
          throw Exception('Keine Checkliste in der Response gefunden');
        }
        
        final checklistData = responseData['checklist'] as List;
        print('Checklist items count: ${checklistData.length}');
        
        setState(() {
          checklistItems = checklistData
              .map((item) => ChecklistItem.fromJson(item))
              .toList();
          _initializeCategoryStatuses();
          isLoading = false;
        });
      } else {
        throw Exception('Server-Fehler: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in fetchQuestions: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Checkliste: $e'),
          backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _initializeCategoryStatuses() {
    final rootItems = _getRootItems();
    for (var item in rootItems) {
      final children = _getChildItems(item.id);
      categoryStatuses[item.id] = CategoryStatus(
        categoryId: item.id,
        isOk: null, // Standardmäßig nicht ausgewählt
        hasSubItems: children.isNotEmpty,
        checkedSubItems: [],
        uncheckedSubItems: [],
      );
    }
  }

  List<ChecklistItem> _getRootItems() {
    return checklistItems.where((item) => item.parentId == null).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  List<ChecklistItem> _getChildItems(String parentId) {
    return checklistItems.where((item) => item.parentId == parentId).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  IconData _getIconForCategory(String title) {
    final lowerTitle = title.toLowerCase();
    
    // Fahrerarbeitsplatz - Einzelner Sitz (Fahrersitz)
    if (lowerTitle.contains('fahrerarbeitsplatz') || lowerTitle.contains('arbeitsplatz')) {
      return Icons.airline_seat_recline_normal;
    } 
    // Bereifung - Reifen
    else if (lowerTitle.contains('bereifung') || lowerTitle.contains('reifen')) {
      return Icons.album; // Reifen-Symbol (Kreis)
    } 
    // Motor - Motor/Zahnrad
    else if (lowerTitle.contains('motor')) {
      return Icons.settings_suggest;
    } 
    // Fahrzeugfront - Bus von vorne
    else if (lowerTitle.contains('front')) {
      return Icons.directions_bus;
    } 
    // Linke Fahrzeugseite - Bus
    else if (lowerTitle.contains('linke') && lowerTitle.contains('seite')) {
      return Icons.commute; // Bus Symbol
    } 
    // Fahrzeugheck - Bus Rückseite
    else if (lowerTitle.contains('heck')) {
      return Icons.garage;
    } 
    // Rechte Fahrzeugseite - Bus
    else if (lowerTitle.contains('rechte') && lowerTitle.contains('seite')) {
      return Icons.commute; // Bus Symbol
    } 
    // Fahrerangaben - Person/Fahrer
    else if (lowerTitle.contains('fahrerangaben')) {
      return Icons.badge; // Ausweis/ID
    } 
    // Fahrgastraum - Mehrere Sitze (Passagiere)
    else if (lowerTitle.contains('fahrgastraum') || lowerTitle.contains('gastraum')) {
      return Icons.event_seat; // Sitzreihen/Innenraum
    } 
    // Equipment - Aktentasche/Koffer
    else if (lowerTitle.contains('equipment') || lowerTitle.contains('ausrüstung')) {
      return Icons.work; // Aktentasche
    }
    // Beleuchtung - Lampe
    else if (lowerTitle.contains('beleuchtung') || lowerTitle.contains('licht')) {
      return Icons.lightbulb;
    }
    // Fallback
    else {
      return Icons.check_circle_outline;
    }
  }

  void _navigateToDetail(ChecklistItem category) async {
    // Zur Detailansicht navigieren
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailView(
          category: category,
          childItems: _getChildItems(category.id),
          initialStatus: categoryStatuses[category.id]!,
          existingReport: damageReports[category.id],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        categoryStatuses[category.id] = result['status'];
        if (result['report'] != null) {
          damageReports[category.id] = result['report'];
      } else {
          damageReports.remove(category.id);
        }
      });
    } else {
      // Wenn zurück ohne zu speichern (result == null), Status auf neutral setzen
      // ABER nur wenn keine Unterelemente ausgewählt wurden
      final currentStatus = categoryStatuses[category.id]!;
      if (currentStatus.checkedSubItems.isEmpty && currentStatus.uncheckedSubItems.isEmpty) {
        setState(() {
          final children = _getChildItems(category.id);
          categoryStatuses[category.id] = CategoryStatus(
            categoryId: category.id,
            isOk: null, // Zurück auf neutral
            hasSubItems: children.isNotEmpty,
            checkedSubItems: [],
            uncheckedSubItems: [],
          );
        });
      }
    }
  }

  bool _isFahrerangabenCategory(ChecklistItem category) {
    // Prüft ob es die Fahrerangaben-Kategorie ist (order_index 7 oder Titel enthält "Fahrerangaben")
    return category.title.toLowerCase().contains('fahrerangaben') || 
           category.orderIndex == 7;
  }

  void _handleCategoryOk(ChecklistItem category) {
    setState(() {
      final children = _getChildItems(category.id);
      categoryStatuses[category.id] = CategoryStatus(
        categoryId: category.id,
        isOk: true,
        hasSubItems: children.isNotEmpty,
        checkedSubItems: children.map((c) => c.id).toList(),
        uncheckedSubItems: [],
      );
      // Schadensmeldung entfernen, falls vorhanden
      damageReports.remove(category.id);
    });
  }

  void _handleCategoryNotOk(ChecklistItem category) async {
    // Für alle Kategorien mit Unterelementen: Detailansicht öffnen
    final children = _getChildItems(category.id);
    
    if (children.isEmpty) {
      // Keine Unterelemente - direkt als nicht OK markieren
      setState(() {
        categoryStatuses[category.id] = CategoryStatus(
          categoryId: category.id,
          isOk: false,
          hasSubItems: false,
          checkedSubItems: [],
          uncheckedSubItems: [],
        );
      });
    } else {
      // Hat Unterelemente - zur Detailansicht navigieren
      // Achtung-Meldung wird in der Detailansicht geprüft
      _navigateToDetail(category);
    }
  }

  bool _allCategoriesSelected() {
    return categoryStatuses.values.every((status) => status.isSelected);
  }

  void _navigateToSummary() {
    // Prüfen ob alle Oberpunkte ausgewählt wurden
    if (!_allCategoriesSelected()) {
      final unselectedCategories = _getRootItems()
          .where((cat) => categoryStatuses[cat.id]?.isOk == null)
          .map((cat) => cat.title)
          .toList();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unvollständige Prüfung'),
          content: Text(
            'Bitte geben Sie zu allen Kategorien eine Rückmeldung.\n\nNoch nicht bewertet:\n${unselectedCategories.map((t) => '• $t').join('\n')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryView(
          categories: _getRootItems(),
          allChecklistItems: checklistItems,
          categoryStatuses: categoryStatuses,
          damageReports: damageReports,
          onConfirm: _submitCheckup,
          lat: widget.lat,
          long: widget.long,
        ),
      ),
    );
  }

  Future<void> _submitCheckup() async {
    // Tour-Informationen holen
    String? driverName;
    String? tourName = TourNameGbl.isNotEmpty ? TourNameGbl : null;
    
    if (CurrentTourData != null && CurrentTourData['general'] != null) {
      driverName = CurrentTourData['general']['driver'];
      tourName = CurrentTourData['tour'];
    }
    
    // Alle Kategorien mit Mängeln sammeln (auch ohne explizite Dokumentation)
    List<Map<String, dynamic>> allDamageReports = [];
    
    for (var category in _getRootItems()) {
      final status = categoryStatuses[category.id]!;
      
      if (status.hasIssues) {
        // Prüfen ob es eine explizite Dokumentation gibt
        if (damageReports.containsKey(category.id)) {
          // Mit Dokumentation
          allDamageReports.add(damageReports[category.id]!.toJson());
        } else {
          // Ohne Dokumentation - aber trotzdem Mängel
          final childItems = _getChildItems(category.id);
          final uncheckedChildren = childItems
              .where((child) => status.uncheckedSubItems.contains(child.id))
              .toList();
          
          // DamageReport ohne Kommentar/Fotos erstellen
          final autoDamageReport = DamageReport(
            categoryId: category.id,
            categoryTitle: category.title,
            selectedDamages: uncheckedChildren.map((c) => c.title).toList(),
            comment: null,
            photoUrls: [],
            createdAt: DateTime.now(),
          );
          
          allDamageReports.add(autoDamageReport.toJson());
        }
      }
    }
    
    // JSON für Backend generieren (vollständig für Logs)
    Map<String, dynamic> fullResult = {
      'timestamp': DateTime.now().toIso8601String(),
      'driver_name': driverName,
      'tour': tourName,
      'categories': categoryStatuses.values.map((s) => s.toJson()).toList(),
      'damage_reports': allDamageReports,
      'has_issues': categoryStatuses.values.any((s) => s.hasIssues),
    };

    String fullJsonString = json.encode(fullResult);
    
    // An send-repair API schicken (wenn Schadensmeldungen vorhanden)
    if (allDamageReports.isNotEmpty) {
      try {
        String repairApiUrl = getUrl('send-repair');
        
        // Payload für Repair-API vorbereiten
        Map<String, dynamic> repairPayload = {
          'timestamp': DateTime.now().toIso8601String(),
          'driver_name': driverName,
          'tour': tourName,
          'damage_reports': allDamageReports,
        };
        
        String repairJsonString = json.encode(repairPayload);
        
        if (repairApiUrl.isNotEmpty) {
          print('Sending repair report to: $repairApiUrl');
          print('Repair payload: $repairJsonString');
          
          final response = await http.post(
            Uri.parse(repairApiUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: repairJsonString,
          );
          
          print('Repair report response status: ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            print('Repair report sent successfully');
          } else {
            print('Failed to send repair report: ${response.statusCode}');
          }
        } else {
          print('Warning: send-repair URL not configured');
          print('Repair payload (would have been sent): $repairJsonString');
        }
      } catch (e) {
        print('Error sending repair report: $e');
        // Fehler wird geloggt, aber Prozess wird nicht unterbrochen
      }
    } else {
      print('No damage reports to send');
    }
    
    // Logging für interne Zwecke (vollständige Daten)
    sendLogs('beforedrive_check', fullJsonString);
    
     Navigator.pushReplacement(
       context,
       MaterialPageRoute(
         builder: (context) => InitNavigationMap(
           lat: widget.lat,
           long: widget.long,
           isFreeDrive: false,
         ),
       ),
    );
    
    // Temporär: Zurück zur vorherigen Seite
    // Navigator.pop(context);
  }

  bool get _allCategoriesChecked {
    return categoryStatuses.values.every((status) => 
      status.isOk == true && status.uncheckedSubItems.isEmpty
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Prüfung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Checkliste wird geladen...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : Column(
      children: [
                // Fortschrittsanzeige
        Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                      width: 2.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fortschritt',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: HexColor.fromHex(getColor('primary')),
                            ),
                          ),
                          Text(
                            '${categoryStatuses.values.where((s) => s.isSelected).length} / ${_getRootItems().length}',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: HexColor.fromHex(getColor('primary')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: LinearProgressIndicator(
                          value: _getRootItems().isEmpty 
                              ? 0.0 
                              : categoryStatuses.values.where((s) => s.isSelected).length / _getRootItems().length,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            HexColor.fromHex(getColor('primary')),
                          ),
                          minHeight: 12.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _allCategoriesSelected() 
                            ? '✓ Alle Kategorien bewertet' 
                            : 'Bitte bewerten Sie alle Kategorien',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: _allCategoriesSelected() 
                              ? Colors.green.shade700 
                              : Colors.grey.shade700,
                          fontWeight: _allCategoriesSelected() 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _getRootItems().length,
                    itemBuilder: (context, index) {
                      final category = _getRootItems()[index];
                      final status = categoryStatuses[category.id]!;
                      final hasReport = damageReports.containsKey(category.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                          color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                            color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          leading: Icon(
                            _getIconForCategory(category.title),
                            color: Colors.grey.shade600,
                            size: 28.0,
                          ),
                          title: Row(
                  children: [
                              Expanded(
                                child: Text(
                                  category.title,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Badge mit Anzahl negativer Unterpunkte
                              if (status.uncheckedSubItems.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 8.0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    '${status.uncheckedSubItems.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasReport)
                                Container(
                                  margin: const EdgeInsets.only(right: 8.0),
                                  child: Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                    size: 24.0,
                                  ),
                                ),
                              // Alle Kategorien haben die beiden Buttons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Problem/Mangel Button (Daumen runter)
                    GestureDetector(
                                    onTap: () => _handleCategoryNotOk(category),
                      child: Container(
                                      padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                                        color: status.isOk == false
                                            ? Colors.red 
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6.0),
                                        border: status.isOk == null
                                            ? Border.all(color: Colors.grey.shade400, width: 2.0)
                                            : null,
                                      ),
                                      child: Icon(
                                        Icons.thumb_down,
                                        color: status.isOk == false
                                            ? Colors.white 
                                            : Colors.grey.shade600,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  // Alles OK Button (Daumen hoch)
                                  GestureDetector(
                                    onTap: () => _handleCategoryOk(category),
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: status.isOk == true
                                            ? Colors.green 
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6.0),
                                        border: status.isOk == null
                                            ? Border.all(color: Colors.grey.shade400, width: 2.0)
                            : null,
                      ),
                                      child: Icon(
                                        Icons.thumb_up,
                                        color: status.isOk == true
                                            ? Colors.white 
                                            : Colors.grey.shade600,
                                        size: 24.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: status.hasSubItems 
                              ? () => _navigateToDetail(category)
                              : null,
                      ),
                      );
                    },
                  ),
                ),
                // Bottom Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4.0,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _navigateToSummary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor.fromHex(getColor('primary')),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 2.0,
                    ),
                    child: const Text(
                      'Weiter zur Zusammenfassung',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Detail-Screen für Kategorie mit Unterelementen
class CategoryDetailView extends StatefulWidget {
  final ChecklistItem category;
  final List<ChecklistItem> childItems;
  final CategoryStatus initialStatus;
  final DamageReport? existingReport;

  const CategoryDetailView({
    super.key,
    required this.category,
    required this.childItems,
    required this.initialStatus,
    this.existingReport,
  });

  @override
  _CategoryDetailViewState createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  late Map<String, bool?> itemCheckedState; // null = nicht ausgewählt
  DamageReport? damageReport;

  @override
  void initState() {
    super.initState();
    itemCheckedState = {};
    for (var item in widget.childItems) {
      // Wenn in uncheckedSubItems -> false (Mangel), sonst true (OK)
      if (widget.initialStatus.uncheckedSubItems.contains(item.id)) {
        itemCheckedState[item.id] = false;
      } else {
        itemCheckedState[item.id] = true; // Standardmäßig OK
      }
    }
    damageReport = widget.existingReport;
  }

  bool _isFahrerangabenCategory() {
    return widget.category.title.toLowerCase().contains('fahrerangaben') || 
           widget.category.orderIndex == 7;
  }

  void _handleBackButton() {
    // Prüfen ob irgendwas geändert wurde
    final hasChanges = itemCheckedState.values.any((value) => value != null);
    
    if (!hasChanges) {
      // Keine Änderungen - einfach zurück ohne zu speichern
      Navigator.pop(context);
    } else {
      // Es gibt Änderungen - normal speichern
      _saveAndReturn();
    }
  }

  void _saveAndReturn() async {
    final checkedItems = itemCheckedState.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();
    
    final uncheckedItems = itemCheckedState.entries
        .where((e) => e.value == false)
        .map((e) => e.key)
        .toList();

    final status = CategoryStatus(
      categoryId: widget.category.id,
      isOk: uncheckedItems.isEmpty,
      hasSubItems: true,
      checkedSubItems: checkedItems,
      uncheckedSubItems: uncheckedItems,
    );

    Navigator.pop(context, {
      'status': status,
      'report': damageReport,
    });
  }

  @override
  Widget build(BuildContext context) {
    final allChecked = itemCheckedState.values.every((checked) => checked == true);
    final uncheckedCount = itemCheckedState.values.where((c) => c == false).length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBackButton,
        ),
        title: Text(
          widget.category.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.0,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
                    Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.childItems.length,
              itemBuilder: (context, index) {
                final item = widget.childItems[index];
                final isChecked = itemCheckedState[item.id];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    leading: Icon(
                      Icons.build_circle_outlined,
                      color: Colors.grey.shade600,
                      size: 24.0,
                    ),
                    title: Text(
                        item.title,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () async {
                        // Toggle zwischen OK (true) und Mangel (false)
                        final newValue = isChecked == false ? true : false;
                        
                        // Spezielle Prüfung für Fahrerangaben BEVOR der Status gesetzt wird
                        if (_isFahrerangabenCategory() && newValue == false) {
                          final verklickt = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              title: const Text('Achtung!'),
                              content: const Text(
                                'Haben Sie sich verklickt? Sie sind im Begriff sich fahrtuntüchtig zu melden.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Ja, verklickt'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Nein, ich bin fahrtuntüchtig'),
                                ),
                              ],
                            ),
                          );

                          if (verklickt == true) {
                            // Verklickt - nichts tun
                            return;
                          } else if (verklickt == false) {
                            // Nicht verklickt - zweite Warnung und raus
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                title: const Text('Fahrtuntüchtigkeit'),
                                content: const Text(
                                  'Bitte verlassen Sie das Fahrzeug und wenden Sie sich an Ihre Disposition.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Dialog schließen
                                      Navigator.pop(context); // Detail-Screen schließen
                                      Navigator.pop(context); // Hauptscreen schließen (zurück zur Tourenübersicht)
                                    },
                                    child: const Text('Verstanden'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                        }
                        
                        setState(() {
                          itemCheckedState[item.id] = newValue;
                        });
                        
                        // Wenn auf Mangel gesetzt, Dokumentations-Dialog anzeigen
                        // (ABER NICHT bei Fahrerangaben, da wurde schon geprüft)
                        if (newValue == false && !_isFahrerangabenCategory()) {
                          final wantsToDocument = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Mangel dokumentieren'),
                              content: const Text(
                                'Möchten Sie weitere Informationen zu diesem Mangel erfassen?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Nein'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HexColor.fromHex(getColor('primary')),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Ja'),
                                ),
                              ],
                            ),
                          );

                          // Wenn "Ja", Dokumentations-Modal öffnen
                          if (wantsToDocument == true) {
                            final result = await showModalBottomSheet<DamageReport>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DocumentationModal(
                                category: widget.category,
                                selectedDamages: [item],
                                existingReport: damageReport,
                              ),
                            );

                            if (result != null) {
                              setState(() {
                                damageReport = result;
                              });
                            }
                          }
                        }
                      },
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                          color: isChecked == false
                              ? Colors.red 
                              : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Icon(
                          Icons.thumb_down,
                          color: isChecked == false
                              ? Colors.white 
                              : Colors.grey.shade600,
                            size: 24.0,
                        ),
                      ),
                    ),
                    onTap: null,
                  ),
                );
              },
            ),
          ),
          // Bottom Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, -2),
                      ),
                  ],
                ),
            child: ElevatedButton(
                  onPressed: _saveAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor.fromHex(getColor('primary')),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// Dokumentations-Modal für Kommentare und Fotos
class DocumentationModal extends StatefulWidget {
  final ChecklistItem category;
  final List<ChecklistItem> selectedDamages;
  final DamageReport? existingReport;

  const DocumentationModal({
    super.key,
    required this.category,
    required this.selectedDamages,
    this.existingReport,
  });

  @override
  _DocumentationModalState createState() => _DocumentationModalState();
}

class _DocumentationModalState extends State<DocumentationModal> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String> _photoUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingReport != null) {
      _commentController.text = widget.existingReport!.comment ?? '';
      _photoUrls = List.from(widget.existingReport!.photoUrls);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photoUrls.add(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Aufnehmen des Fotos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
    });
  }

  void _saveAndReturn() {
    final report = DamageReport(
      categoryId: widget.category.id,
      categoryTitle: widget.category.title,
      selectedDamages: widget.selectedDamages.map((d) => d.title).toList(),
      comment: _commentController.text.isEmpty ? null : _commentController.text,
      photoUrls: _photoUrls,
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
    return Column(
      children: [
              // Handle-Bar zum Ziehen
        Container(
                margin: const EdgeInsets.symmetric(vertical: 12.0),
                width: 40.0,
                height: 4.0,
          decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
          ),
          child: Row(
            children: [
                    Expanded(
                      child: Text(
                        'Mangel dokumentieren',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                color: HexColor.fromHex(getColor('primary')),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Kommentar
            const Text(
              'Kommentar',
                  style: TextStyle(
                    fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Beschreiben Sie den Mangel...',
                border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24.0),

            // Fotos
            const Text(
              'Fotos',
                  style: TextStyle(
                    fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            
            // Foto-Grid
            if (_photoUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: _photoUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
              Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(_photoUrls[index]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4.0,
                        right: 4.0,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            
            const SizedBox(height: 12.0),
            
            // Foto hinzufügen Button
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: double.infinity,
                height: 120.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 2.0,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 48.0,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8.0),
              Text(
                      'Foto hinzufügen',
                style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
            ),
            const SizedBox(height: 24.0),

                      // Hinzufügen Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveAndReturn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'Hinzufügen',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Zusammenfassungs-Screen
class SummaryView extends StatefulWidget {
  final List<ChecklistItem> categories;
  final List<ChecklistItem> allChecklistItems;
  final Map<String, CategoryStatus> categoryStatuses;
  final Map<String, DamageReport> damageReports;
  final VoidCallback onConfirm;
  final double? lat;
  final double? long;

  const SummaryView({
    super.key,
    required this.categories,
    required this.allChecklistItems,
    required this.categoryStatuses,
    required this.damageReports,
    required this.onConfirm,
    this.lat,
    this.long,
  });

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  List<ChecklistItem> _getChildItems(String parentId) {
    return widget.allChecklistItems
        .where((item) => item.parentId == parentId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  void _confirmAndProceed() {
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final hasIssues = widget.categoryStatuses.values.any((s) => s.hasIssues);
    final issueCount = widget.categoryStatuses.values
        .where((s) => s.hasIssues)
        .length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Zusammenfassung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Schäden Section
                  if (hasIssues) ...[
                    Container(
                      padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.orange.shade700,
                                size: 24.0,
                              ),
                              const SizedBox(width: 8.0),
                Text(
                                'SCHÄDEN',
                  style: TextStyle(
                                  fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                  ),
                ),
              ],
                          ),
                          const SizedBox(height: 12.0),
                          ...widget.categories.where((cat) {
                            final status = widget.categoryStatuses[cat.id]!;
                            return status.hasIssues;
                          }).map((cat) {
                            final status = widget.categoryStatuses[cat.id]!;
                            final report = widget.damageReports[cat.id];
                            final childItems = _getChildItems(cat.id);
                            
                            // Unterpunkte die auf "Nicht OK" gesetzt wurden
                            final uncheckedChildren = childItems
                                .where((child) => status.uncheckedSubItems.contains(child.id))
                                .toList();
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hauptkategorie
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.thumb_down,
                                        color: Colors.red,
                                        size: 18.0,
                                      ),
                                      const SizedBox(width: 6.0),
                                      Expanded(
                                        child: Text(
                                          cat.title,
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade900,
                                          ),
            ),
          ),
        ],
                                  ),
                                  
                                  // Unterpunkte anzeigen
                                  if (uncheckedChildren.isNotEmpty) ...[
                                    const SizedBox(height: 6.0),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: uncheckedChildren.map((child) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Row(
        children: [
                                                Icon(
                                                  Icons.circle,
                                                  size: 6.0,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: Text(
                                                    child.title,
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                      color: Colors.orange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                  
                                  // Dokumentation (Kommentar)
                                  if (report != null && report.comment != null) ...[
                                    const SizedBox(height: 6.0),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24.0),
                                      child: Text(
                                        '💬 ${report.comment!}',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Alle Kategorien
                  const Text(
                    'Technische Bereitschaft',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  ...widget.categories.map((cat) {
                    final status = widget.categoryStatuses[cat.id]!;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.title,
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            status.isOk == false ? Icons.thumb_down : Icons.thumb_up,
                            color: status.isOk == false ? Colors.red : Colors.green,
                            size: 24.0,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _confirmAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor.fromHex(getColor('primary')),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Speichern',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

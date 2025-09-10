import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/maps/mapEngine.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/checklist_item.dart';

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
  Map<String, ChecklistItem> itemsMap = {};
  Map<String, bool> expandedState = {};
  Map<String, bool> checkedState = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      String jsonString = await rootBundle.loadString('lib/config/apis.json');
      Map<String, dynamic> parsedJson = json.decode(jsonString);
      final response = await http.get(Uri.parse(getUrl('get-checkuplist')));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final checklistData = responseData['checklist'] as List;
        
        setState(() {
          checklistItems = checklistData
              .map((item) => ChecklistItem.fromJson(item))
              .toList();
          _initializeData();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load checklist');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Checkliste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeData() {
    itemsMap = {};
    expandedState = {};
    checkedState = {};

    for (var item in checklistItems) {
      itemsMap[item.id] = item;
      expandedState[item.id] = false; // Standardmäßig eingeklappt
      checkedState[item.id] = true; // Standardmäßig alle angehakt
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

  void _toggleCheckbox(String itemId) {
    setState(() {
      final newValue = !(checkedState[itemId] ?? false);
      checkedState[itemId] = newValue;
      
      // Wenn Parent angehakt wird, alle Children auch anhaken
      if (newValue) {
        _checkAllChildren(itemId);
      } else {
        // Wenn Parent ungecheckt wird, alle Children auch unchecken
        _uncheckAllChildren(itemId);
      }
    });
  }

  void _checkAllChildren(String parentId) {
    final children = _getChildItems(parentId);
    for (var child in children) {
      checkedState[child.id] = true;
      _checkAllChildren(child.id); // Rekursiv für verschachtelte Kinder
    }
  }

  void _uncheckAllChildren(String parentId) {
    final children = _getChildItems(parentId);
    for (var child in children) {
      checkedState[child.id] = false;
      _uncheckAllChildren(child.id); // Rekursiv für verschachtelte Kinder
    }
  }

  void _toggleExpansion(String itemId) {
    setState(() {
      expandedState[itemId] = !(expandedState[itemId] ?? false);
    });
  }

  String generateJsonString() {
    Map<String, dynamic> result = {};
    
    final checkedItems = checklistItems.where((item) => checkedState[item.id] == true).toList();
    final uncheckedItems = checklistItems.where((item) => checkedState[item.id] == false).toList();
    
    result['checked_items'] = checkedItems.map((item) => {
      'id': item.id,
      'title': item.title,
      'level': item.level,
      'parent_id': item.parentId,
    }).toList();
    
    result['unchecked_items'] = uncheckedItems.map((item) => {
      'id': item.id,
      'title': item.title,
      'level': item.level,
      'parent_id': item.parentId,
    }).toList();
    
    result['summary'] = {
      'total_items': checklistItems.length,
      'checked_count': checkedItems.length,
      'unchecked_count': uncheckedItems.length,
      'completion_percentage': checklistItems.isNotEmpty 
          ? (checkedItems.length / checklistItems.length * 100).round()
          : 0,
    };

    return json.encode(result);
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    final hasChildren = _getChildItems(item.id).isNotEmpty;
    final isExpanded = expandedState[item.id] ?? false;
    final isChecked = checkedState[item.id] ?? false;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
            left: item.level * 16.0,
            top: 4.0,
            bottom: 4.0,
          ),
          child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isChecked ? Colors.green.shade300 : Colors.grey.shade300,
                    width: 1.0,
                  ),
                  color: isChecked ? Colors.green.shade50 : Colors.white,
                ),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: () => _toggleCheckbox(item.id),
                      child: Container(
                        width: 24.0,
                        height: 24.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isChecked ? Colors.green : Colors.grey.shade400,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(4.0),
                          color: isChecked ? Colors.green : Colors.transparent,
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 16.0,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    
                    // Titel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleCheckbox(item.id),
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: item.level == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: isChecked ? Colors.green.shade800 : Colors.grey.shade800,
                        ),
                      ),
                      ),
                    ),
                    
                    // Expand/Collapse Button für Items mit Children
                    if (hasChildren)
                      GestureDetector(
                        onTap: () => _toggleExpansion(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.0),
                            border: Border.all(color: HexColor.fromHex(getColor('primary')).withOpacity(0.3)),
                          ),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 24.0,
                            color: HexColor.fromHex(getColor('primary')),
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        ),
        
        // Children (nur wenn expanded)
        if (hasChildren && isExpanded)
          ..._getChildItems(item.id).map((child) => _buildChecklistItem(child)),
      ],
    );
  }

  Widget _buildModernChecklist() {
    final rootItems = _getRootItems();
    final checkedCount = checkedState.values.where((checked) => checked).length;
    final totalCount = checklistItems.length;

    return Column(
      children: [
        // Header mit Statistiken - Kompakt
        Container(
          margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: HexColor.fromHex(getColor('primary')).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: HexColor.fromHex(getColor('primary')).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.checklist, 
                color: HexColor.fromHex(getColor('primary')),
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Abfahrkontroll-Checkliste',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: HexColor.fromHex(getColor('primary')),
                  ),
                ),
              ),
              // Kompakter Progress Indicator
              Container(
                width: 40.0,
                height: 40.0,
                child: CircularProgressIndicator(
                  value: totalCount > 0 ? checkedCount / totalCount : 0.0,
                  backgroundColor: HexColor.fromHex(getColor('primary')).withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(HexColor.fromHex(getColor('primary'))),
                  strokeWidth: 4.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                '$checkedCount/$totalCount',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: HexColor.fromHex(getColor('primary')).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
        // Checkliste mit Bottom-Padding für den Button
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0), // Bottom-Padding für Button
            itemCount: rootItems.length,
            itemBuilder: (context, index) {
              return _buildChecklistItem(rootItems[index]);
            },
          ),
        ),
      ],
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
        title: Text(
          'Abfahrkontrolle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading ? Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
          ),
        ],
      ) : Stack(
        children: [
          // Checkliste nimmt den ganzen verfügbaren Platz ein
          _buildModernChecklist(),
          // Submit Button - Ganz unten angedockt über volle Breite
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  String jsonString = generateJsonString();
                  sendLogs('beforedrive_check', jsonString);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InitNavigationMap(
                        lat: widget.lat,
                        long: widget.long,
                        isFreeDrive: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('Ich bestätige meine Eingabe verbindlich'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor.fromHex(getColor('primary')),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Keine Rundung für volle Breite
                  ),
                  elevation: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
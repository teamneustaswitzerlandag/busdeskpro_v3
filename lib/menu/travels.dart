import 'package:flutter/material.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'travel_modules/wc_finder_module.dart';
import 'travel_modules/action_popup_module.dart';
import 'travel_modules/participants_module.dart';
import 'travel_modules/example_travels_data.dart';
import 'travel_modules/expense_accounting_module.dart';
import 'travel_modules/complaint_module.dart';
import 'travel_modules/travel_feedback_module.dart';
import 'travel_modules/travel_chat_module.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TravelsPage extends StatefulWidget {
  const TravelsPage({super.key});

  @override
  State<TravelsPage> createState() => _TravelsPageState();
}

class _TravelsPageState extends State<TravelsPage> {
  bool isLoading = false;
  String loadingText = "Lade Reisen...";
  List<Map<String, dynamic>> travels = [];
  List<Map<String, dynamic>> filteredTravels = [];
  Map<int, bool> expandedTravels = {};
  Map<String, bool> expandedDays = {};
  String selectedTravelType = 'Aktuelle';
  List<String> travelTypes = ['Vergangene', 'Aktuelle', 'Zukünftige'];
  PageController _pageController = PageController(initialPage: 1); // Start bei "Aktuelle"
  int currentPageIndex = 1; // Track den aktuellen Page-Index

  @override
  void initState() {
    super.initState();
    loadTravels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadTravels() async {
    setState(() {
      isLoading = true;
      loadingText = "Lade Reisen...";
    });

    try {
      // TODO: Hier die API-Anfrage für Reisen implementieren
      // Simuliere API-Aufruf mit realistischer Verzögerung
      await Future.delayed(Duration(milliseconds: 800));
      
      // Beispieldaten aus separater Datei laden
      travels = ExampleTravelsData.generateExampleTravels();
      
      print('=== TRAVELS DEBUG ===');
      print('Loaded ${travels.length} travels');
      if (travels.isNotEmpty) {
        print('First travel: ${travels[0]['ReiseText']}');
        print('First travel fields: ${travels[0].keys}');
      }
      print('====================');
      
      filterTravels();
      
      // Erfolgs-Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reisen erfolgreich aktualisiert'),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Fehler beim Laden der Reisen: $e');
      
      // Fehler-Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Reisen'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterTravels() {
    setState(() {
      switch (selectedTravelType) {
        case 'Vergangene':
          filteredTravels = travels.where((travel) => travel['status'] == 'Vergangene').toList();
          break;
        case 'Zukünftige':
          filteredTravels = travels.where((travel) => travel['status'] == 'Zukünftige').toList();
          break;
        default:
          filteredTravels = travels.where((travel) => travel['status'] == 'Aktuelle').toList();
      }
    });
  }

  String _getSectionHint(String sectionType) {
    switch (sectionType) {
      case 'Vergangene':
        return 'Hier werden Reisen angezeigt, deren Reiseende bereits in der Vergangenheit liegt.';
      case 'Zukünftige':
        return 'Hier werden Reisen angezeigt, deren Reisebeginn in der Zukunft liegt.';
      case 'Aktuelle':
        return 'Hier werden Reisen angezeigt, die bereits begonnen haben oder heute beginnen und noch nicht beendet sind.';
      default:
        return '';
    }
  }

  void toggleTravelExpansion(int travelId) {
    setState(() {
      expandedTravels[travelId] = !(expandedTravels[travelId] ?? false);
    });
  }

  void toggleDayExpansion(String dayKey) {
    setState(() {
      expandedDays[dayKey] = !(expandedDays[dayKey] ?? false);
    });
  }

  IconData _getIconForReiseArt(String reiseArt) {
    final lower = reiseArt.toLowerCase();
    if (lower.contains('städte')) {
      return Icons.location_city;
    } else if (lower.contains('kultur')) {
      return Icons.museum;
    } else if (lower.contains('business')) {
      return Icons.business_center;
    } else if (lower.contains('erlebnis')) {
      return Icons.celebration;
    } else if (lower.contains('wellness')) {
      return Icons.spa;
    } else if (lower.contains('aktiv')) {
      return Icons.hiking;
    } else {
      return Icons.public_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: HexColor.fromHex(getColor('primary')),
                  ),
                  SizedBox(height: 20),
                  Text(
                    loadingText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Travel Type Selector mit Reload-Button
                Container(
                  height: 60,
                  child: Row(
                    children: [
                      // Reload-Button links
                      Container(
                        width: 60,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isLoading
                              ? Padding(
                                  padding: EdgeInsets.all(8),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: HexColor.fromHex(getColor('primary')),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: loadTravels,
                                  icon: Icon(
                                    Icons.refresh_rounded,
                                    color: HexColor.fromHex(getColor('primary')),
                                    size: 20,
                                  ),
                                  tooltip: 'Reisen aktualisieren',
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                          ),
                        ),
                      ),
                      // PageView für Swipe-Buttons
                      Expanded(
                        child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPageIndex = index;
                        selectedTravelType = travelTypes[index];
                      });
                      filterTravels();
                    },
                    itemCount: travelTypes.length,
                    itemBuilder: (context, index) {
                      final type = travelTypes[index];
                      final isSelected = type == selectedTravelType;
                      
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [HexColor.fromHex(getColor('primary')), HexColor.fromHex(getColor('primary')).withOpacity(0.8)]
                                : [Colors.grey[300]!, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                        ),
                      ),
                    ],
                  ),
                ),
                // Swipe-Indikatoren
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wischen, um zwischen aktuellen, vergangenen und zukünftigen Reisen zu switchen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.swipe_right_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
                // Seiten-Indikatoren (Dots)
                Container(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(travelTypes.length, (index) {
                      final isCurrentPage = index == currentPageIndex;
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isCurrentPage ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isCurrentPage 
                              ? HexColor.fromHex(getColor('primary'))
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // Globale Aktionen (WC-Finder, Parkplatzfinder, Notfallrufnummern)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => WCFinderModule.showWCFinderPopup(context, {}),
                          icon: Icon(Icons.wc_rounded, size: 20),
                          label: Text('WC-Finder'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: HexColor.fromHex(getColor('primary')),
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => ActionPopupModule.showActionPopup(context, 'Parkplatzfinder', 'Finden Sie verfügbare Parkplätze in der Nähe.'),
                          icon: Icon(Icons.local_parking_rounded, size: 20),
                          label: Text('Parkplatz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: HexColor.fromHex(getColor('primary')),
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (checkIfAnyModuleIsActive('EmergencyPhonenumbers')) ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openPhonembers(context),
                            icon: Icon(Icons.emergency_rounded, size: 20),
                            label: Text('Notfall'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Hinweis-Text für die aktuelle Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: HexColor.fromHex(getColor('primary')),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSectionHint(selectedTravelType),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Travel List
                Expanded(
                  child: filteredTravels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.travel_explore_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Keine ${selectedTravelType.toLowerCase()} Reisen',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hier werden Ihre Reisen angezeigt',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadTravels,
                          color: HexColor.fromHex(getColor('primary')),
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: filteredTravels.length,
                            itemBuilder: (context, index) {
                              return _buildTravelCard(filteredTravels[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTravelCard(Map<String, dynamic> travel) {
    final bool isExpanded = expandedTravels[travel['DSNummer']] ?? false;
    final startDate = travel['Reisebeginn'] ?? DateTime.now().toIso8601String().split('T')[0];
    final dauer = travel['Dauer'] ?? 0;
    final endDate = DateTime.parse(startDate).add(Duration(days: dauer)).toIso8601String().split('T')[0];
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Travel Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForReiseArt(travel['ReiseArt'] ?? ''),
                          color: HexColor.fromHex(getColor('primary')),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    travel['ReiseText'] ?? 'Unbekannte Reise',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    travel['ReiseKuerzel'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: HexColor.fromHex(getColor('primary')),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  travel['ReiseArt'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        '${_formatDate(startDate)} - ${_formatDate(endDate)} (${dauer} Tage)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Spacer(),
                      // Expand/Collapse Button
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => toggleTravelExpansion(travel['DSNummer']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded Content
            if (isExpanded) ...[
              Divider(height: 1, color: Colors.grey[200]),
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotels
                    if (travel['Hotels'] != null && (travel['Hotels'] as List).isNotEmpty) ...[
                      Text(
                        'Unterkunft',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      ...(travel['Hotels'] as List).map((hotel) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hotel, color: Colors.blue[700], size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hotel['Name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    if (hotel['DatumVon'] != null && hotel['DatumBis'] != null)
                                      Text(
                                        '${_formatDate(hotel['DatumVon'])} - ${_formatDate(hotel['DatumBis'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 20),
                    ],
                    // Action Buttons - Prominent gestaltet
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktionen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _buildActionButton(
                              icon: Icons.receipt_long_rounded,
                              label: 'Spesen',
                              color: Colors.blue,
                              onTap: () => ExpenseAccountingModule.showExpenseAccountingPopup(context, travel, initialTab: 0),
                            ),
                            _buildActionButton(
                              icon: Icons.note_add_rounded,
                              label: 'Notizen erfassen',
                              color: Colors.green,
                              onTap: () => ActionPopupModule.showActionPopup(context, 'Notizen erfassen', 'Erfassen Sie wichtige Notizen und Informationen für diese Reise.'),
                            ),
                            _buildActionButton(
                              icon: Icons.schedule_rounded,
                              label: 'Reiseplan',
                              color: Colors.orange,
                              onTap: () => _showSchedulePopup(context, travel),
                            ),
                            _buildActionButton(
                              icon: Icons.people_rounded,
                              label: 'Teilnehmer',
                              color: Colors.purple,
                              onTap: () => _showParticipantsPopup(context, travel),
                            ),
                            _buildActionButton(
                              icon: Icons.report_problem_rounded,
                              label: 'Beschwerde',
                              color: Colors.red,
                              onTap: () => ComplaintModule.showComplaintPopup(context, travel),
                            ),
                            _buildActionButton(
                              icon: Icons.rate_review_rounded,
                              label: 'Feedback',
                              color: Colors.amber,
                              onTap: () => TravelFeedbackModule.showTravelFeedbackPopup(context, travel),
                            ),
                            _buildActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Chats',
                              color: Colors.teal,
                              onTap: () {
                                final travelId = travel['DSNummer']?.toString() ?? travel['ReiseText'] ?? 'unknown';
                                final travelTitle = travel['ReiseText'] ?? 'Unbekannte Reise';
                                TravelChatModule.showChatList(context, travelId, travelTitle);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
    );
  }

  List<Widget> _buildSchedulePreview(Map<String, dynamic> schedule) {
    List<Widget> widgets = [];
    int maxDays = 2; // Zeige nur die ersten 2 Tage in der Vorschau
    int dayCount = 0;

    for (String day in schedule.keys.take(maxDays)) {
      dayCount++;
      List<dynamic> activities = schedule[day] ?? [];
      
      widgets.add(
        Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 8),
              ...activities.take(2).map((activity) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '${activity['time']} - ${activity['activity']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              )),
              if (activities.length > 2)
                Text(
                  '... und ${activities.length - 2} weitere Aktivitäten',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (schedule.keys.length > maxDays) {
      widgets.add(
        Center(
          child: TextButton(
            onPressed: () => _showSchedulePopup(context, {'schedule': schedule}),
            child: Text(
              'Vollständigen Plan anzeigen (${schedule.keys.length} Tage)',
              style: TextStyle(
                color: HexColor.fromHex(getColor('primary')),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _showParticipantsPopup(BuildContext context, Map<String, dynamic> travel) {
    final participants = travel['participants'] is List 
        ? List<Map<String, dynamic>>.from(travel['participants']) 
        : <Map<String, dynamic>>[];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
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
                        Icons.people_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teilnehmer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${participants.length} Person${participants.length != 1 ? 'en' : ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
                  child: participants.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Keine Teilnehmer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Für diese Reise sind noch keine Teilnehmer registriert.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                onTap: () => ParticipantsModule.showParticipantDetails(
                                  context,
                                  participant,
                                  reisebeginn: travel['Reisebeginn']?.toString(),
                                  dauer: travel['Dauer'] is int ? travel['Dauer'] : (travel['Dauer'] is String ? int.tryParse(travel['Dauer']) : null),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                                        radius: 24,
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: HexColor.fromHex(getColor('primary')),
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ExampleTravelsData.getParticipantName(participant),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            if (participant['room'] != null)
                                              Text(
                                                participant['room'],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
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

  void _showSchedulePopup(BuildContext context, Map<String, dynamic> travel) {
    final verlauf = travel['Verlauf'] is List ? travel['Verlauf'] as List : [];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
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
                        Icons.schedule_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reiseplan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
                // Content
                Expanded(
                  child: verlauf.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Kein Reiseplan verfügbar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Für diese Reise wurde noch kein Plan erstellt.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: verlauf.length,
                        itemBuilder: (context, index) {
                          final day = verlauf[index];
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.orange[50]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: HexColor.fromHex(getColor('primary')),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        day['Tag'] ?? '',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[800],
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
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

  int _getTravelCount(String type) {
    return travels.where((travel) => travel['status'] == type).length;
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'TBD';
    
    try {
      // Parse das Datum (erwartet yyyy-MM-dd Format)
      DateTime date = DateTime.parse(dateString);
      // Formatiere zu dd.MM.yyyy
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      // Falls das Parsing fehlschlägt, gib den ursprünglichen String zurück
      return dateString;
    }
  }

  void _openPhonembers(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final response = await http.get(
        Uri.parse('${getUrl('get-emergencynumbers')}?phonenumber=$PhoneNumberAuth'),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Schließt den Ladekreis

      if (response.statusCode == 200) {
        List<dynamic> phoneNumbers = json.decode(response.body);

        if (!mounted) return;
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
                    // Moderner Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HexColor.fromHex(getColor('primary')),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            "Notfallrufnummern",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Kompakter Content
                    Expanded(
                      child: phoneNumbers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Keine Notfallrufnummern verfügbar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(12),
                              itemCount: phoneNumbers.length,
                              itemBuilder: (context, index) {
                                final phone = phoneNumbers[index];
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.phone_rounded,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Text Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                phone['name'] ?? 'Unbekannt',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                phone['number'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Call Button
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.call_rounded, color: Colors.red, size: 20),
                                            onPressed: () {
                                              sendLogs("log_call_phonenumber", "tel:${phone['number']}");
                                              launchUrlString('tel:${phone['number']}');
                                            },
                                            padding: EdgeInsets.all(8),
                                            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Fehler-Dialog anzeigen
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Fehler'),
                ],
              ),
              content: Text('Die Notfallrufnummern konnten nicht geladen werden.\n\nStatus: ${response.statusCode}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Netzwerk- oder andere Fehler abfangen
      if (!mounted) return;
      Navigator.of(context).pop(); // Schließt den Ladekreis
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Fehler'),
              ],
            ),
            content: Text('Die Notfallrufnummern konnten nicht geladen werden.\n\n${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

}
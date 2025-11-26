import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:intl/intl.dart';

class TravelFeedbackModule {
  static void showTravelFeedbackPopup(BuildContext context, Map<String, dynamic> travel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.95,
            child: _TravelFeedbackForm(travel: travel),
          ),
        );
      },
    );
  }
}

class _TravelFeedbackForm extends StatefulWidget {
  final Map<String, dynamic> travel;

  const _TravelFeedbackForm({required this.travel});

  @override
  State<_TravelFeedbackForm> createState() => _TravelFeedbackFormState();
}

class _TravelFeedbackFormState extends State<_TravelFeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final _travelController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _referenceNumberController = TextEditingController();
  final _tourGuideController = TextEditingController();

  // List of itinerary items with feedback
  List<Map<String, dynamic>> _itineraryItems = [];
  // Map to track expanded state of each item (false = collapsed by default)
  Map<int, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _travelController.text = widget.travel['ReiseText'] ?? '';
    if (widget.travel['Reisebeginn'] != null) {
      _fromDateController.text = _formatDate(widget.travel['Reisebeginn']);
    }
    if (widget.travel['Reisebeginn'] != null && widget.travel['Dauer'] != null) {
      _toDateController.text = _calculateEndDate(widget.travel['Reisebeginn'], widget.travel['Dauer']);
    }
    _referenceNumberController.text = widget.travel['DSNummer']?.toString() ?? '';
    
    // Initialize with planned itinerary from travel data
    if (widget.travel['Verlauf'] is List) {
      final verlauf = widget.travel['Verlauf'] as List<dynamic>;
      _itineraryItems = verlauf.map((item) {
        return {
          'planned': item['Tag'] ?? '',
          'actual': '',
          'suggestion': '',
        };
      }).toList();
      // Initialize all items as collapsed (false)
      for (int i = 0; i < _itineraryItems.length; i++) {
        _expandedItems[i] = false;
      }
    }
  }

  @override
  void dispose() {
    _travelController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _referenceNumberController.dispose();
    _tourGuideController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _calculateEndDate(String? startDate, int? duration) {
    if (startDate == null || duration == null) return '';
    try {
      final start = DateTime.parse(startDate);
      final end = start.add(Duration(days: duration));
      return DateFormat('dd.MM.yyyy').format(end);
    } catch (e) {
      return '';
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('de', 'DE'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor.fromHex(getColor('primary')),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: HexColor.fromHex(getColor('primary')),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: HexColor.fromHex(getColor('primary')),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: HexColor.fromHex(getColor('primary')),
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        controller.text = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
      } else {
        controller.text = DateFormat('dd.MM.yyyy').format(picked);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Column(
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
                Icons.rate_review_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseablaufbericht',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.travel['ReiseText'] != null)
                      Text(
                        widget.travel['ReiseText'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        // Form Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _travelController,
                              label: 'Reise',
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    controller: _fromDateController,
                                    label: 'Von',
                                    context: context,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    controller: _toDateController,
                                    label: 'bis',
                                    context: context,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: _referenceNumberController,
                              label: 'RN',
                            ),
                            SizedBox(height: 12),
                            _buildTextField(
                              controller: _tourGuideController,
                              label: 'Reiseleiter (ggf. geistlicher Begleiter)',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // List Header
                  Text(
                    'Programmablauf',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  // List Items
                  ..._itineraryItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isExpanded = _expandedItems[index] ?? false;
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header - Clickable
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedItems[index] = !isExpanded;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: HexColor.fromHex(getColor('primary')),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Tag ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Card Content - Collapsible
                          if (isExpanded)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                // Geplanter Ablauf
                                Text(
                                  'Ausgeschriebener Programmablauf lt. Katalog, Flyer etc.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item['planned'],
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Geplanter Ablauf',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _itineraryItems[index]['planned'] = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                // Tatsächlicher Ablauf
                                Text(
                                  'Tatsächlicher Programmverlauf mit Zeitangaben',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item['actual'],
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Tatsächlicher Ablauf mit Zeiten',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _itineraryItems[index]['actual'] = value;
                                    });
                                  },
                                ),
                                SizedBox(height: 16),
                                // Verbesserungsvorschläge
                                Text(
                                  'Verbesserungsvorschläge für zukünftige Reise - bitte begründen warum!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item['suggestion'],
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Verbesserungsvorschläge',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _itineraryItems[index]['suggestion'] = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
        // Footer
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _submitFeedback();
              },
              icon: Icon(Icons.send),
              label: Text('Feedback senden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor.fromHex(getColor('primary')),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () => _selectDate(context, controller),
    );
  }

  void _submitFeedback() {
    final feedbackData = {
      'travel': _travelController.text,
      'from_date': _fromDateController.text,
      'to_date': _toDateController.text,
      'reference_number': _referenceNumberController.text,
      'tour_guide': _tourGuideController.text,
      'itinerary_items': _itineraryItems,
      'travel_id': widget.travel['DSNummer']?.toString(),
    };

    print('Feedback data: $feedbackData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback wird gesendet...')),
    );
    
    Navigator.pop(context);
  }
}


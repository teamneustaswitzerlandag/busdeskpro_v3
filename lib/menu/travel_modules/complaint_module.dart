import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:intl/intl.dart';

class ComplaintModule {
  static void showComplaintPopup(BuildContext context, Map<String, dynamic> travel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.95,
            child: _ComplaintForm(travel: travel),
          ),
        );
      },
    );
  }
}

class _ComplaintForm extends StatefulWidget {
  final Map<String, dynamic> travel;

  const _ComplaintForm({required this.travel});

  @override
  State<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<_ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form fields
  final _travelerNameController = TextEditingController();
  final _travelNumberController = TextEditingController();
  final _tourGuideController = TextEditingController();
  final _locationController = TextEditingController();
  final _hotelRoomController = TextEditingController();
  final _complaintDateController = TextEditingController();
  final _agreedServiceController = TextEditingController();
  final _complaintDescriptionController = TextEditingController();
  final _remedyRequestDateController = TextEditingController();
  final _witnessController = TextEditingController();
  final _remedyFormController = TextEditingController();
  final _remedyByController = TextEditingController();
  final _remedyDateController = TextEditingController();

  bool _photosAvailable = false;
  bool _defectsReported = false;
  Map<String, dynamic>? _selectedParticipant;

  List<Map<String, dynamic>> get _participants {
    if (widget.travel['participants'] is List) {
      return List<Map<String, dynamic>>.from(widget.travel['participants']);
    }
    return [];
  }

  String _getParticipantName(Map<String, dynamic> participant) {
    if (participant.containsKey('Name') && participant.containsKey('Vorname')) {
      final vorname = participant['Vorname'] ?? '';
      final name = participant['Name'] ?? '';
      return '$vorname $name'.trim().isEmpty ? 'Unbekannt' : '$vorname $name'.trim();
    } else if (participant.containsKey('firstName') && participant.containsKey('lastName')) {
      final firstName = participant['firstName'] ?? '';
      final lastName = participant['lastName'] ?? '';
      return '$firstName $lastName'.trim().isEmpty ? 'Unbekannt' : '$firstName $lastName'.trim();
    }
    return 'Unbekannt';
  }

  @override
  void initState() {
    super.initState();
    _travelNumberController.text = widget.travel['ReiseText'] ?? '';
    _complaintDateController.text = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
  }

  @override
  void dispose() {
    _travelerNameController.dispose();
    _travelNumberController.dispose();
    _tourGuideController.dispose();
    _locationController.dispose();
    _hotelRoomController.dispose();
    _complaintDateController.dispose();
    _agreedServiceController.dispose();
    _complaintDescriptionController.dispose();
    _remedyRequestDateController.dispose();
    _witnessController.dispose();
    _remedyFormController.dispose();
    _remedyByController.dispose();
    _remedyDateController.dispose();
    _pageController.dispose();
    super.dispose();
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
                Icons.report_problem_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beschwerde-Protokoll',
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
        // Page Indicator
        Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageIndicator(0, 'Seite 1'),
              SizedBox(width: 20),
              _buildPageIndicator(1, 'Seite 2'),
            ],
          ),
        ),
        // Form Content
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildPage1(),
              _buildPage2(),
            ],
          ),
        ),
        // Navigation Buttons
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(Icons.arrow_back),
                    label: Text('Zurück'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (_currentPage > 0) SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _submitComplaint();
                    }
                  },
                  icon: Icon(_currentPage == 0 ? Icons.arrow_forward : Icons.send),
                  label: Text(_currentPage == 0 ? 'Weiter' : 'Beschwerde senden'),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int page, String label) {
    final isActive = _currentPage == page;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          page,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? HexColor.fromHex(getColor('primary')) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? HexColor.fromHex(getColor('primary')) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teilnehmerauswahl
            Text(
              'Name des Reisenden *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedParticipant,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                hintText: 'Teilnehmer auswählen',
              ),
              items: _participants.map((participant) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: participant,
                  child: Text(_getParticipantName(participant)),
                );
              }).toList(),
              onChanged: (participant) {
                setState(() {
                  _selectedParticipant = participant;
                  if (participant != null) {
                    _travelerNameController.text = _getParticipantName(participant);
                    _hotelRoomController.text = participant['room']?.toString() ?? '';
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Bitte wählen Sie einen Teilnehmer aus';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _travelNumberController,
              label: 'Reisenummer oder Reisetitel',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _tourGuideController,
              label: 'Reiseleiter/Geistlicher Begleiter',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Urlaubsort',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _hotelRoomController,
              label: 'Hotel/Zimmer-Nr.',
            ),
            SizedBox(height: 16),
            _buildDateTimePicker(
              controller: _complaintDateController,
              label: 'Datum/Zeit der Beanstandung',
            ),
            SizedBox(height: 24),
            Text(
              'Vereinbarte Reiseleistung nach dem Reisevertrag (vgl. Leistungsblock der Reiseausschreibung):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            _buildTextField(
              controller: _agreedServiceController,
              label: '',
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Folgendes wird beanstandet (möglichst detaillierte Beschreibung):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            _buildTextField(
              controller: _complaintDescriptionController,
              label: '',
              maxLines: 5,
              required: true,
            ),
            SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Die bp-Reiseleitung wird gebeten, den Mangel per Foto festzuhalten, wenn dies möglich ist. Fotos vorhanden?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _photosAvailable,
                      onChanged: (value) {
                        setState(() {
                          _photosAvailable = value ?? false;
                        });
                      },
                    ),
                    Text('Ja'),
                    SizedBox(width: 12),
                    Radio<bool>(
                      value: false,
                      groupValue: _photosAvailable,
                      onChanged: (value) {
                        setState(() {
                          _photosAvailable = value ?? false;
                        });
                      },
                    ),
                    Text('Nein'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Oben genannte Mängel wurden angezeigt.'),
              value: _defectsReported,
              onChanged: (value) {
                setState(() {
                  _defectsReported = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            SizedBox(height: 16),
            _buildDateTimePicker(
              controller: _remedyRequestDateController,
              label: 'Es wird Abhilfe verlangt bis (Datum/Zeit):',
            ),
            SizedBox(height: 24),
            Text(
              'Folgende Mitarbeiter des betroffenen Leistungsträgers vor Ort, z. B. Hotel, Busunternehmen, können den Mangel bezeugen (Name, ggf. Kontaktdaten):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            _buildTextField(
              controller: _witnessController,
              label: '',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Erfolgte Abhilfe:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'In welcher Form?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _remedyFormController,
            label: '',
            maxLines: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Durch wen?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildTextField(
            controller: _remedyByController,
            label: '',
          ),
          SizedBox(height: 16),
          Text(
            'Wann? (Datum/Zeit)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          _buildDateTimePicker(
            controller: _remedyDateController,
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool required = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
      validator: required && enabled
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Dieses Feld ist erforderlich';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _selectDateTime(BuildContext context, TextEditingController controller) async {
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

  Widget _buildDateTimePicker({
    required TextEditingController controller,
    required String label,
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
      onTap: () => _selectDateTime(context, controller),
    );
  }

  void _submitComplaint() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement API call to send complaint
      final complaintData = {
        'traveler_name': _travelerNameController.text,
        'travel_number': _travelNumberController.text,
        'tour_guide': _tourGuideController.text,
        'location': _locationController.text,
        'hotel_room': _hotelRoomController.text,
        'complaint_date': _complaintDateController.text,
        'agreed_service': _agreedServiceController.text,
        'complaint_description': _complaintDescriptionController.text,
        'photos_available': _photosAvailable,
        'defects_reported': _defectsReported,
        'remedy_request_date': _remedyRequestDateController.text,
        'witness': _witnessController.text,
        'remedy_form': _remedyFormController.text,
        'remedy_by': _remedyByController.text,
        'remedy_date': _remedyDateController.text,
        'travel_id': widget.travel['DSNummer']?.toString(),
      };

      print('Complaint data: $complaintData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beschwerde wird gesendet...')),
      );
      
      Navigator.pop(context);
    }
  }
}


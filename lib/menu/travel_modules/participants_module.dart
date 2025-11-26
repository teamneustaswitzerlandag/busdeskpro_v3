import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class ParticipantsModule {
  static void showParticipantDetails(
    BuildContext context,
    Map<String, dynamic> participant, {
    String? reisebeginn,
    int? dauer,
  }) {
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
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          color: HexColor.fromHex(getColor('primary')),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getParticipantName(participant),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kontaktdaten (nur bei aktiver Reise)
                        if (_isTravelActive(reisebeginn, dauer))
                          _buildContactSection(participant),
                        if (_isTravelActive(reisebeginn, dauer))
                          SizedBox(height: 24),
                        // Zimmerbelegung
                        _buildRoomSection(participant),
                        SizedBox(height: 24),
                        // Zusätzliche Informationen
                        _buildAdditionalInfoSection(participant),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callParticipant(participant),
                          icon: Icon(Icons.phone_rounded),
                          label: Text('Anrufen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _messageParticipant(participant),
                          icon: Icon(Icons.message_rounded),
                          label: Text('Nachricht'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
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
  }

  static Widget _buildContactSection(Map<String, dynamic> participant) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone_rounded, color: Colors.blue.shade600),
              SizedBox(width: 8),
              Text(
                'Kontaktdaten',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (participant['phone'] != null) ...[
            _buildContactRow(Icons.phone_rounded, 'Telefon', participant['phone'] ?? 'Nicht verfügbar'),
            SizedBox(height: 8),
          ],
          if (participant['mobile'] != null) ...[
            _buildContactRow(Icons.phone_android_rounded, 'Mobil', participant['mobile'] ?? 'Nicht verfügbar'),
            SizedBox(height: 8),
          ],
          if (participant['email'] != null) ...[
            _buildContactRow(Icons.email_rounded, 'E-Mail', participant['email'] ?? 'Nicht verfügbar'),
          ],
          if (participant['phone'] == null && participant['mobile'] == null && participant['email'] == null) ...[
            Text(
              'Keine Kontaktdaten verfügbar',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildRoomSection(Map<String, dynamic> participant) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bed_rounded, color: Colors.green.shade600),
              SizedBox(width: 8),
              Text(
                'Zimmerbelegung',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (participant['room'] != null) ...[
            _buildInfoRow('Zimmer', participant['room'] ?? 'Nicht zugewiesen'),
            SizedBox(height: 8),
          ],
          if (participant['roomType'] != null) ...[
            _buildInfoRow('Zimmertyp', participant['roomType'] ?? 'Standard'),
            SizedBox(height: 8),
          ],
          if (participant['room'] == null && participant['roomType'] == null) ...[
            Text(
              'Keine Zimmerdaten verfügbar',
              style: TextStyle(
                color: Colors.green.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }


  static Widget _buildAdditionalInfoSection(Map<String, dynamic> participant) {
    final info = participant['additionalInfo'] as Map<String, dynamic>? ?? {};
    
    if (info.isEmpty) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.purple.shade600),
              SizedBox(width: 8),
              Text(
                'Zusätzliche Informationen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (info['dietary'] != null) ...[
            _buildInfoRow('Diät/Allergien', info['dietary']?.toString() ?? 'Unbekannt'),
            SizedBox(height: 8),
          ],
          if (info['medical'] != null) ...[
            _buildInfoRow('Medizinische Hinweise', info['medical']?.toString() ?? 'Unbekannt'),
            SizedBox(height: 8),
          ],
          if (info['notes'] != null) ...[
            _buildInfoRow('Notizen', info['notes']?.toString() ?? 'Unbekannt'),
          ],
        ],
      ),
    );
  }

  static Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade600),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade800,
          ),
        ),
          Expanded(
            child: Text(
              value ?? 'Nicht verfügbar',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
      ],
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'Nicht verfügbar',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  static Widget buildParticipantsList(
    List<Map<String, dynamic>> participants, {
    String? reisebeginn,
    int? dauer,
  }) {
    if (participants.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300!),
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline_rounded, color: Colors.grey.shade500),
            SizedBox(width: 12),
            Text(
              'Keine Teilnehmer verfügbar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people_rounded,
                color: HexColor.fromHex(getColor('primary')),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Teilnehmer (${participants.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: HexColor.fromHex(getColor('primary')),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        ...participants.map((participant) => _buildParticipantCard(
          participant,
          reisebeginn: reisebeginn,
          dauer: dauer,
        )),
      ],
    );
  }

  static Widget _buildParticipantCard(
    Map<String, dynamic> participant, {
    String? reisebeginn,
    int? dauer,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (BuildContext context) {
          return InkWell(
            onTap: () => showParticipantDetails(
              context,
              participant,
              reisebeginn: reisebeginn,
              dauer: dauer,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                child: Icon(
                  Icons.person_rounded,
                  color: HexColor.fromHex(getColor('primary')),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getParticipantName(participant),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  static String _getParticipantName(Map<String, dynamic> participant) {
    // SOAP-Format: Name, Vorname
    if (participant.containsKey('Name') && participant.containsKey('Vorname')) {
      final vorname = participant['Vorname'] ?? '';
      final name = participant['Name'] ?? '';
      return '$vorname $name'.trim().isEmpty ? 'Unbekannt' : '$vorname $name'.trim();
    }
    // Legacy-Format: firstName, lastName
    else if (participant.containsKey('firstName') && participant.containsKey('lastName')) {
      final firstName = participant['firstName'] ?? '';
      final lastName = participant['lastName'] ?? '';
      return '$firstName $lastName'.trim().isEmpty ? 'Unbekannt' : '$firstName $lastName'.trim();
    }
    return 'Unbekannt';
  }

  static void _callParticipant(Map<String, dynamic> participant) {
    // TODO: Implement phone call functionality
    print('Calling ${participant['name']}: ${participant['contact']?['phone']}');
  }

  static void _messageParticipant(Map<String, dynamic> participant) {
    // TODO: Implement messaging functionality
    print('Messaging ${participant['name']}: ${participant['contact']?['email']}');
  }

  static List<Widget> _buildStarRating(dynamic ratingValue) {
    String ratingStr = ratingValue?.toString() ?? '0';
    int rating = int.tryParse(ratingStr) ?? 0;
    
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      stars.add(
        Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber.shade600,
          size: 20,
        ),
      );
    }
    return stars;
  }

  /// Prüft, ob eine Reise aktiv ist (14 Tage vor Reisebeginn bis 5 Tage nach Reiseende)
  static bool _isTravelActive(String? reisebeginn, int? dauer) {
    if (reisebeginn == null || dauer == null) {
      return false;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final beginn = DateTime.parse(reisebeginn);
      final beginnDate = DateTime(beginn.year, beginn.month, beginn.day);
      final endeDate = beginnDate.add(Duration(days: dauer - 1));
      
      // Aktiver Zeitraum: 14 Tage vor Reisebeginn bis 5 Tage nach Reiseende
      final aktivAb = beginnDate.subtract(Duration(days: 14));
      final aktivBis = endeDate.add(Duration(days: 5));
      
      // Prüfe, ob heute im aktiven Zeitraum liegt (inklusive der Grenztage)
      // today >= aktivAb && today <= aktivBis
      return !today.isBefore(aktivAb) && !today.isAfter(aktivBis);
    } catch (e) {
      // Bei Parsing-Fehler: Kontaktdaten nicht anzeigen
      return false;
    }
  }
}


import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class ActionPopupModule {
  static void showActionPopup(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
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
                        _getActionIcon(title),
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
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
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Description
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: HexColor.fromHex(getColor('primary')),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        // Action content based on title
                        Expanded(
                          child: _buildActionContent(title),
                        ),
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
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Schließen'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement functionality based on title
                            _handleAction(context, title);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(_getActionButtonText(title)),
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

  static Widget _buildActionContent(String title) {
    switch (title) {
      case 'Belege hochladen':
        return _buildUploadContent();
      case 'Notizen erfassen':
        return _buildNotesContent();
      case 'Parkplatzfinder':
        return _buildParkingContent();
      default:
        return _buildDefaultContent();
    }
  }

  static Widget _buildUploadContent() {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 48,
                color: Colors.grey[500],
              ),
              SizedBox(height: 8),
              Text(
                'Dateien hier hinziehen',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'oder klicken zum Auswählen',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Unterstützte Formate: PDF, JPG, PNG, DOC',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  static Widget _buildNotesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notiz hinzufügen:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: TextField(
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: 'Geben Sie hier Ihre Notizen ein...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HexColor.fromHex(getColor('primary'))),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildParkingContent() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_parking_rounded,
                color: Colors.blue[600],
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parkplätze in der Nähe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Suche nach verfügbaren Parkplätzen...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: HexColor.fromHex(getColor('primary')),
                ),
                SizedBox(height: 16),
                Text(
                  'Lade Parkplätze...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildDefaultContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Feature in Entwicklung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Diese Funktion wird bald verfügbar sein.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _getActionIcon(String title) {
    switch (title) {
      case 'Belege hochladen':
        return Icons.upload_file_rounded;
      case 'Notizen erfassen':
        return Icons.note_add_rounded;
      case 'Parkplatzfinder':
        return Icons.local_parking_rounded;
      case 'WC-Finder':
        return Icons.wc_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static String _getActionButtonText(String title) {
    switch (title) {
      case 'Belege hochladen':
        return 'Hochladen';
      case 'Notizen erfassen':
        return 'Speichern';
      case 'Parkplatzfinder':
        return 'Suchen';
      default:
        return 'OK';
    }
  }

  static void _handleAction(BuildContext context, String title) {
    switch (title) {
      case 'Belege hochladen':
        // TODO: Implement file upload
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Datei-Upload wird implementiert...')),
        );
        break;
      case 'Notizen erfassen':
        // TODO: Save notes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notiz wird gespeichert...')),
        );
        break;
      case 'Parkplatzfinder':
        // TODO: Search for parking
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Parkplatzsuche wird gestartet...')),
        );
        break;
      default:
        break;
    }
    Navigator.pop(context);
  }
}

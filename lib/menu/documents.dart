import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

class DocumentListPage extends StatefulWidget {
  @override
  _DocumentListPageState createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> with TickerProviderStateMixin {
  List<dynamic> documents = [];
  bool _isLoading = true;
  int _loadedCount = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchDocuments();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    try {
      String jsonString = await rootBundle.loadString('lib/config/apis.json');
      Map<String, dynamic> parsedJson = json.decode(jsonString);
      final url = Uri.parse(getUrl('get-documents'));

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          documents = json.decode(response.body);
          _loadedCount = documents.length;
          _isLoading = false;
        });
        
        _animationController.forward();
      } else {
        throw Exception('Fehler beim Abrufen der Dokumente');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Fehler beim Laden der Dokumente: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Erneut versuchen',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _fetchDocuments();
          },
        ),
      ),
    );
  }

  // Datum formatieren
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);
      
      if (difference.inDays == 0) {
        return 'Heute ${DateFormat('HH:mm').format(parsedDate)}';
      } else if (difference.inDays == 1) {
        return 'Gestern ${DateFormat('HH:mm').format(parsedDate)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} Tag${difference.inDays > 1 ? 'e' : ''} her';
      } else {
        return DateFormat('dd.MM.yyyy HH:mm').format(parsedDate);
      }
    } catch (e) {
      return date;
    }
  }

  String _getRelativeTime(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);
      
      if (difference.inMinutes < 1) {
        return 'Gerade eben';
      } else if (difference.inMinutes < 60) {
        return 'vor ${difference.inMinutes} Min';
      } else if (difference.inHours < 24) {
        return 'vor ${difference.inHours} Std';
      } else {
        return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? 'en' : ''}';
      }
    } catch (e) {
      return '';
    }
  }

  // Dateigröße formatieren
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Dateityp-Icon bestimmen
  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('text')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  // Dateityp-Farbe bestimmen
  Color _getFileColor(String mimeType) {
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('word') || mimeType.contains('document')) return Colors.blue;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Colors.green;
    if (mimeType.contains('image')) return Colors.orange;
    if (mimeType.contains('text')) return Colors.grey;
    return HexColor.fromHex(getColor('primary'));
  }

  void _openDocument(BuildContext context, String documentId, String mimeType) async {
    try {
      // URL aus der Konfiguration holen und documentId ersetzen
      final openUrl = getUrl('open-document').replaceAll('{documentId}', documentId);
      final url = Uri.parse(openUrl);
      
      // Logging
      sendLogs("log_open_document", "${PhoneNumberAuth}_$documentId");
      
      // Prüfen ob es ein PDF ist
      if (mimeType.contains('pdf')) {
        // PDF als Popup anzeigen
        _showPdfPopup(context, openUrl, documentId);
      } else {
        // Andere Dateitypen zum Download anbieten
        _showDownloadDialog(context, openUrl, documentId, mimeType);
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Öffnen des Dokuments: $e');
    }
  }

  void _showPdfPopup(BuildContext context, String pdfUrl, String documentId) async {
    // Loading Dialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    HexColor.fromHex(getColor('primary')),
                  ),
                ),
                SizedBox(height: 16),
                Text('PDF wird geladen...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // PDF-Daten herunterladen
      final response = await http.get(Uri.parse(pdfUrl));
      
      if (response.statusCode == 200) {
        // Loading Dialog schließen
        Navigator.of(context).pop();
        
        // PDF Viewer anzeigen
        _showPdfViewer(context, response.bodyBytes, documentId);
      } else {
        Navigator.of(context).pop();
        _showErrorSnackBar('Fehler beim Laden des PDFs: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Fehler beim Laden des PDFs: $e');
    }
  }

  void _showPdfViewer(BuildContext context, Uint8List pdfData, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              children: [
                // Header
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
                      Icon(Icons.picture_as_pdf, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PDF-Viewer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // PDF Viewer
                Expanded(
                  child: Container(
                    child: PDFView(
                      pdfData: pdfData, // Verwende pdfData statt filePath
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: true,
                      pageSnap: true,
                      onError: (error) {
                        _showErrorSnackBar('Fehler beim Anzeigen des PDFs: $error');
                      },
                      onPageError: (page, error) {
                        _showErrorSnackBar('Fehler auf Seite $page: $error');
                      },
                      onViewCreated: (PDFViewController controller) {
                        // PDF Controller für weitere Steuerung
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context, String downloadUrl, String documentId, String mimeType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_getFileIcon(mimeType), color: _getFileColor(mimeType)),
              SizedBox(width: 8),
              Text('Download'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Möchten Sie diese Datei herunterladen?'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Die Datei wird in Ihrem Browser geöffnet und kann von dort heruntergeladen werden.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchDownload(downloadUrl);
              },
              icon: Icon(Icons.download),
              label: Text('Download starten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor.fromHex(getColor('primary')),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Kann Download-URL nicht öffnen');
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Starten des Downloads: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.folder_open, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Dokumente',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Refresh Button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchDocuments();
            },
            tooltip: 'Dokumente aktualisieren',
          ),
          // Counter
          if (_loadedCount > 0)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_loadedCount',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : documents.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _fetchDocuments,
                    color: HexColor.fromHex(getColor('primary')),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        return _buildDocumentCard(documents[index], index);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              HexColor.fromHex(getColor('primary')),
            ),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            "Dokumente werden geladen...",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Keine Dokumente verfügbar",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Es sind derzeit keine Dokumente vorhanden.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchDocuments,
            icon: Icon(Icons.refresh),
            label: Text('Aktualisieren'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    final filename = document['filename'] ?? 'Unbekanntes Dokument';
    final createdAt = document['created_at'] ?? '';
    final fileSize = document['file_size'] ?? 0;
    final mimeType = document['mime_type'] ?? '';
    final documentId = document['id'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDocument(context, documentId, mimeType), // mimeType hinzugefügt
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // File Icon
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getFileColor(mimeType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(mimeType),
                    color: _getFileColor(mimeType),
                    size: 28,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filename
                      Text(
                        filename,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4),
                      
                      // File info
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.storage,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatFileSize(fileSize),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Relative time
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRelativeTime(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: HexColor.fromHex(getColor('primary')),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Open Button
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    color: HexColor.fromHex(getColor('primary')),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
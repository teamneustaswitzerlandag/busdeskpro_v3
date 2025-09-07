import 'package:flutter/material.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MandantConfigDialog extends StatefulWidget {
  @override
  _MandantConfigDialogState createState() => _MandantConfigDialogState();
}

class _MandantConfigDialogState extends State<MandantConfigDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic>? _currentTenant;
  bool _isLoading = false;
  final _storage = FlutterSecureStorage();
  
  // State für einklappbare Bereiche
  bool _apisExpanded = false;
  bool _modulesExpanded = false;
  bool _colorsExpanded = false;
  bool _logosExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200), // Noch schneller
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1), // Minimaler Slide
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    // Sofortige Animation starten
    _animationController.forward();
    
    // Tenant asynchron laden
    _loadCurrentTenantAsync();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentTenantAsync() async {
    try {
      final cachedTenant = await _storage.read(key: 'deviceCachedTenant');
      if (cachedTenant != null && mounted) {
        // JSON Parsing in separatem Isolate für bessere Performance
        final tenant = json.decode(cachedTenant);
        if (mounted) {
          setState(() {
            _currentTenant = tenant;
          });
        }
      }
    } catch (e) {
      print('Error loading tenant: $e');
    }
  }

  Future<void> _reloadTenantConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://bus-dashboard.dxp.azure.neusta.cloud:7698/getTenants'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> tenants = decoded['body'];
        
        for (var tenant in tenants) {
          if (tenant['name'] == MandantAuth) {
            // Tenant in Storage speichern
            await _storage.write(key: 'deviceCachedTenant', value: jsonEncode(tenant));
            
            // Globalen Tenant aktualisieren
            GblTenant = tenant;
            
            // UI aktualisieren
            if (mounted) {
              setState(() {
                _currentTenant = tenant;
              });
            }
            break;
          }
        }
        
        // Erfolgs-Feedback im Popup anzeigen
        if (mounted) {
          _showSuccessMessage('Mandanten-Konfiguration erfolgreich aktualisiert');
        }
      } else {
        throw Exception('Failed to load tenants');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Fehler beim Laden der Konfiguration: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Erfolg',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Fehler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: _currentTenant == null 
                      ? _buildLoadingState()
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCurrentTenantInfo(),
                              SizedBox(height: 24),
                              _buildConfigurationDetails(),
                              SizedBox(height: 24),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HexColor.fromHex(getColor('primary')),
            HexColor.fromHex(getColor('primary')).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.business,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Mandanten-Konfiguration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTenantInfo() {
    if (_currentTenant == null) {
      return _buildLoadingState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: HexColor.fromHex(getColor('primary')),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Aktueller Mandant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('Name', _currentTenant!['name'] ?? 'N/A'),
            if (_currentTenant!['description'] != null)
              _buildInfoRow('Beschreibung', _currentTenant!['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationDetails() {
    if (_currentTenant == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // APIs - Nur wenn vorhanden
        if (_currentTenant!['apis'] != null)
          _buildApisSection(),
        
        // Module - Nur wenn vorhanden
        if (_currentTenant!['modules'] != null)
          _buildModulesSection(),
        
        // Colors - Nur wenn vorhanden
        if (_currentTenant!['colors'] != null)
          _buildColorsSection(),
        
        // Logos - Nur wenn vorhanden
        if (_currentTenant!['logos'] != null)
          _buildLogosSection(),
        
        // App-spezifische Einstellungen
        _buildAppConfig(),
      ],
    );
  }

  Widget _buildApisSection() {
    List<dynamic> apis = _currentTenant!['apis'];
    
    return _buildExpandableSection(
      title: 'Verfügbare APIs (${apis.length})',
      icon: Icons.api,
      isExpanded: _apisExpanded,
      onToggle: () {
        setState(() {
          _apisExpanded = !_apisExpanded;
        });
      },
      child: Column(
        children: apis.map<Widget>((api) {
          return Container(
            margin: EdgeInsets.only(bottom: 6), // Reduziert
            padding: EdgeInsets.all(10), // Reduziert
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: InkWell(
              onTap: () => _showUrlDialog(api['api'] ?? 'N/A', api['url'] ?? 'N/A'),
              child: Row(
                children: [
                  Icon(
                    Icons.api,
                    size: 14, // Reduziert
                    color: HexColor.fromHex(getColor('primary')),
                  ),
                  SizedBox(width: 6), // Reduziert
                  Expanded(
                    child: Text(
                      api['api'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontSize: 13, // Reduziert
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10, // Reduziert
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModulesSection() {
    List<dynamic> modules = _currentTenant!['modules'];
    
    return _buildExpandableSection(
      title: 'Module Aktivierungen (${modules.length})',
      icon: Icons.extension,
      isExpanded: _modulesExpanded,
      onToggle: () {
        setState(() {
          _modulesExpanded = !_modulesExpanded;
        });
      },
      child: Column(
        children: modules.map<Widget>((module) {
          bool isActive = module['active'] == true;
          return Container(
            margin: EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isActive ? Colors.green[600] : Colors.red[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    module['module'] ?? 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.green[800] : Colors.red[800],
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isActive ? 'Aktiv' : 'Inaktiv',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorsSection() {
    List<dynamic> colors = _currentTenant!['colors'];
    
    return _buildExpandableSection(
      title: 'Farb-Konfiguration (${colors.length})',
      icon: Icons.palette,
      isExpanded: _colorsExpanded,
      onToggle: () {
        setState(() {
          _colorsExpanded = !_colorsExpanded;
        });
      },
      child: Column(
        children: colors.map<Widget>((color) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${color['name']}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(color['value'] ?? '000000'),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '#${color['value']}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogosSection() {
    List<dynamic> logos = _currentTenant!['logos'];
    
    return _buildExpandableSection(
      title: 'Logo-Konfiguration (${logos.length})',
      icon: Icons.image,
      isExpanded: _logosExpanded,
      onToggle: () {
        setState(() {
          _logosExpanded = !_logosExpanded;
        });
      },
      child: Column(
        children: logos.map<Widget>((logo) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${logo['name']}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                if (logo['value'] != null && logo['value']['\$content'] != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        base64Decode(logo['value']['\$content']),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Base64 Image (${logo['value']?['\$content']?.length ?? 0} chars)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Einstellungen',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        _buildConfigItem('Primary Color', getColor('primary')),
        _buildConfigItem('App Version', AppVersion),
        _buildConfigItem('Phone Number', PhoneNumberAuth),
      ],
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (label == 'Primary Color')
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: HexColor.fromHex(value),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
          if (label != 'Primary Color')
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.grey[800],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _reloadTenantConfig,
            icon: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync_alt, size: 18),
            label: Text(_isLoading ? 'Lädt...' : 'Neu laden'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: HexColor.fromHex(getColor('primary')),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.check, size: 18),
            label: Text('Fertig'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              HexColor.fromHex(getColor('primary')),
            ),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Lade Konfiguration...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12), // Reduziert
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10), // Reduziert
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.all(12), // Reduziert
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: HexColor.fromHex(getColor('primary')),
                    size: 18, // Reduziert
                  ),
                  SizedBox(width: 8), // Reduziert
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15, // Reduziert
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                    size: 18, // Reduziert
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12), // Reduziert
              child: child,
            ),
        ],
      ),
    );
  }

  void _showUrlDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.api,
              color: HexColor.fromHex(getColor('primary')),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SelectableText(
            url,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.grey[700],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Schließen'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Hier könntest du die URL kopieren oder öffnen
            },
            icon: Icon(Icons.copy, size: 16),
            label: Text('Kopieren'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

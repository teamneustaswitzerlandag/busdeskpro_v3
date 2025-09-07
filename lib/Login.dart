import 'dart:convert';
import 'dart:math';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/Login2.dart';
import 'package:bus_desk_pro/libaries/blinking_point.dart';
import 'package:bus_desk_pro/libaries/countdown_loader.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:bus_desk_pro/libaries/tour.dart';
import 'package:bus_desk_pro/main.dart';
//import 'package:bus_desk_pro/maps/maps-base-kopie-example2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

//const String flavor = String.fromEnvironment('flavor', defaultValue: 'prod');

class LoginCacheChecker extends StatefulWidget {
  LoginCacheChecker({Key? key}) : super(key: key);

  @override
  _CheckConditionWidgetState createState() => _CheckConditionWidgetState();
}

class _CheckConditionWidgetState extends State<LoginCacheChecker> {

  @override
  void initState() {
    super.initState();
    _executeCustomLogic();
  }

  void _executeCustomLogic() async {
    final _storage = FlutterSecureStorage();
    var storedPhonenumber = await _storage.read(key: 'deviceCachedPhonenumber');
    var storedMandant = await _storage.read(key: 'deviceCachedMandant');
    var storedTenant = await _storage.read(key: 'deviceCachedTenant');
    startLocationUpdates();
    Timer(Duration(seconds: 3), () {
      if (storedPhonenumber == null && storedTenant == null && storedMandant == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        PhoneNumberAuth = storedPhonenumber?? '';
        MandantAuth = storedMandant?? '';
        GblTenant = jsonDecode(storedTenant??'');
        InitUniqueAppUserId();
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LandingPage(
                title: 'BusDesk Pro',
              ),
            )
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // Hintergrundfarbe auf weiß setzen
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text(
                'App wird geladen...',
                style: TextStyle(fontSize: 18, color: Colors.black), // Textfarbe auf schwarz setzen
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _mandantController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  // 4-stellige Code-Eingabe Controller
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  
  String _selectedLoginType = 'phone';
  bool _isLoading = false;
  bool _otpSent = false;
  bool _tenantValidated = false;
  Map<String, dynamic>? _currentTenant;
  final _storage = FlutterSecureStorage();
  
  // Länder-Code-Dropdown
  String _selectedCountryCode = '+49';
  String _selectedCountryFlag = '🇩🇪';
  String _selectedCountryName = 'Deutschland';

  // Länder-Liste
  final List<Map<String, String>> _countries = [
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Deutschland'},
    {'code': '+43', 'flag': '🇦🇹', 'name': 'Österreich'},
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Schweiz'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'Großbritannien'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'Frankreich'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italien'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Spanien'},
    {'code': '+31', 'flag': '🇳🇱', 'name': 'Niederlande'},
    {'code': '+32', 'flag': '🇧🇪', 'name': 'Belgien'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStoredCredentials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cleanup der OTP Controller und Focus Nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _checkStoredCredentials() async {
    final storedMandant = await _storage.read(key: 'deviceCachedMandant');
    if (storedMandant != null) {
      _mandantController.text = storedMandant;
      await _validateTenant();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Verhindere Zurück-Navigation
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - nur anzeigen wenn Tenant validiert UND nicht bei Mandant-Eingabe
                  if (_tenantValidated && _currentTenant != null && _selectedLoginType != 'phone')
                    _buildLogo()
                  else if (_tenantValidated && _currentTenant != null && _selectedLoginType == 'phone')
                    _buildLogo()
                  else if (!_tenantValidated)
                    SizedBox.shrink(), // Kein Logo bei Mandant-Eingabe
                  
                  SizedBox(height: 40),
                  
                  // Mandant Eingabe - nur wenn noch nicht validiert
                  if (!_tenantValidated)
                    _buildMandantInput(),
                  
                  // Abstand zwischen Mandant-Eingabe und Button
                  if (!_tenantValidated)
                    SizedBox(height: 20),
                  
                  // Tenant Validierung Button - nur wenn noch nicht validiert
                  if (!_tenantValidated)
                    _buildValidateTenantButton(),
                  
                  SizedBox(height: 20),
                  
                  // Login Type Selection - nur wenn Tenant validiert und Module verfügbar
                  if (_tenantValidated && _shouldShowLoginTypeSelection())
                    _buildLoginTypeSelection(),
                  
                  SizedBox(height: 20),
                  
                  // Phone/Employee Input - nur wenn Tenant validiert und OTP noch nicht gesendet
                  if (_tenantValidated && !_otpSent)
                    if (_selectedLoginType == 'phone')
                      _buildPhoneInput()
                    else
                      _buildEmployeeInput(),
                  
                  SizedBox(height: 20),
                  
                  // OTP Input - nur bei Phone Login und nach SMS-Versand
                  if (_tenantValidated && _selectedLoginType == 'phone' && _otpSent)
                    _buildOtpInput(),
                  
                  SizedBox(height: 30),
                  
                  // Login Button - nur wenn Tenant validiert
                  if (_tenantValidated)
                    _buildLoginButton(),
                  
                  // Zusätzlicher Platz am Ende für Tastatur
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _buildLogoContent(),
    );
  }

  Widget _buildLogoContent() {
    try {
      if (_currentTenant != null && _currentTenant!['logos'] != null) {
        List<dynamic> logos = _currentTenant!['logos'];
        for (var logo in logos) {
          if (logo['name'] == 'logo' && logo['value']?['\$content'] != null) {
            return Image.memory(
              base64Decode(logo['value']['\$content']),
              height: (_otpSent || _selectedLoginType == 'phone') ? 40 : 100,
              fit: BoxFit.contain,
              key: ValueKey('logo_${_selectedLoginType}_${_otpSent}'), // Stabile Key
            );
          }
        }
      }
    } catch (e) {
      print('Error loading logo: $e');
    }
    
    return _buildPlaceholderLogo();
  }

  Widget _buildPlaceholderLogo() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: (_otpSent || _selectedLoginType == 'phone') ? 40 : 100,
      width: (_otpSent || _selectedLoginType == 'phone') ? 80 : 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: (_otpSent || _selectedLoginType == 'phone') ? 20 : 40,
            color: Colors.grey[400],
          ),
          if (!_otpSent && _selectedLoginType != 'phone')
            Column(
              children: [
                SizedBox(height: 8),
                Text(
                  'Mandant eingeben',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMandantInput() {
    return TextField(
      controller: _mandantController,
      decoration: InputDecoration(
        labelText: 'Mandant',
        hintText: 'Mandant eingeben',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildValidateTenantButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _validateTenant,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Schwarz statt Tenant-Farbe
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Mandant validieren',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
    ),
  );
}

  bool _shouldShowLoginTypeSelection() {
    if (_currentTenant == null) return false;
    
    bool phoneActive = _checkModuleActive(_currentTenant!, 'LoginPhonenumber');
    bool employeeActive = _checkModuleActive(_currentTenant!, 'LoginEmployeeNumber');
    
    // Nur anzeigen wenn beide Module verfügbar sind
    return phoneActive && employeeActive;
  }

  Widget _buildLoginTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLoginTypeOption(
              'phone',
              'Rufnummer',
              Icons.phone,
              _selectedLoginType == 'phone',
            ),
          ),
          Expanded(
            child: _buildLoginTypeOption(
              'employee',
              'Personalnummer',
              Icons.badge,
              _selectedLoginType == 'employee',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTypeOption(String type, String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLoginType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent, // Schwarz statt Tenant-Farbe
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        // Zurück-Button
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _tenantValidated = false;
                  _currentTenant = null;
                  _selectedLoginType = 'phone';
                  _otpSent = false;
                  // OTP-Controller leeren
                  for (var controller in _otpControllers) {
                    controller.clear();
                  }
                });
              },
              icon: Icon(Icons.arrow_back, size: 16),
              label: Text("Zurück zum Mandanten"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Schwarz statt Tenant-Farbe
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Länder-Code-Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              items: _countries.map((country) {
                return DropdownMenuItem<String>(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(
                        country['flag']!,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8),
                      Text(
                        country['name']!,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Text(
                        country['code']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCountryCode = newValue;
                    final country = _countries.firstWhere(
                      (c) => c['code'] == newValue,
                      orElse: () => _countries[0],
                    );
                    _selectedCountryFlag = country['flag']!;
                    _selectedCountryName = country['name']!;
                  });
                }
              },
            ),
          ),
        ),
        SizedBox(height: 12),
        // Telefonnummer-Eingabe
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Rufnummer',
            hintText: '123 456789',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeInput() {
    return TextField(
      controller: _employeeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Personalnummer',
        hintText: '12345',
        prefixIcon: Icon(Icons.badge),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        // Zurück-Button
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  // OTP-Controller leeren
                  for (var controller in _otpControllers) {
                    controller.clear();
                  }
                });
              },
              icon: Icon(Icons.arrow_back, size: 16),
              label: Text("Zurück zur Rufnummer"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Schwarz statt Tenant-Farbe
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Titel
        Text(
          "Geben Sie den 4-stelligen Code ein",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        // 4 Eingabefelder
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 1,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    counterText: "",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onChanged: (value) {
                    // Fokus auf das nächste Textfeld setzen
                    if (value.isNotEmpty && index < 3) {
                      _otpFocusNodes[index + 1].requestFocus();
                    }
                    // Fokus auf das vorherige Textfeld setzen bei Backspace
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 16),
        // Code erneut senden Button
        TextButton.icon(
          onPressed: _isLoading ? null : _resendOtp,
          icon: Icon(Icons.refresh, size: 16),
          label: Text("Code erneut senden"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black, // Schwarz statt Tenant-Farbe
          ),
        ),
      ],
    );
  }

  Future<void> _resendOtp() async {
    // Tastatur schließen
    FocusScope.of(context).unfocus();
    
    // OTP-Felder leeren
    for (var controller in _otpControllers) {
      controller.clear();
    }
    
    // Zurück zur Rufnummer-Eingabe
    setState(() {
      _otpSent = false;
      _isLoading = false;
    });
    
    _showSuccess('Sie können die Rufnummer korrigieren und erneut senden');
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black, // Schwarz statt Tenant-Farbe
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _getLoginButtonText(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
    ),
  );
}

  String _getLoginButtonText() {
    if (_selectedLoginType == 'phone') {
      return _otpSent ? 'OTP Verifizieren' : 'OTP Senden';
    } else {
      return 'Einloggen';
    }
  }

  Future<void> _validateTenant() async {
    // Trim entfernt Leerzeichen vor und nach dem Text
    String mandantText = _mandantController.text.trim();
    
    if (mandantText.isEmpty) {
      _showError('Bitte Mandant eingeben');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://bus-dashboard.dxp.azure.neusta.cloud:7698/getTenants'));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> tenants = decoded['body'];
        
        for (var tenant in tenants) {
          if (tenant['name'] == mandantText) { // Verwende getrimmten Text
            await _storage.write(key: 'deviceCachedTenant', value: jsonEncode(tenant));
            GblTenant = tenant;
            
            // Debug: Zeige alle Module des Mandanten
            print('=== MANDANT DEBUG ===');
            print('Mandant: ${tenant['name']}');
            print('Modules: ${tenant['modules']}');
            
            // Prüfe Module direkt aus dem tenant-Objekt
            bool phoneActive = _checkModuleActive(tenant, 'LoginPhonenumber');
            bool employeeActive = _checkModuleActive(tenant, 'LoginEmployeeNumber');
            
            print('Phone Login Active: $phoneActive');
            print('Employee Login Active: $employeeActive');
            print('==================');
            
            setState(() {
              _currentTenant = tenant;
              _tenantValidated = true;
              _isLoading = false;
              
              // Setze Standard-Login-Typ basierend auf verfügbaren Modulen
              if (phoneActive && employeeActive) {
                // Beide Module aktiv - Standard auf Phone setzen
                _selectedLoginType = 'phone';
                print('Selected: Phone (both modules active)');
              } else if (phoneActive) {
                // Nur Phone-Login aktiv
                _selectedLoginType = 'phone';
                print('Selected: Phone (only phone module active)');
              } else if (employeeActive) {
                // Nur Employee-Login aktiv
                _selectedLoginType = 'employee';
                print('Selected: Employee (only employee module active)');
              } else {
                // Kein Modul aktiv - Fallback auf Phone (OTP SMS)
                _selectedLoginType = 'phone';
                print('Selected: Phone (fallback - no modules active)');
              }
            });
            
            String loginTypeText = _selectedLoginType == 'phone' ? 'Rufnummer' : 'Personalnummer';
            _showSuccess('Mandant erfolgreich validiert - Login über $loginTypeText');
            return;
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        _showError('Mandant nicht gefunden');
      } else {
        throw Exception('Failed to load tenants');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Fehler beim Laden der Mandanten: $e');
    }
  }

  bool _checkModuleActive(Map<String, dynamic> tenant, String moduleName) {
    List<dynamic> modules = tenant['modules'] ?? [];
    
    for (var module in modules) {
      if (module['module'] == moduleName && module['active'] == true) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _handleLogin() async {
    if (!_tenantValidated) {
      _showError('Bitte zuerst Mandant validieren');
      return;
    }

    if (_selectedLoginType == 'phone') {
      await _handlePhoneLogin();
    } else {
      await _handleEmployeeLogin();
    }
  }

  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.isEmpty) {
      _showError('Bitte Rufnummer eingeben');
      return;
    }

    if (!_otpSent) {
      // Tastatur schließen vor OTP senden
      FocusScope.of(context).unfocus();
      
      // OTP senden
      setState(() {
        _isLoading = true;
      });

      try {
        await _sendOtp();
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _showSuccess('OTP wurde gesendet');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showError('Fehler beim Senden des OTP: $e');
      }
    } else {
      // OTP verifizieren
      String enteredCode = _otpControllers.map((controller) => controller.text).join();
      if (enteredCode.isEmpty) {
        _showError('Bitte OTP eingeben');
        return;
      }

      // Tastatur schließen vor OTP verifizieren
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
      });

      try {
        await _verifyOtp();
        await _completeLogin();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showError('Fehler bei OTP-Verifizierung: $e');
      }
    }
  }

  Future<void> _handleEmployeeLogin() async {
    if (_employeeController.text.isEmpty) {
      _showError('Bitte Personalnummer eingeben');
      return;
    }

    // Tastatur schließen vor Employee Login
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Keine API-Validierung für Personalnummer - direkt speichern
      await _completeLogin();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Fehler beim Login: $e');
    }
  }

  Future<void> _sendOtp() async {
    // Generiere 4-stelligen Code
    final random = Random();
    verificationCodeGbl = (1000 + random.nextInt(9000)).toString();
    AuthCode = verificationCodeGbl;
    
    print('Generated OTP Code: $verificationCodeGbl');
    
    // Setze Telefonnummer zusammen
    String phoneNumber = _phoneController.text.replaceAll(' ', '').replaceAll('-', '');
    String fullPhoneNumber = _selectedCountryCode + phoneNumber;
    
    // Bereite Telefonnummer für cm.com vor (+ durch 00 ersetzen)
    String phoneNumberForCM = fullPhoneNumber.replaceAll('+', '00');
    
    print('Sending SMS to: $phoneNumberForCM (Full: $fullPhoneNumber) with code: $verificationCodeGbl');
    
    // cm.com SMS API Call
    final url = Uri.parse('https://gw.messaging.cm.com/v1.0/message');
    final headers = {
      'accept': 'application/json',
      'content-type': 'application/json',
      'X-CM-PRODUCTTOKEN': '0aae9b97-db6e-4c8f-9c27-d10d0a63da1e',
    };
    final body = jsonEncode({
      "messages": {
        "msg": [
          {
            "from": "2FA",
            "to": [{"number": phoneNumberForCM}],
            "body": {
              "type": "auto",
              "content": "Dein Code lautet: $verificationCodeGbl"
            },
            "reference": "my_reference_${DateTime.now().millisecondsSinceEpoch}"
          }
        ]
      }
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      
      print('SMS Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to send SMS: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('SMS Error: $e');
      throw Exception('SMS sending failed: $e');
    }
  }

  Future<void> _verifyOtp() async {
    // Sammle den eingegebenen Code
    String enteredCode = _otpControllers.map((controller) => controller.text).join();
    
    print('Entered Code: "$enteredCode"');
    print('Generated Code: "$verificationCodeGbl"');
    print('Codes Match: ${enteredCode == verificationCodeGbl}');
    
    // Prüfe ob der eingegebene Code mit dem generierten übereinstimmt
    if (enteredCode != verificationCodeGbl) {
      throw Exception('Invalid OTP');
    }
  }

  Future<void> _loginWithEmployeeNumber() async {
    // API Call für Employee Login
    final response = await http.post(
      Uri.parse('${getUrl('employee-login')}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'mandant': _mandantController.text,
        'employeeNumber': _employeeController.text,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid employee number');
    }
  }

  Future<void> _completeLogin() async {
    // Mandant speichern
    await _storage.write(key: 'deviceCachedMandant', value: _mandantController.text.trim());
    MandantAuth = _mandantController.text.trim();

    // Phone/Employee speichern
    if (_selectedLoginType == 'phone') {
      // Vollständige Telefonnummer mit Länder-Code speichern (mit +)
      String phoneNumber = _phoneController.text.replaceAll(' ', '').replaceAll('-', '');
      String fullPhoneNumber = _selectedCountryCode + phoneNumber;
      
      await _storage.write(key: 'deviceCachedPhonenumber', value: fullPhoneNumber);
      PhoneNumberAuth = fullPhoneNumber; // Speichert mit + für die App
    } else {
      // Personalnummer direkt speichern
      String employeeNumber = _employeeController.text.trim();
      
      await _storage.write(key: 'deviceCachedPhonenumber', value: employeeNumber);
      PhoneNumberAuth = employeeNumber; // Speichert Personalnummer in PhoneNumberAuth
    }

    setState(() {
      _isLoading = false;
    });

    // Zur LandingPage navigieren
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LandingPage(
          title: 'BusDesk Pro',
          phonenumber: PhoneNumberAuth,
          mandant: _mandantController.text.trim(),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Hilfsmethode für sichere Farb-Abfrage
Color _getPrimaryColor() {
  try {
    if (GblTenant != null) {
      return HexColor.fromHex(getColor('primary'));
    }
  } catch (e) {
    print('Error getting primary color: $e');
  }
  // Fallback-Farbe
  return Colors.black;
}
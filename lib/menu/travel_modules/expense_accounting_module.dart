import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class ExpenseAccountingModule {
  static void showExpenseAccountingPopup(BuildContext context, Map<String, dynamic> travel, {int initialTab = 0}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.95,
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
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spesenabrechnung',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (travel['ReiseText'] != null)
                              Text(
                                travel['ReiseText'],
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
                // Content with Tabs
                Expanded(
                  child: DefaultTabController(
                    initialIndex: initialTab,
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey[100],
                          child: TabBar(
                            labelColor: HexColor.fromHex(getColor('primary')),
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: HexColor.fromHex(getColor('primary')),
                            indicatorWeight: 3,
                            tabs: [
                              Tab(
                                icon: Icon(Icons.camera_alt_rounded),
                                text: 'Belegerfassung',
                              ),
                              Tab(
                                icon: Icon(Icons.calculate_rounded),
                                text: 'Abrechnung',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildReceiptCaptureTab(context, travel),
                              _buildAccountingTab(context, travel),
                            ],
                          ),
                        ),
                      ],
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

  static Widget _buildReceiptCaptureTab(BuildContext context, Map<String, dynamic> travel) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Box
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue[700],
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erfassen Sie hier alle Belege für Ihre Spesen und Ausgaben während der Reise. Sie können Fotos von Belegen machen oder Dateien hochladen.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Upload Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 40,
                          color: Colors.grey[500],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belege hier hochladen',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'oder klicken zum Auswählen',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement file picker
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Datei-Auswahl wird implementiert...')),
                            );
                          },
                          icon: Icon(Icons.add_photo_alternate_rounded, size: 16),
                          label: Text('Beleg hinzufügen', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Uploaded Receipts List
                  Text(
                    'Erfasste Belege',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  // Placeholder for uploaded receipts
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_outlined, color: Colors.grey[400], size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Noch keine Belege erfasst',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAccountingTab(BuildContext context, Map<String, dynamic> travel) {
    return _AccountingTabStateful(travel: travel);
  }

  static Widget _buildFormSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        child,
      ],
    );
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  static String _calculateEndDate(String? startDate, int? duration) {
    if (startDate == null || duration == null) return '';
    try {
      final start = DateTime.parse(startDate);
      final end = start.add(Duration(days: duration));
      return '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';
    } catch (e) {
      return '';
    }
  }

  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  static Widget _buildCollapsibleReiseSection(Map<String, dynamic> travel) {
    return _CollapsibleReiseSection(travel: travel);
  }
}

// Separate StatefulWidget für einklappbare Reise-Sektion
class _CollapsibleReiseSection extends StatefulWidget {
  final Map<String, dynamic> travel;

  const _CollapsibleReiseSection({required this.travel});

  @override
  State<_CollapsibleReiseSection> createState() => _CollapsibleReiseSectionState();
}

class _CollapsibleReiseSectionState extends State<_CollapsibleReiseSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reise',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${widget.travel['ReiseText'] ?? ''} • ${ExpenseAccountingModule._formatDate(widget.travel['Reisebeginn'])} - ${ExpenseAccountingModule._calculateEndDate(widget.travel['Reisebeginn'], widget.travel['Dauer'])}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
              if (isExpanded) ...[
                Divider(height: 1, color: Colors.grey[300]),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(text: widget.travel['ReiseText'] ?? ''),
                        decoration: InputDecoration(
                          labelText: 'Reise',
                          hintText: 'Reisebezeichnung',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: ExpenseAccountingModule._formatDate(widget.travel['Reisebeginn'])),
                              decoration: InputDecoration(
                                labelText: 'Von',
                                hintText: 'TT.MM.JJJJ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: ExpenseAccountingModule._calculateEndDate(widget.travel['Reisebeginn'], widget.travel['Dauer']),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Bis',
                                hintText: 'TT.MM.JJJJ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: widget.travel['DSNummer']?.toString() ?? ''),
                        decoration: InputDecoration(
                          labelText: 'Reisenummer',
                          hintText: 'Reisenummer',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
  }
}

// Separate StatefulWidget für Accounting Tab mit State-Management
class _AccountingTabStateful extends StatefulWidget {
  final Map<String, dynamic> travel;

  const _AccountingTabStateful({required this.travel});

  @override
  State<_AccountingTabStateful> createState() => _AccountingTabStatefulState();
}

class _AccountingTabStatefulState extends State<_AccountingTabStateful> {
  late List<Map<String, TextEditingController>> tagessatzList;
  late List<Map<String, TextEditingController>> spesenList;
  double subtotal = 0;
  double vat = 0;
  double grandTotal = 0;

  @override
  void initState() {
    super.initState();
    tagessatzList = [
      {
        'rate': TextEditingController(),
        'days': TextEditingController(text: widget.travel['Dauer']?.toString() ?? ''),
      }
    ];
    spesenList = [
      {
        'rate': TextEditingController(),
        'days': TextEditingController(text: widget.travel['Dauer']?.toString() ?? ''),
      }
    ];
    
    // Listener für automatische Berechnung
    for (var item in tagessatzList) {
      item['rate']!.addListener(_calculateTotals);
      item['days']!.addListener(_calculateTotals);
    }
    for (var item in spesenList) {
      item['rate']!.addListener(_calculateTotals);
      item['days']!.addListener(_calculateTotals);
    }
    _calculateTotals();
  }

  @override
  void dispose() {
    for (var item in tagessatzList) {
      item['rate']!.dispose();
      item['days']!.dispose();
    }
    for (var item in spesenList) {
      item['rate']!.dispose();
      item['days']!.dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double tagessatzTotal = 0;
    for (var item in tagessatzList) {
      final rate = double.tryParse(item['rate']!.text.replaceAll(',', '.')) ?? 0;
      final days = int.tryParse(item['days']!.text) ?? 0;
      tagessatzTotal += rate * days;
    }

    double spesenTotal = 0;
    for (var item in spesenList) {
      final rate = double.tryParse(item['rate']!.text.replaceAll(',', '.')) ?? 0;
      final days = int.tryParse(item['days']!.text) ?? 0;
      spesenTotal += rate * days;
    }

    setState(() {
      subtotal = tagessatzTotal + spesenTotal;
      vat = subtotal * 0.19;
      grandTotal = subtotal + vat;
    });
  }

  void _addTagessatz() {
    setState(() {
      final newItem = {
        'rate': TextEditingController(),
        'days': TextEditingController(text: widget.travel['Dauer']?.toString() ?? ''),
      };
      newItem['rate']!.addListener(_calculateTotals);
      newItem['days']!.addListener(_calculateTotals);
      tagessatzList.add(newItem);
    });
  }

  void _removeTagessatz(int index) {
    if (tagessatzList.length > 1) {
      setState(() {
        tagessatzList[index]['rate']!.dispose();
        tagessatzList[index]['days']!.dispose();
        tagessatzList.removeAt(index);
        _calculateTotals();
      });
    }
  }

  void _addSpesen() {
    setState(() {
      final newItem = {
        'rate': TextEditingController(),
        'days': TextEditingController(text: widget.travel['Dauer']?.toString() ?? ''),
      };
      newItem['rate']!.addListener(_calculateTotals);
      newItem['days']!.addListener(_calculateTotals);
      spesenList.add(newItem);
    });
  }

  void _removeSpesen(int index) {
    if (spesenList.length > 1) {
      setState(() {
        spesenList[index]['rate']!.dispose();
        spesenList[index]['days']!.dispose();
        spesenList.removeAt(index);
        _calculateTotals();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reiseleitung
                  ExpenseAccountingModule._buildFormSection(
                    title: 'Reiseleitung',
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Name der Reiseleitung',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Reise Info - Einklappbar
                  ExpenseAccountingModule._buildCollapsibleReiseSection(widget.travel),
                  SizedBox(height: 28),
                  // Tagessatz
                  ExpenseAccountingModule._buildFormSection(
                    title: 'Tagessatz',
                    child: Column(
                      children: [
                        ...tagessatzList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final rate = double.tryParse(item['rate']!.text.replaceAll(',', '.')) ?? 0;
                          final days = int.tryParse(item['days']!.text) ?? 0;
                          final total = rate * days;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: item['rate'],
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Tagessatz (€)',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: item['days'],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Anzahl Tage',
                                    hintText: widget.travel['Dauer']?.toString() ?? '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Gesamt',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              ExpenseAccountingModule._formatCurrency(total),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (tagessatzList.length > 1) ...[
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeTagessatz(index),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addTagessatz,
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Tagessatz hinzufügen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  // Spesenpauschale
                  ExpenseAccountingModule._buildFormSection(
                    title: 'Spesenpauschale für Verpflegungskosten',
                    child: Column(
                      children: [
                        ...spesenList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final rate = double.tryParse(item['rate']!.text.replaceAll(',', '.')) ?? 0;
                          final days = int.tryParse(item['days']!.text) ?? 0;
                          final total = rate * days;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: item['rate'],
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Tagessatz (€)',
                                    hintText: '0.00',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                SizedBox(height: 12),
                                TextField(
                                  controller: item['days'],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Anzahl Tage',
                                    hintText: widget.travel['Dauer']?.toString() ?? '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Gesamt',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              ExpenseAccountingModule._formatCurrency(total),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (spesenList.length > 1) ...[
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _removeSpesen(index),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addSpesen,
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Spesenpauschale hinzufügen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HexColor.fromHex(getColor('primary')),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Summary
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Zwischensumme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              ExpenseAccountingModule._formatCurrency(subtotal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '19 % UST',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              ExpenseAccountingModule._formatCurrency(vat),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gesamt',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                            Text(
                              ExpenseAccountingModule._formatCurrency(grandTotal),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: HexColor.fromHex(getColor('primary')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Abrechnung wird gespeichert...')),
                        );
                      },
                      icon: Icon(Icons.save_rounded),
                      label: Text('Speichern'),
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
          ),
        ],
      ),
    );
  }
}


import 'package:intl/intl.dart';

class ExampleTravelsData {
  // Berechnet automatisch den Status basierend auf Reisebeginn und Dauer
  static String calculateTravelStatus(String reisebeginn, int dauer) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      final beginn = DateTime.parse(reisebeginn);
      final beginnDate = DateTime(beginn.year, beginn.month, beginn.day);
      final endeDate = beginnDate.add(Duration(days: dauer - 1));
      
      // Vergangene: Reiseende liegt in der Vergangenheit
      if (endeDate.isBefore(today)) {
        return 'Vergangene';
      }
      
      // Zukünftige: Reisebeginn liegt in der Zukunft
      if (beginnDate.isAfter(today)) {
        return 'Zukünftige';
      }
      
      // Aktuelle: Reisebeginn liegt heute oder in der Vergangenheit, aber Reiseende liegt heute oder in der Zukunft
      return 'Aktuelle';
    } catch (e) {
      // Fallback bei Parsing-Fehler
      return 'Aktuelle';
    }
  }
  
  static List<Map<String, dynamic>> generateExampleTravels() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final travels = [
      // Aktuelle Reisen
      {
        'DSNummer': 11000135,
        'ReiseKuerzel': 'BER2024-W',
        'ReiseKuerzelMFG': 'BER-W-01',
        'ReiseText': 'Berlin - Die pulsierende Hauptstadt',
        'ReiseArt': 'Städtereise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=400',
        'Reisebeginn': dateFormat.format(now.subtract(Duration(days: 1))), // Gestern begonnen
        'Dauer': 4,
        'PreisAb': 599.00,
        'Hotels': [
          {
            'Name': 'Hotel Adlon Kempinski',
            'DatumVon': dateFormat.format(now.subtract(Duration(days: 1))),
            'DatumBis': dateFormat.format(now.add(Duration(days: 2)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Brandenburger Tor, Reichstag'},
          {'Tag': 'Tag 2: Museumsinsel, Berliner Dom, Alexanderplatz'},
          {'Tag': 'Tag 3: Checkpoint Charlie, East Side Gallery, Potsdamer Platz'},
          {'Tag': 'Tag 4: KaDeWe Shopping und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10001,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Mustermann',
            'Vorname': 'Max',
            'Geschlecht': 'M',
            'GeburtsDatum': '1975-03-15',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'max.mustermann@email.de',
            'Telefon': '030 12345678',
            'Mobile': '0170 1234567',
            'room': 'Zimmer 205',
            'roomType': 'Einzelzimmer',
          },
          {
            'Kundennummer': 10002,
            'Unternummer': 1,
            'Anrede': 'Frau',
            'Name': 'Schmidt',
            'Vorname': 'Anna',
            'Geschlecht': 'W',
            'GeburtsDatum': '1982-07-22',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'anna.schmidt@email.de',
            'Telefon': '030 98765432',
            'Mobile': '0171 9876543',
            'room': 'Zimmer 206',
            'roomType': 'Einzelzimmer',
          },
          {
            'Kundennummer': 10007,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Becker',
            'Vorname': 'Stefan',
            'Geschlecht': 'M',
            'GeburtsDatum': '1990-01-10',
            'Unterkunft': 1,
            'UKBelegung': 2,
            'Zimmertyp': 2,
            'Email': 'stefan.becker@email.de',
            'Telefon': '030 44444444',
            'Mobile': '0176 4444444',
            'room': 'Zimmer 310',
            'roomType': 'Doppelzimmer',
          },
          {
            'Kundennummer': 10007,
            'Unternummer': 2,
            'Anrede': 'Frau',
            'Name': 'Becker',
            'Vorname': 'Lisa',
            'Geschlecht': 'W',
            'GeburtsDatum': '1992-06-25',
            'Unterkunft': 1,
            'UKBelegung': 2,
            'Zimmertyp': 2,
            'Email': 'lisa.becker@email.de',
            'Telefon': '030 44444444',
            'Mobile': '0176 5555555',
            'room': 'Zimmer 310',
            'roomType': 'Doppelzimmer',
          },
        ],
      },
      {
        'DSNummer': 11000142,
        'ReiseKuerzel': 'MUC2024-K',
        'ReiseKuerzelMFG': 'MUC-K-03',
        'ReiseText': 'München - Oktoberfest und Alpenblick',
        'ReiseArt': 'Erlebnisreise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1595867818082-083862f3d630?w=400',
        'Reisebeginn': dateFormat.format(now), // Heute begonnen
        'Dauer': 5,
        'PreisAb': 749.00,
        'Hotels': [
          {
            'Name': 'Hotel Bayerischer Hof',
            'DatumVon': dateFormat.format(now),
            'DatumBis': dateFormat.format(now.add(Duration(days: 4)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Marienplatz, Viktualienmarkt'},
          {'Tag': 'Tag 2: Schloss Nymphenburg, Olympiapark'},
          {'Tag': 'Tag 3: Deutsches Museum, Englischer Garten'},
          {'Tag': 'Tag 4: Tagesausflug Schloss Neuschwanstein'},
          {'Tag': 'Tag 5: BMW Welt, Shopping und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10003,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Müller',
            'Vorname': 'Peter',
            'Geschlecht': 'M',
            'GeburtsDatum': '1980-08-14',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'peter.mueller@email.de',
            'Telefon': '089 22222222',
            'Mobile': '0172 2222222',
            'room': 'Zimmer 415',
            'roomType': 'Einzelzimmer',
          },
        ],
      },
      // Zukünftige Reisen
      {
        'DSNummer': 11000158,
        'ReiseKuerzel': 'HAM2025-H',
        'ReiseKuerzelMFG': 'HAM-H-02',
        'ReiseText': 'Hamburg - Maritimes Flair an der Elbe',
        'ReiseArt': 'Städtereise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1585297099357-f48e6c3a6eff?w=400',
        'Reisebeginn': dateFormat.format(now.add(Duration(days: 30))),
        'Dauer': 3,
        'PreisAb': 529.00,
        'Hotels': [
          {
            'Name': 'The Westin Hamburg',
            'DatumVon': dateFormat.format(now.add(Duration(days: 30))),
            'DatumBis': dateFormat.format(now.add(Duration(days: 32)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Speicherstadt, HafenCity'},
          {'Tag': 'Tag 2: Elbphilharmonie, Miniatur Wunderland, Reeperbahn'},
          {'Tag': 'Tag 3: Alster-Rundfahrt, Fischmarkt und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10004,
            'Unternummer': 1,
            'Anrede': 'Frau',
            'Name': 'Meyer',
            'Vorname': 'Julia',
            'Geschlecht': 'W',
            'GeburtsDatum': '1985-09-30',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'julia.meyer@email.de',
            'Telefon': '040 77777777',
            'Mobile': '0173 7777777',
            'room': 'Zimmer 512',
            'roomType': 'Einzelzimmer',
          },
          {
            'Kundennummer': 10008,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Koch',
            'Vorname': 'Andreas',
            'Geschlecht': 'M',
            'GeburtsDatum': '1988-02-28',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'andreas.koch@email.de',
            'Telefon': '040 66666666',
            'Mobile': '0177 6666666',
            'room': 'Zimmer 513',
            'roomType': 'Einzelzimmer',
          },
        ],
      },
      {
        'DSNummer': 11000172,
        'ReiseKuerzel': 'FRA2025-M',
        'ReiseKuerzelMFG': 'FRA-M-04',
        'ReiseText': 'Frankfurt - Skyline und Finanzmetropole',
        'ReiseArt': 'Business-Reise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1564221710304-0b37c8b9d729?w=400',
        'Reisebeginn': dateFormat.format(now.add(Duration(days: 45))),
        'Dauer': 2,
        'PreisAb': 399.00,
        'Hotels': [
          {
            'Name': 'Jumeirah Frankfurt',
            'DatumVon': dateFormat.format(now.add(Duration(days: 45))),
            'DatumBis': dateFormat.format(now.add(Duration(days: 46)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Römerberg, Maintower'},
          {'Tag': 'Tag 2: Palmengarten, Museumsufer und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10009,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Wagner',
            'Vorname': 'Daniel',
            'Geschlecht': 'M',
            'GeburtsDatum': '1983-11-20',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'daniel.wagner@email.de',
            'Telefon': '069 33333333',
            'Mobile': '0178 3333333',
            'room': 'Zimmer 720',
            'roomType': 'Business-Zimmer',
          },
        ],
      },
      // Vergangene Reisen
      {
        'DSNummer': 11000098,
        'ReiseKuerzel': 'DRE2024-K',
        'ReiseKuerzelMFG': 'DRE-K-01',
        'ReiseText': 'Dresden - Barockes Juwel an der Elbe',
        'ReiseArt': 'Kulturreise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1599946347371-68eb71b16afc?w=400',
        'Reisebeginn': dateFormat.format(now.subtract(Duration(days: 14))),
        'Dauer': 3,
        'PreisAb': 479.00,
        'Hotels': [
          {
            'Name': 'Hotel Taschenbergpalais',
            'DatumVon': dateFormat.format(now.subtract(Duration(days: 14))),
            'DatumBis': dateFormat.format(now.subtract(Duration(days: 12)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Frauenkirche und Semperoper'},
          {'Tag': 'Tag 2: Zwinger, Residenzschloss und Brühlsche Terrasse'},
          {'Tag': 'Tag 3: Elbschlösser und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10006,
            'Unternummer': 1,
            'Anrede': 'Frau',
            'Name': 'Fischer',
            'Vorname': 'Sabine',
            'Geschlecht': 'W',
            'GeburtsDatum': '1972-12-03',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'sabine.fischer@email.de',
            'Telefon': '0351 99999999',
            'Mobile': '0175 9999999',
            'room': 'Zimmer 215',
            'roomType': 'Einzelzimmer',
          },
          {
            'Kundennummer': 10010,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Hoffmann',
            'Vorname': 'Klaus',
            'Geschlecht': 'M',
            'GeburtsDatum': '1965-05-17',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'klaus.hoffmann@email.de',
            'Telefon': '0351 88888888',
            'Mobile': '0179 8888888',
            'room': 'Zimmer 216',
            'roomType': 'Einzelzimmer',
          },
        ],
      },
      {
        'DSNummer': 11000089,
        'ReiseKuerzel': 'HEI2024-A',
        'ReiseKuerzelMFG': 'HEI-A-02',
        'ReiseText': 'Heidelberg - Romantik am Neckar',
        'ReiseArt': 'Kulturreise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1580674285054-bed31e145f59?w=400',
        'Reisebeginn': dateFormat.format(now.subtract(Duration(days: 7))),
        'Dauer': 2,
        'PreisAb': 349.00,
        'Hotels': [
          {
            'Name': 'Hotel Europäischer Hof',
            'DatumVon': dateFormat.format(now.subtract(Duration(days: 7))),
            'DatumBis': dateFormat.format(now.subtract(Duration(days: 6)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Heidelberger Schloss, Altstadt'},
          {'Tag': 'Tag 2: Philosophenweg, Neckar-Rundfahrt und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10011,
            'Unternummer': 1,
            'Anrede': 'Frau',
            'Name': 'Richter',
            'Vorname': 'Monika',
            'Geschlecht': 'W',
            'GeburtsDatum': '1977-09-05',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'monika.richter@email.de',
            'Telefon': '06221 77777777',
            'Mobile': '0180 7777777',
            'room': 'Zimmer 102',
            'roomType': 'Einzelzimmer',
          },
        ],
      },
      // Weitere aktuelle Reise
      {
        'DSNummer': 11000201,
        'ReiseKuerzel': 'KOE2024-R',
        'ReiseKuerzelMFG': 'KOE-R-05',
        'ReiseText': 'Köln - Dom und Rheinromantik',
        'ReiseArt': 'Städtereise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1513581166391-887a96ddeafd?w=400',
        'Reisebeginn': dateFormat.format(now.add(Duration(days: 1))),
        'Dauer': 3,
        'PreisAb': 449.00,
        'Hotels': [
          {
            'Name': 'Excelsior Hotel Ernst',
            'DatumVon': dateFormat.format(now.add(Duration(days: 1))),
            'DatumBis': dateFormat.format(now.add(Duration(days: 3)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Kölner Dom, Altstadt'},
          {'Tag': 'Tag 2: Schokoladenmuseum, Rheinufer-Promenade'},
          {'Tag': 'Tag 3: Rheinschifffahrt und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10012,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Weber',
            'Vorname': 'Thomas',
            'Geschlecht': 'M',
            'GeburtsDatum': '1978-04-12',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'thomas.weber@email.de',
            'Telefon': '0221 55555555',
            'Mobile': '0174 5555555',
            'room': 'Zimmer 408',
            'roomType': 'Einzelzimmer',
          },
          {
            'Kundennummer': 10013,
            'Unternummer': 1,
            'Anrede': 'Frau',
            'Name': 'Schneider',
            'Vorname': 'Maria',
            'Geschlecht': 'W',
            'GeburtsDatum': '1984-11-08',
            'Unterkunft': 1,
            'UKBelegung': 1,
            'Zimmertyp': 1,
            'Email': 'maria.schneider@email.de',
            'Telefon': '0221 66666666',
            'Mobile': '0175 6666666',
            'room': 'Zimmer 409',
            'roomType': 'Einzelzimmer',
          },
        ],
      },
      // Weitere zukünftige Reise
      {
        'DSNummer': 11000215,
        'ReiseKuerzel': 'STU2025-W',
        'ReiseKuerzelMFG': 'STU-W-01',
        'ReiseText': 'Stuttgart - Automobilstadt und Weinberge',
        'ReiseArt': 'Erlebnisreise',
        'Land': 'Deutschland',
        'BildURL': 'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=400',
        'Reisebeginn': dateFormat.format(now.add(Duration(days: 60))),
        'Dauer': 4,
        'PreisAb': 679.00,
        'Hotels': [
          {
            'Name': 'Steigenberger Graf Zeppelin',
            'DatumVon': dateFormat.format(now.add(Duration(days: 60))),
            'DatumBis': dateFormat.format(now.add(Duration(days: 63)))
          },
        ],
        'Verlauf': [
          {'Tag': 'Tag 1: Anreise, Mercedes-Benz Museum'},
          {'Tag': 'Tag 2: Porsche Museum, Schlossplatz'},
          {'Tag': 'Tag 3: Weinwanderung, Fernsehturm'},
          {'Tag': 'Tag 4: Wilhelma Zoo und Abreise'},
        ],
        'participants': [
          {
            'Kundennummer': 10014,
            'Unternummer': 1,
            'Anrede': 'Herr',
            'Name': 'Schulz',
            'Vorname': 'Michael',
            'Geschlecht': 'M',
            'GeburtsDatum': '1986-07-19',
            'Unterkunft': 1,
            'UKBelegung': 2,
            'Zimmertyp': 2,
            'Email': 'michael.schulz@email.de',
            'Telefon': '0711 11111111',
            'Mobile': '0176 1111111',
            'room': 'Zimmer 601',
            'roomType': 'Doppelzimmer',
          },
          {
            'Kundennummer': 10014,
            'Unternummer': 2,
            'Anrede': 'Frau',
            'Name': 'Schulz',
            'Vorname': 'Sandra',
            'Geschlecht': 'W',
            'GeburtsDatum': '1989-03-25',
            'Unterkunft': 1,
            'UKBelegung': 2,
            'Zimmertyp': 2,
            'Email': 'sandra.schulz@email.de',
            'Telefon': '0711 11111111',
            'Mobile': '0177 2222222',
            'room': 'Zimmer 601',
            'roomType': 'Doppelzimmer',
          },
        ],
      },
    ];
    
    // Status für alle Reisen automatisch berechnen
    for (var travel in travels) {
      if (travel['Reisebeginn'] != null && travel['Dauer'] != null) {
        travel['status'] = calculateTravelStatus(
          travel['Reisebeginn'].toString(),
          travel['Dauer'] as int,
        );
      }
    }
    
    return travels;
  }
  
  // Hilfsmethode für Teilnehmer-Namen (unterstützt beide Formate)
  static String getParticipantName(Map<String, dynamic> participant) {
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
}


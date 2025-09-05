/*
 * Copyright (C) 2019-2025 HERE Europe B.V.
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * License-Filename: LICENSE
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/consent.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/maploader.dart';
import 'package:here_sdk/routing.dart' as Routing;
import 'package:here_sdk/search.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bus_desk_pro/maps/here/AppLogic.dart';
import 'package:bus_desk_pro/maps/here/HEREPositioningTermsAndPrivacyHelper.dart';

import 'here_new/common/application_preferences.dart';
import 'here_new/common/custom_map_style_settings.dart';
import 'here_new/common/ui_style.dart';
import 'here_new/download_maps/download_maps_screen.dart';
import 'here_new/download_maps/map_loader_controller.dart';
import 'here_new/download_maps/map_regions_list_screen.dart';
import 'here_new/landing_screen.dart';
import 'here_new/navigation/navigation_screen.dart';
import 'here_new/positioning/positioning_engine.dart';
import 'here_new/route_preferences/route_preferences_model.dart';
import 'here_new/routing/route_details_screen.dart';
import 'here_new/routing/routing_screen.dart';
import 'here_new/routing/waypoint_info.dart';
import 'here_new/routing/waypoints_controller.dart';
import 'here_new/search/recent_search_data_model.dart';
import 'here_new/search/search_results_screen.dart';
import 'environment.dart';
import 'here_new/positioning/no_location_warning_widget.dart';
import 'here_new/positioning/positioning.dart';
import 'here_new/positioning/positioning_engine.dart';

/// Application root widget.
class MapsEngine extends StatefulWidget {
  final double? lat;
  final double? long;
  final List? stop_;
  final bool? isFreeDrive;

  const MapsEngine({super.key, this.lat, this.long, this.stop_, this.isFreeDrive});

  @override
  State<MapsEngine> createState() => _SdkEmbeddedScreenState();
}

class _SdkEmbeddedScreenState extends State<MapsEngine> {

  Position? pos;

  Timer? _checkTimer;

  ConsentUserReply? _consentState;

  @override
  void initState() {
    //_initPos();
    super.initState();
    _startCheckingForPosition();

  }

  Future<void> _initPos() async {
    pos = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startCheckingForPosition() {
    _checkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (currentPosition != null) {
        timer.cancel();
        setState(() {}); // rebuilds with currentPosition
      }
    });
  }

  Future<Widget> getStartScreen() async {
    final _storage = FlutterSecureStorage();
    var consent = await _storage.read(key: 'HERESDKConsent');
    if (consent != 'true') {
      return LandingScreen();
    } else {
      return RoutingScreen(
          currentPosition: GeoCoordinates(currentPosition!.latitude, currentPosition!.longitude),
          departure: WayPointInfo(coordinates: GeoCoordinates(currentPosition!.latitude, currentPosition!.longitude)),
          destination: WayPointInfo(coordinates: GeoCoordinates(double.parse(GblStops[currentStoppIndex]['lat']), double.parse(GblStops[currentStoppIndex]['long']))),
          startNavigationDirectly: true,
          isTruckRoute: true
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecentSearchDataModel()),
        ChangeNotifierProvider(create: (context) => RoutePreferencesModel.withDefaults()),
        ChangeNotifierProvider(create: (context) => MapLoaderController()),
        ChangeNotifierProvider(create: (context) => AppPreferences()),
        Provider(create: (context) => PositioningEngine()),
        ChangeNotifierProvider(create: (context) => CustomMapStyleSettings()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de', '')],
        theme: UIStyle.lightTheme,
        onGenerateTitle: (BuildContext context) =>
        AppLocalizations.of(context)!.appTitle,
        onGenerateRoute: (RouteSettings settings) {
          final routes = <String, WidgetBuilder>{
            LandingScreen.navRoute: (_) {
              if (currentPosition != null) {
                return FutureBuilder<Widget>(
                  future: getStartScreen(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Prüfe Datenschutzeinwilligung und starte Tour...'),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return snapshot.data ?? SizedBox(); // your async widget
                    }
                  },
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                            'GPS Positionsermittlung läuft...\n\n Benötigt die Übermittlung mehr als 30 Sekunden, kann es folgende Ursachen geben: \n\n 1. Berechtigung zum Standort wurde erst bei diesem App- Start gesetzt. Die App muss einmal neu gestartet werden.\n\n 2. Schlechte GPS -Verbindung',
                            textAlign: TextAlign.center
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            SearchResultsScreen.navRoute: (_) {
              final args = settings.arguments as List<dynamic>;
              return SearchResultsScreen(
                queryString: args[0],
                places: args[1],
                currentPosition: args[2],
                isRecentSearchResult: args[3],
              );
            },
            RoutingScreen.navRoute: (_) {
              final args = settings.arguments as List<dynamic>;
              return RoutingScreen(
                currentPosition: args[0],
                departure: args[1],
                destination: args[2],
              );
            },
            RouteDetailsScreen.navRoute: (_) {
              final args = settings.arguments as List<dynamic>;
              return RouteDetailsScreen(
                route: args[0],
                wayPointsController: args[1],
              );
            },
            NavigationScreen.navRoute: (_) {
              final args = settings.arguments as List<dynamic>;
              return NavigationScreen(
                route: args[0],
                wayPoints: args[1],
              );
            },
            DownloadMapsScreen.navRoute: (_) => DownloadMapsScreen(),
            MapRegionsListScreen.navRoute: (_) {
              final args = settings.arguments as List<dynamic>;
              return MapRegionsListScreen(regions: args[0]);
            },
          };

          final builder = routes[settings.name];
          if (builder != null) {
            return MaterialPageRoute(
              builder: (ctx) => builder(ctx),
              settings: settings,
            );
          }
          throw Exception("Unknown route: ${settings.name}");
        },
        initialRoute: LandingScreen.navRoute,
      ),
    );
  }
}

/*class InitErrorScreen extends StatelessWidget {
  const InitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(UIStyle.contentMarginExtraHuge),
                child: Text(
                  AppLocalizations.of(context)!.sdkInitFailError,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          );
        },
      ),
      theme: UIStyle.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
    );
  }
}*/

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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bus_desk_pro/maps/here/AppLogic.dart';
import 'package:bus_desk_pro/maps/here/HEREPositioningTermsAndPrivacyHelper.dart';

class SampleNavigationApp2 extends StatefulWidget {
  final double? lat;
  final double? long;
  final List? stop_;
  final bool? isFreeDrive;

  const SampleNavigationApp2({super.key, this.lat, this.long, this.stop_, this.isFreeDrive});

  @override
  State<SampleNavigationApp2> createState() => _MyAppState();
}

class _MyAppState extends State<SampleNavigationApp2> with WidgetsBindingObserver {
  late AppLogic _appLogic;
  late final AppLifecycleListener _listener;
  String _messageState = "";
  bool _reroutingInProgress = false;
  late int _remainingDistanceInMeters;
  late int _remainingDurationInSeconds;
  int? _currentManeuverIndex;
  int _currentManeuverDistance = 0;
  int? _nextManeuverIndex;
  int _nextManeuverDistance = 0;
  String? _currentStreetName;
  double? _currentSpeedLimit;
  double? _currentSpeed;
  static const double _kDistanceToShowNextManeuver = 500;

  Future<bool> _handleBackPress() async {
    // Handle the back press.
    _appLogic?.detach();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        appBar: AppBar(
          title: Text("HERE SDK - Navigation Example"),
        ),
        body: Stack(
          children: [
            HereMap(
                //key: GlobalKey(),
                //options: options,
                onMapCreated: _onMapCreated
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    button("Start with HERE Positioning", _startNavigationButtonClicked),
                  ],
                ),
                messageStateWidget(_messageState),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) async {
      if (error == null) {
        if (Platform.isAndroid) {
          final termsAndPrivacyHelper = HEREPositioningTermsAndPrivacyHelper(context);
          await termsAndPrivacyHelper.showAppTermsAndPrivacyPolicyDialogIfNeeded();
        }
        if (!await _requestPermissions()) {
          await _showDialog("Fehler", "Kann kann nicht geöffnet werden. Auf dem Gerät wurden App-Berechtigungen nicht gesetzt oder Standortzugriff ist nicht erlaubt.");
          openAppSettings();
          SystemNavigator.pop();
          return;
        }
        _appLogic = AppLogic(hereMapController, _updateMessageState, _showDialog);
      } else {
        print("Karte kann nicht geladen werden: " + error.toString());
      }
    });
  }

  Future<bool> _requestPermissions() async {
    if (!await Permission.location.serviceStatus.isEnabled) {
      return false;
    }
    if (!await Permission.location.request().isGranted) {
      return false;
    }
    if (Platform.isAndroid) {
      Permission.activityRecognition.request();
    }
    return true;
  }

  // Update the message text state and show selected log messages.
  void _updateMessageState(String messageState) {
    setState(() {
      _messageState = messageState;
      print(messageState);
    });
  }

  void _startNavigationButtonClicked() {
    if (_appLogic != null) {
      _appLogic.startNavigation(widget.lat??0, widget.long??0, "");
    }
  }

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onDetach: () =>
      { print('AppLifecycleListener detached.'), _disposeHERESDK() },
    );
  }

  @override
  void dispose() {
    _disposeHERESDK();
    super.dispose();
  }

  void _disposeHERESDK() async {
    WidgetsBinding.instance!.removeObserver(this);
    await SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    _listener.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && _appLogic != null) {
      _appLogic.detach();
    }
  }

  Align button(String buttonLabel, VoidCallback? callbackFunction) {
    return Align(
      alignment: Alignment.topCenter,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: callbackFunction,
        child: Text(buttonLabel, style: TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget messageStateWidget(String messageState) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          messageState,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ),
      color: Colors.white,
      margin: EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0),
    );
  }

  // A helper method to show a dialog.
  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

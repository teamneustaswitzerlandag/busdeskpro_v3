library busdeskpro.popup;

import 'package:bus_desk_pro/libaries/countdown_loader.dart';
import 'package:flutter/material.dart';

Future<void> showCustomDialog(context, String headline, String message, List<Widget> buttons) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(headline),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: buttons,
      );
    },
  );
}

Future<void> showCustomDialog2(context, String headline, String message, List<Widget> buttons, int countdown) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(headline),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8.0),
                    CountdownLoader(
                      countdownStart: countdown, // Startwert für den Countdown
                      circleColor: Colors.black, // Farbe des Kreises
                      textColor: Colors.black, // Farbe des Textes
                      strokeWidth: 6.0, // Breite des Kreises
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: buttons,
      );
    },
  );
}
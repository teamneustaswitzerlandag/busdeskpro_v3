import 'package:flutter/material.dart';
import 'dart:async';

class CountdownLoader extends StatefulWidget {
  final int countdownStart; // Startwert des Countdowns
  final Color circleColor; // Farbe des Kreises
  final Color textColor; // Farbe des Textes
  final double strokeWidth; // Breite des Kreises

  CountdownLoader({
    required this.countdownStart,
    this.circleColor = Colors.blue,
    this.textColor = Colors.blue,
    this.strokeWidth = 6.0,
  });

  @override
  _CountdownLoaderState createState() => _CountdownLoaderState();
}

class _CountdownLoaderState extends State<CountdownLoader> {
  late int _countdown;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _countdown = widget.countdownStart;
    _startCountdown();
  }

  // Funktion, um den Countdown zu starten
  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer.cancel(); // Countdown stoppen, wenn er bei 0 angekommen ist
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Timer stoppen, wenn das Widget zerstört wird
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CircularProgressIndicator für den Ladekreis
          CircularProgressIndicator(
            value: _countdown / widget.countdownStart, // Wert zwischen 0 und 1, basierend auf dem Countdown
            strokeWidth: widget.strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(widget.circleColor),
          ),
          // Countdown in der Mitte des Kreises
          Text(
            '$_countdown', // Zeigt den aktuellen Countdown-Wert an
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
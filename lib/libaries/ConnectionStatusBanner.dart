import 'package:bus_desk_pro/config/globals.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionStatusBanner extends StatefulWidget {
  const ConnectionStatusBanner({super.key});

  @override
  _ConnectionStatusBannerState createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner> {
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _subscription = _connectivity.onConnectivityChanged;

    _subscription.listen((List<ConnectivityResult> results) {
      setState(() {
        isConnectedToInternet = results.any((r) => r != ConnectivityResult.none);
      });
    });

    // Initial prüfen
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    setState(() {
      isConnectedToInternet = results.any((r) => r != ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnectedToInternet ? Colors.green : Colors.red,
      alignment: Alignment.center,
      child: Text(
        isConnectedToInternet ? "Sie sind online" : "Sie sind derzeit offline",
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
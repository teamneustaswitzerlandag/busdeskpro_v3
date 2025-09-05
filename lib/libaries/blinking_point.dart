import 'package:flutter/material.dart';

class BlinkingPoint extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const BlinkingPoint({
    Key? key,
    this.size = 30.0,
    this.color = Colors.blue,
    this.duration = const Duration(seconds: 1),
  }) : super(key: key);

  @override
  _BlinkingPointState createState() => _BlinkingPointState();
}

class _BlinkingPointState extends State<BlinkingPoint> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // AnimationController mit der übergebenen Dauer
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    // Opacity-Animation für das Blinken
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
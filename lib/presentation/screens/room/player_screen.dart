import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  final String roomCode;

  const PlayerScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Room: $roomCode')),
    );
  }
}

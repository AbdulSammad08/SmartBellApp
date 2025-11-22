import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_bg.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Content overlay
        Material(
          color: Colors.black.withOpacity(0.2), // Adjust opacity (0.3-0.6)
          child: child,
        )
      ],
    );
  }
}
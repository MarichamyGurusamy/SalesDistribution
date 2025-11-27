import 'package:flutter/material.dart';

class JanaMasalaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? logoColor;
  final Color? textColor;

  const JanaMasalaLogo({
    Key? key,
    this.size = 64,
    this.showText = true,
    this.logoColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = logoColor ?? Color(0xFFE23744); // Brand red
    final tColor = textColor ?? Colors.grey[800];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo: Circular spice icon design
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, Color(0xFFFFA502)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              // Spice/leaf icon
              Icon(
                Icons.spa,
                size: size * 0.6,
                color: Colors.white,
              ),
            ],
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.2),
          Text(
            'JANA MASALA',
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              color: tColor,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Sales Distribution',
            style: TextStyle(
              fontSize: size * 0.15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

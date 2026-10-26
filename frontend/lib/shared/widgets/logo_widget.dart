import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const LogoWidget({super.key, this.size = 80, this.showText = false});

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return SvgPicture.asset(
        'assets/images/logo.svg',
        width: size * 1.5,
        height: size * 1.5,
      );
    }
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF0D2B1A),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

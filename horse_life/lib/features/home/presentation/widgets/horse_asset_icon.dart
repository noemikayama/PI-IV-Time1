import 'package:flutter/material.dart';

// Asset oficial que já é utilizado no menu inferior do HorseLife.
class HorseAssetIcon extends StatelessWidget {
  final double size;
  const HorseAssetIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/black-head-horse.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: size),
  );
}

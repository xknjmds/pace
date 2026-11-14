import 'package:flutter/material.dart';

/// The PACE symbol: three stacked stones, drawn with plain widgets so no
/// asset or SVG package is needed. [size] is the width of the bottom stone.
class CairnMark extends StatelessWidget {
  const CairnMark({super.key, this.size = 88, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final unit = size / 176; // geometry from the 256-unit master
    Widget stone(double width, double height) => Container(
      width: width * unit,
      height: height * unit,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(height * unit / 2),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stone(72, 44),
        SizedBox(height: 12 * unit),
        stone(124, 50),
        SizedBox(height: 12 * unit),
        stone(176, 56),
      ],
    );
  }
}

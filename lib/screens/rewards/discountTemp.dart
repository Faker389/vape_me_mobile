import 'package:flutter/material.dart';

class DiscountBox extends StatelessWidget {
  final int percentage;

  const DiscountBox({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190, // ~w-48 in Tailwind
      height: 160, // ~h-40 in Tailwind
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0015), // from-[#0A0015]
            Color(0xFF260547), // via-[#260547]
            Color(0xFF490E77), // to-[#490e77]
          ],
        ),
      ),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFA86FFF), // from-[#A86FFF]
              Color(0xFFFF6F91), // to-[#FF6F91]
            ],
          ).createShader(bounds),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '-$percentage%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

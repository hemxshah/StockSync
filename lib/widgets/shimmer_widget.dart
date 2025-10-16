import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget {
  static Widget rect({double width = double.infinity, double height = 16, BorderRadius? radius}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: radius ?? BorderRadius.circular(8)),
      ),
    );
  }

  static Widget circle({double size = 48}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(width: size, height: size, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
    );
  }
}

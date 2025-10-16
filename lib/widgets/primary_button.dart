import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: SizedBox(
        height: 48,
        child: Center(child: loading ? const CircularProgressIndicator.adaptive() : Text(label)),
      ),
    );
  }
}

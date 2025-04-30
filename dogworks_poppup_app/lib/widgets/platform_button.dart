import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool? isDestructive;
  final bool? isLoading;

  const PlatformButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isDestructive,
    this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Adaptive button based on platform
    if (kIsWeb) {
      return _buildWebButton();
    } else if (Platform.isIOS) {
      return _buildIOSButton();
    } else {
      return _buildMaterialButton();
    }
  }

  Widget _buildMaterialButton() {
    return ElevatedButton(
      onPressed: isLoading == true ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive == true
            ? Colors.red
            : const Color(0xFF2B3674),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: isLoading == true
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildIOSButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading == true ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: isDestructive == true
              ? Colors.red
              : const Color(0xFF2B3674),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isDestructive == true
                  ? Colors.red
                  : const Color(0xFF2B3674),
            ),
          ),
        ),
        child: isLoading == true
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isDestructive == true
                      ? Colors.red
                      : const Color(0xFF2B3674),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildWebButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: isLoading == true ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive == true
              ? Colors.red
              : const Color(0xFF2B3674),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading == true
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
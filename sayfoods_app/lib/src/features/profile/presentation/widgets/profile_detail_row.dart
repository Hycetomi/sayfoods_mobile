import 'package:flutter/material.dart';

class ProfileDetailRow extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onTap; // <-- NEW: Allows us to pass a click function

  const ProfileDetailRow({
    super.key,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        ),
        // <-- NEW: Clickable Icon
        IconButton(
          icon: const Icon(Icons.edit_square, size: 20),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(), // Keeps it tightly aligned
        ),
      ],
    );
  }
}

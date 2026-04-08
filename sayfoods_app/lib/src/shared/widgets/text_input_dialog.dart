import 'package:flutter/material.dart';

class TextInputDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final Color primaryColor;

  const TextInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.hintText = '',
    this.primaryColor = const Color(
      0xFF5A189A,
    ), // Defaults to your brand purple
  });

  // --- THE MAGIC METHOD ---
  // This lets you call TextInputDialog.show(...) from any file in your app!
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String initialValue,
    String hintText = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => TextInputDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
      ),
    );
  }

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initializes the text box with the current name/email/etc.
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Edit ${widget.title}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText.isNotEmpty
              ? widget.hintText
              : 'Enter new ${widget.title}',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Returns null
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(
            context,
            _controller.text.trim(),
          ), // Returns the new text
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

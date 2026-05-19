import 'package:flutter/material.dart';
import 'package:sayfoods_app/src/shared/widgets/sayfoods_modal.dart';

/// Replaces the old AlertDialog-based input with a SayfoodsModal.
/// Keeps the same static interface so all callers work unchanged.
class TextInputDialog {
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String initialValue,
    String hintText = '',
  }) async {
    String? result;
    final ctrl = TextEditingController(text: initialValue);

    await SayfoodsModal.show(
      context: context,
      type: SayfoodsModalType.custom,
      customIcon: Icons.edit_rounded,
      customIconColor: const Color(0xFF5B1380),
      title: 'Edit $title',
      customContent: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hintText.isNotEmpty ? hintText : 'Enter new $title',
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF5B1380), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
      primaryButtonText: 'Save',
      onPrimaryPressed: () {
        result = ctrl.text.trim();
        Navigator.pop(context);
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
    );

    ctrl.dispose();
    return result;
  }
}

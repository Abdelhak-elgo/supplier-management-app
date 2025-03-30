import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? confirmIcon;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.confirmIcon,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          icon: Icon(confirmIcon ?? Icons.check),
          label: Text(confirmLabel),
          style: TextButton.styleFrom(
            foregroundColor: confirmColor ?? Colors.red,
          ),
        ),
      ],
    );
  }

  // Helper method to show the dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? confirmIcon,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        confirmIcon: confirmIcon,
        onConfirm: onConfirm,
      ),
    );
    
    return confirmed ?? false;
  }

  // Helper for delete confirmation
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemType,
    String? itemName,
    required VoidCallback onConfirm,
  }) async {
    final title = 'Delete $itemType';
    final message = itemName != null
        ? 'Are you sure you want to delete $itemName? This action cannot be undone.'
        : 'Are you sure you want to delete this $itemType? This action cannot be undone.';
    
    return await show(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
      confirmIcon: Icons.delete,
      onConfirm: onConfirm,
    );
  }
}

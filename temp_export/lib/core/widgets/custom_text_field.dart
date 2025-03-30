import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? initialValue;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool isRequired;

  const CustomTextField({
    Key? key,
    this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.inputFormatters,
    this.enabled = true,
    this.initialValue,
    this.autofocus = false,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.onSubmitted,
    this.decoration,
    this.readOnly = false,
    this.onTap,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      decoration: decoration ??
          InputDecoration(
            labelText: isRequired ? '$label *' : label,
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            contentPadding: contentPadding,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      onFieldSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
    );
  }

  // Factory constructors for common field types
  
  // For numeric input
  factory CustomTextField.number({
    TextEditingController? controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    String? initialValue,
    bool isRequired = false,
    bool allowDecimal = true,
    bool allowNegative = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
        signed: allowNegative,
      ),
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      isRequired: isRequired,
      inputFormatters: [
        if (!allowDecimal) FilteringTextInputFormatter.digitsOnly,
        if (allowDecimal && !allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        if (allowDecimal && allowNegative)
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
    );
  }

  // For price input
  factory CustomTextField.price({
    TextEditingController? controller,
    String label = 'Price',
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    String? initialValue,
    bool isRequired = true,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? 'Enter price',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      isRequired: isRequired,
      prefix: const Icon(Icons.attach_money),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }

  // For quantity input
  factory CustomTextField.quantity({
    TextEditingController? controller,
    String label = 'Quantity',
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    String? initialValue,
    bool isRequired = true,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? 'Enter quantity',
      keyboardType: TextInputType.number,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      isRequired: isRequired,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  // For multiline text
  factory CustomTextField.multiline({
    TextEditingController? controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    String? initialValue,
    int minLines = 3,
    int maxLines = 5,
    bool isRequired = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.multiline,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      isRequired: isRequired,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  // For phone input
  factory CustomTextField.phone({
    TextEditingController? controller,
    String label = 'Phone',
    String? hint,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
    String? initialValue,
    bool isRequired = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? 'Enter phone number',
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      initialValue: initialValue,
      isRequired: isRequired,
      prefix: const Icon(Icons.phone),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
      ],
    );
  }

  // For search input
  factory CustomTextField.search({
    TextEditingController? controller,
    String label = 'Search',
    String? hint,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
    FocusNode? focusNode,
    VoidCallback? onClear,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? 'Search...',
      keyboardType: TextInputType.text,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      focusNode: focusNode,
      prefix: const Icon(Icons.search),
      suffix: controller != null && onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                onClear();
              },
            )
          : null,
    );
  }

  // For date picker
  factory CustomTextField.datePicker({
    required TextEditingController controller,
    String label = 'Date',
    String? hint,
    String? Function(String?)? validator,
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    void Function(DateTime)? onDateSelected,
    bool enabled = true,
    bool isRequired = false,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint ?? 'Select date',
      readOnly: true,
      enabled: enabled,
      isRequired: isRequired,
      validator: validator,
      suffix: const Icon(Icons.calendar_today),
      onTap: enabled
          ? () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate ?? DateTime.now(),
                firstDate: firstDate ?? DateTime(2000),
                lastDate: lastDate ?? DateTime(2100),
              );
              if (picked != null) {
                controller.text = '${picked.month}/${picked.day}/${picked.year}';
                if (onDateSelected != null) {
                  onDateSelected(picked);
                }
              }
            }
          : null,
    );
  }
}

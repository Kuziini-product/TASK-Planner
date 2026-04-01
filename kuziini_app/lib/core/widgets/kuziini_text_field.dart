import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_spacing.dart';

class KuziiniTextField extends StatelessWidget {
  const KuziiniTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.vGapSm,
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            fillColor: fillColor,
            contentPadding: contentPadding,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(suffixIcon, size: 20),
                    splashRadius: 20,
                  )
                : null,
            counterText: '',
            border: borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius!),
                    borderSide: BorderSide.none,
                  )
                : null,
            enabledBorder: borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius!),
                    borderSide: BorderSide.none,
                  )
                : null,
            focusedBorder: borderRadius != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius!),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

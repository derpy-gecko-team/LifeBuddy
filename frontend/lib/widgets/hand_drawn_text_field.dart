import 'package:flutter/material.dart';
import 'package:lifebuddy/theme/app_colors.dart';
import 'package:lifebuddy/widgets/nine_patch_box.dart';

// --- Tune the border here ---
const _borderAsset = 'assets/images/text_field_border.png';

/// Image pixels per logical pixel. Higher = thinner, smaller border.
const double _borderScale = 3;

/// Non-stretching corner band in image pixels. null = 40% of image height.
/// Example: EdgeInsets.all(40)
const EdgeInsets? _borderSlice = null;
// ----------------------------

/// A text field framed with a hand-drawn border. Works inside a [Form]:
/// `validator`, `Form.validate()` and `Form.reset()` behave like TextFormField.
class HandDrawnTextField extends FormField<String> {
  HandDrawnTextField({
    super.key,
    required this.controller,
    required String hint,
    String? Function(String value)? validator,
    super.enabled,
    super.autovalidateMode,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
    bool autocorrect = true,
    bool enableSuggestions = true,
  }) : super(
          initialValue: '',
          // Always validate the controller's live text, never a stale copy.
          validator:
              validator == null ? null : (_) => validator(controller.text),
          builder: (field) {
            final theme = Theme.of(field.context);
            final isEnabled = field.widget.enabled;
            final textStyle = theme.textTheme.bodyLarge;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isEnabled ? 1 : 0.6,
                  child: NinePatchBox(
                    asset: _borderAsset,
                    slice: _borderSlice,
                    imageScale: _borderScale,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: ConstrainedBox(
                      // Same height for every field, with or without a suffix.
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              enabled: isEnabled,
                              obscureText: obscureText,
                              keyboardType: keyboardType,
                              textInputAction: textInputAction,
                              autofillHints: autofillHints,
                              autocorrect: autocorrect,
                              enableSuggestions: enableSuggestions,
                              onSubmitted: onSubmitted,
                              style: textStyle,
                              decoration: InputDecoration.collapsed(
                                hintText: hint,
                                hintStyle: textStyle?.copyWith(
                                  color: AppColors.inkFaded,
                                ),
                              ),
                            ),
                          ),
                          if (suffix != null) suffix,
                        ],
                      ),
                    ),
                  ),
                ),
                // Error text slides open instead of popping in.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: field.hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 6, left: 8),
                          child: Text(
                            field.errorText!,
                            style: textStyle?.copyWith(
                              fontSize: 14,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            );
          },
        );

  final TextEditingController controller;

  @override
  FormFieldState<String> createState() => _HandDrawnTextFieldState();
}

/// Keeps the controller and the FormField in sync (so auto-validation on user
/// interaction works) and makes reset() actually clear the text.
class _HandDrawnTextFieldState extends FormFieldState<String> {
  TextEditingController get _controller =>
      (widget as HandDrawnTextField).controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FormField<String> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = (oldWidget as HandDrawnTextField).controller;
    if (oldController != _controller) {
      oldController.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
      setValue(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  void reset() {
    _controller.clear();
    super.reset();
  }

  void _onControllerChanged() {
    if (_controller.text != value) didChange(_controller.text);
  }
}
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lifebuddy/auth/validators.dart';
import 'package:lifebuddy/widgets/hand_drawn_text_field.dart';

/// Each callback returns an error message to display, or null on success.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onLogin, required this.onRegister});

  final Future<String?> Function(String identifier, String password) onLogin;
  final Future<String?> Function(String username, String email, String password)
  onRegister;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static const _swapDuration = Duration(milliseconds: 250);

  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isRegister = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() {
    FocusScope.of(context).unfocus();
    for (final c in [_username, _email, _password, _confirm]) {
      c.clear();
    }
    _formKey.currentState?.reset(); // clears validation errors
    setState(() {
      _isRegister = !_isRegister;
      _obscure = true;
      _error = null;
    });
  }

  /// Shared by every action: guards double taps, shows loading, catches errors.
  Future<void> _run(Future<String?> Function() action) async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    String? error;
    try {
      error = await action();
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }

    if (!mounted) return; // on success the parent usually navigates away
    if (error == null)
      TextInput.finishAutofillContext(); // offer to save password
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text; // never trim passwords

    await _run(
      () => _isRegister
          ? widget.onRegister(username, email, password)
          : widget.onLogin(username, password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final registering = _isRegister;

    return AutofillGroup(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + keyboardInset),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: _swapDuration,
                          child: FittedBox(
                            key: ValueKey(registering),
                            fit: BoxFit.scaleDown,
                            child: Text(
                              registering ? 'Create account' : 'Login',
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        HandDrawnTextField(
                          controller: _username,
                          enabled: !_loading,
                          hint: registering ? 'Username' : 'Username or email',
                          textInputAction: TextInputAction.next,
                          autofillHints: [
                            registering
                                ? AutofillHints.newUsername
                                : AutofillHints.username,
                          ],
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: registering
                              ? AuthValidators.username
                              : AuthValidators.identifier,
                        ),
                        _Reveal(
                          show: registering,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: HandDrawnTextField(
                              controller: _email,
                              enabled: !_loading,
                              hint: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              enableSuggestions: false,
                              validator: AuthValidators.email,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        HandDrawnTextField(
                          controller: _password,
                          enabled: !_loading,
                          obscureText: _obscure,
                          hint: 'Password',
                          suffix: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          textInputAction: registering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: registering ? null : (_) => _submit(),
                          autofillHints: [
                            registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: registering
                              ? AuthValidators.newPassword
                              : AuthValidators.loginPassword,
                        ),
                        _Reveal(
                          show: registering,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: HandDrawnTextField(
                              controller: _confirm,
                              enabled: !_loading,
                              obscureText: _obscure,
                              hint: 'Confirm password',
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              autocorrect: false,
                              enableSuggestions: false,
                              validator: (v) => v == _password.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                          ),
                        ),
                        // Server errors slide open under the fields.
                        AnimatedSize(
                          duration: _swapDuration,
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _error == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        // The button stays solid while loading (submit ignores
                        // taps), so the spinner remains visible on it.
                        FilledButton(
                          onPressed: _submit,
                          child: AnimatedSwitcher(
                            duration: _swapDuration,
                            child: _loading
                                ? SizedBox(
                                    key: const ValueKey('spinner'),
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Text(
                                    registering ? 'Create account' : 'Login',
                                    key: ValueKey(registering),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading ? null : _toggleMode,
                          child: AnimatedSwitcher(
                            duration: _swapDuration,
                            child: Text(
                              registering
                                  ? 'Already have an account? Log in'
                                  : "Don't have an account? Register",
                              key: ValueKey(registering),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grows [child] open (and fades it in) when [show] becomes true, and shrinks
/// it away when false. While hidden the child is NOT in the tree, so hidden
/// fields are never validated and never take focus.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter, // grow downward from the top edge
        child: FadeTransition(opacity: animation, child: child),
      ),
      // Keep full width while animating (the default layout shrink-wraps).
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: show
          ? KeyedSubtree(key: const ValueKey('shown'), child: child)
          : const SizedBox(key: ValueKey('hidden'), width: double.infinity),
    );
  }
}

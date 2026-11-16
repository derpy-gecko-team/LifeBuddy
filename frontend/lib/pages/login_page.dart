import 'package:material_ui/material_ui.dart';
import 'package:lifebuddy/auth/login_form.dart';
import 'package:lifebuddy/home_shell.dart';
import 'package:lifebuddy/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // --- Tune these by eye ---
  static const _startDelay = Duration(seconds: 1);
  static const _animDuration = Duration(milliseconds: 2400);
  static const _startScale = 1.0;
  static const _endScale = 1.35;
  // Fraction of the animation at which the form becomes visible and tappable.
  static const _formStart = 0.7;

  static const _background = AssetImage('assets/images/login_bg_image.jpeg');

  late final AnimationController _controller;
  late final Animation<double> _zoom;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animDuration);

    // First 75% of the animation: zoom.
    _zoom = Tween<double>(begin: _startScale, end: _endScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    // Last 30%: the form fades in and settles upward by a few pixels.
    final formIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(_formStart, 1.0, curve: Curves.easeOut),
    );
    _formOpacity = formIn;
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(formIn);

    // Quiet screen for 1s, then start.
    Future.delayed(_startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the big background before the zoom starts, so it never pops in.
    precacheImage(_background, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _fakeAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
    return null; // returning a String instead shows it as the error message
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shown for the frame or two before the image is decoded.
      backgroundColor: AppColors.parchment,
      // The form handles the keyboard itself; the background must stay still.
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ScaleTransition(
            scale: _zoom,
            alignment: Alignment.center, // zoom target point
            child: Image(image: _background, fit: BoxFit.cover),
          ),
          SafeArea(
            // Invisible means untappable: ignore touches until it fades in.
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => IgnorePointer(
                ignoring: _controller.value < _formStart,
                child: child,
              ),
              child: FadeTransition(
                opacity: _formOpacity,
                child: SlideTransition(
                  position: _formSlide,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: LoginForm(
                      onLogin: (identifier, password) => _fakeAuth(),
                      onRegister: (username, email, password) => _fakeAuth(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
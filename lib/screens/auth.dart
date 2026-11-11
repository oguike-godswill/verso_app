import 'package:flutter/material.dart';
import '../art.dart';
import '../state.dart';
import '../theme.dart';
import 'shell.dart';

class AuthScreen extends StatefulWidget {
  final int initialMode;
  const AuthScreen({super.key, this.initialMode = 0});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late int? _mode = widget.initialMode;
  int? _selectedAvatar = 0;
  final nameCtrl = TextEditingController();
  final handleCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String? errorMsg;
  bool _isLoading = false;

  int get mode => _mode ?? 0;
  int get selectedAvatar => _selectedAvatar ?? 0;

  static const emblemNames = [
    'The Lake',
    'Quiet Boat',
    'Hilltop Tree',
    'Crimson Sea',
    'Lighthouse',
    'Twin Peaks',
    'Sanctuary Arch',
    'Paper Sail',
  ];

  @override
  void dispose() {
    nameCtrl.dispose();
    handleCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_isLoading) return;
    final app = AppScope.of(context);
    setState(() {
      errorMsg = null;
      _isLoading = true;
    });

    final String? err;
    if (mode == 0) {
      err = await app.signIn(emailCtrl.text, passCtrl.text);
    } else {
      err = await app.signUp(
        name: nameCtrl.text,
        handle: handleCtrl.text,
        email: emailCtrl.text,
        password: passCtrl.text,
        avatarCover: selectedAvatar,
      );
    }

    if (!mounted) return;
    if (err != null) {
      setState(() {
        errorMsg = err;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = false);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;
    final canGoBack = Navigator.maybeOf(context)?.canPop() == true;

    return Scaffold(
      backgroundColor: VC.blue,
      body: Stack(
        children: [
          // Torn-paper background + upper illustration
          Positioned.fill(
            child: ClipPath(
              clipper: TornSideClipper(0.58),
              child: Container(color: VC.paper),
            ),
          ),
          if (!isKeyboardOpen)
            Positioned.fill(
              bottom: size.height * 0.45,
              child: CustomPaint(painter: WelcomeScenePainter(mode)),
            ),
          // Top header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  if (canGoBack)
                    CircleBtn(
                      icon: Icons.chevron_left,
                      bg: VC.navy.withValues(alpha: 0.12),
                      fg: VC.ink,
                      onTap: () => Navigator.maybePop(context),
                    ),
                ],
              ),
            ),
          ),
          // Torn bottom paper sheet with form
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: isKeyboardOpen ? null : TornTopClipper(seed: 9, depth: 12),
              child: Container(
                color: VC.cream,
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: isKeyboardOpen ? size.height : size.height * 0.78,
                ),
                padding: EdgeInsets.fromLTRB(
                  26,
                  isKeyboardOpen ? 16 : 30,
                  26,
                  isKeyboardOpen ? 16 : 24,
                ),
                child: SafeArea(
                  top: isKeyboardOpen,
                  bottom: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('YOUR QUIET TABLE', style: labelStyle()),
                        const SizedBox(height: 4),
                        Text(
                          mode == 0 ? 'Welcome back.' : 'Claim your shelf.',
                          style: serifStyle(isKeyboardOpen ? 24 : 30),
                        ),
                        const SizedBox(height: 12),
                        PillTabs(
                          labels: const ['Sign in', 'Create shelf'],
                          index: mode,
                          onChanged: (i) => setState(() {
                            _mode = i;
                            errorMsg = null;
                          }),
                        ),
                      const SizedBox(height: 16),
                      if (mode == 1) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _field(
                                key: const ValueKey('auth_name'),
                                controller: nameCtrl,
                                label: 'NAME',
                                hint: 'Clara',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field(
                                key: const ValueKey('auth_handle'),
                                controller: handleCtrl,
                                label: 'HANDLE',
                                hint: '@clara',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text('CHOOSE YOUR EMBLEM', style: labelStyle()),
                            const Spacer(),
                            Text(
                              emblemNames[selectedAvatar % emblemNames.length],
                              style: serifStyle(13, color: VC.blue, style: FontStyle.italic),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: kArchVariantCount,
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => setState(() => _selectedAvatar = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 10),
                                width: 52,
                                height: 62,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30),
                                    bottom: Radius.circular(8),
                                  ),
                                  border: Border.all(
                                    color: selectedAvatar == i ? VC.red : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ArchArt(variant: i),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _field(
                        key: const ValueKey('auth_email'),
                        controller: emailCtrl,
                        label: 'EMAIL',
                        hint: 'you@verso.app',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        key: const ValueKey('auth_pass'),
                        controller: passCtrl,
                        label: 'PASSPHRASE',
                        hint: '••••••••',
                        obscure: true,
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 10),
                        Text(errorMsg!, style: sansStyle(12, color: VC.red, weight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: VC.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _isLoading ? null : submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  mode == 0 ? 'Enter the Exhibit' : 'Create my Shelf',
                                  style: sansStyle(14, color: Colors.white, weight: FontWeight.w700),
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
      ],
    ),
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) =>
      Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle()),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: obscure == true,
            enableSuggestions: obscure != true,
            autocorrect: obscure != true,
            keyboardType: keyboardType ?? TextInputType.text,
            style: sansStyle(14, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: sansStyle(14, color: VC.muted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: VC.paper,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
}

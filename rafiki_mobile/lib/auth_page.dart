// rafiki_mobile/lib/auth_page.dart
import 'package:flutter/material.dart';
import 'auth_state.dart';

class RafikiColors {
  static const indigo = Color(0xFF4F46E5);
  static const coral  = Color(0xFFFF6B6B);
  static const ink    = Color(0xFF1F2937);
  static const muted  = Color(0xFF6B7280);
  static const bg     = Color(0xFFF9FAFB);
  static const border = Color(0xFFE5E7EB);
  static const red    = Color(0xFFEF4444);
}

class AuthPage extends StatefulWidget {
  final bool canPop;
  const AuthPage({super.key, this.canPop = true});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _role = 'client';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthState.instance;
      final phone = _phoneCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isLogin) {
        await auth.login(phone, password);
      } else {
        await auth.register(
          fullName: _nameCtrl.text.trim(),
          phone: phone,
          password: password,
          role: _role,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: Text(_isLogin ? 'Sign In' : 'Create Account'),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.canPop,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RafikiColors.border),
              ),
              child: Row(
                children: [
                  Expanded(child: _tabButton('Sign In', true)),
                  Expanded(child: _tabButton('Register', false)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!_isLogin) ...[
              _label('Full name'),
              _input(controller: _nameCtrl, hint: 'e.g. Erick Amomobo'),
              const SizedBox(height: 14),
            ],

            _label('Phone'),
            _input(
              controller: _phoneCtrl,
              hint: '254712345678',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_android, color: RafikiColors.muted, size: 18),
            ),
            const SizedBox(height: 14),

            _label('Password'),
            _input(
              controller: _passwordCtrl,
              hint: '••••••••',
              obscure: true,
              prefixIcon: const Icon(Icons.lock_outline, color: RafikiColors.muted, size: 18),
            ),

            if (!_isLogin) ...[
              const SizedBox(height: 14),
              _label('I am a...'),
              Row(
                children: [
                  Expanded(child: _roleChip('client', 'Client', Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(child: _roleChip('provider', 'Provider', Icons.construction)),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RafikiColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: RafikiColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                        style: const TextStyle(color: RafikiColors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RafikiColors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Sign In' : 'Create Account',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                _isLogin
                  ? "Don't have an account? Tap Register above"
                  : "Already have an account? Tap Sign In above",
                style: const TextStyle(color: RafikiColors.muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool isLoginTab) {
    final active = _isLogin == isLoginTab;
    return GestureDetector(
      onTap: () => setState(() {
        _isLogin = isLoginTab;
        _error = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? RafikiColors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : RafikiColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RafikiColors.ink)),
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RafikiColors.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RafikiColors.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RafikiColors.indigo, width: 1.5)),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final active = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? RafikiColors.indigo.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? RafikiColors.indigo : RafikiColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? RafikiColors.indigo : RafikiColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? RafikiColors.indigo : RafikiColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:class_attendance_frontend/config/app_theme.dart';
import 'package:class_attendance_frontend/providers/auth_provider.dart';
import 'package:class_attendance_frontend/utils/biometric_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cho HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _canShowBiometric = false; // Biến kiểm soát hiển thị nút vân tay

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  // Kiểm tra xem có dữ liệu cũ để hiện nút vân tay không
  Future<void> _checkSavedSession() async {
    final hasSaved = await ref.read(authProvider.notifier).hasSavedSession();
    final isBiometricAvailable = await BiometricHelper.isBiometricAvailable();

    if (mounted) {
      setState(() {
        _canShowBiometric = hasSaved && isBiometricAvailable;
      });
    }
  }

  // Hàm xử lý khi bấm nút vân tay
  Future<void> _onBiometricPressed() async {
    final authenticated = await BiometricHelper.authenticate();
    if (authenticated) {
      // Nếu vân tay đúng -> Gọi hàm khôi phục session
      await ref.read(authProvider.notifier).restoreSession();
      // AuthProvider update state -> Router sẽ tự chuyển trang
    } else {
      // Nếu sai hoặc hủy
      setState(() {
        _errorMessage = "Xác thực thất bại";
      });
    }
  }

  void _login() async {
    setState(() => _errorMessage = null);

    if (_formKey.currentState!.validate()) {
      final userId = _userIdController.text.trim();
      final password = _passwordController.text.trim();

      await ref.read(authProvider.notifier).login(userId, password);

      final error = ref.read(authProvider).error;
      if (error != null) {
        HapticFeedback.vibrate();
        setState(() {
          if (error.contains('401')) {
            _errorMessage = 'Sai tên đăng nhập hoặc mật khẩu';
          } else if (error.contains('timeout')) {
            _errorMessage = 'Mạng yếu, vui lòng thử lại';
          } else {
            _errorMessage = error.replaceAll('Exception:', '').trim();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 20),
                const Text(
                  'SmartCheck',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đăng nhập để tiếp tục',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mã số sinh viên / Giảng viên',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập mã số' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                authState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _login,
                  child: const Text('ĐĂNG NHẬP'),
                ),

                // --- NÚT VÂN TAY (CHỈ HIỆN KHI CÓ DATA CŨ) ---
                if (_canShowBiometric) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Hoặc đăng nhập nhanh: "),
                      IconButton(
                        icon: const Icon(Icons.fingerprint, size: 40, color: AppTheme.primaryColor),
                        onPressed: authState.isLoading ? null : _onBiometricPressed,
                        tooltip: "Sử dụng vân tay/FaceID",
                      ),
                    ],
                  ),
                ],
                // ---------------------------------------------

                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => context.push('/debug'),
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('Công cụ Developer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
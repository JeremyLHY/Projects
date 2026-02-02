import 'package:flutter/material.dart';
import 'package:test_app/services/auth.dart';
import 'package:test_app/shared/loading.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String error = '';
  bool loading = false;
  bool emailSent = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button at the top
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      Text(
                        emailSent ? 'Check Your Email' : 'Forgot Password?',
                        style: const TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20.0),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          emailSent
                              ? 'We\'ve sent password reset instructions to your email'
                              : 'Enter your email address to reset your password',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      if (!emailSent)
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            onChanged: (value) => setState(() => email = value),
                            decoration: const InputDecoration(
                              hintText: 'Enter your email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                      const SizedBox(height: 30.0),
                      if (!emailSent)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loading = true);
                                try {
                                  await _auth.sendPasswordResetLink(email);
                                  setState(() {
                                    emailSent = true;
                                    error = '';
                                    loading = false;
                                  });
                                } catch (e) {
                                  setState(() {
                                    error =
                                        'Error sending reset email: ${e.toString()}';
                                    loading = false;
                                  });
                                }
                              }
                            },
                            child: const Text(
                              'Reset Password',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      if (emailSent)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20.0),
                      Text(
                        error,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
  }
}

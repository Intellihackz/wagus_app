import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/theme/app_palette.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final otpController = useTextEditingController();
    final isLoading = useState(false);
    final isEmailSent = useState(false);
    final errorMessage = useState<String?>(null);

    return BlocListener<PortalBloc, PortalState>(
      listener: (context, state) {
        if (state.user != null) {
          context.go(home);
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.contrastDark,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Image.asset(
                    'assets/icons/logo_text.png',
                    height: 64,
                    fit: BoxFit.contain,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isEmailSent.value
                        ? 'Enter the verification code sent to:'
                        : 'Enter your email to login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: context.appColors.contrastLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEmailSent.value)
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: context.appColors.contrastLight),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle:
                            TextStyle(color: context.appColors.slightlyGrey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: context.appColors.slightlyGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: context.appColors.contrastLight),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          emailController.text,
                          style: TextStyle(
                              fontSize: 14,
                              color: context.appColors.contrastLight,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          style:
                              TextStyle(color: context.appColors.contrastLight),
                          decoration: InputDecoration(
                            hintText: 'Verification Code',
                            hintStyle: TextStyle(
                                color: context.appColors.slightlyGrey),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: context.appColors.slightlyGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: context.appColors.contrastLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (errorMessage.value != null)
                    Text(
                      errorMessage.value!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            isLoading.value = true;
                            errorMessage.value = null;

                            try {
                              if (!isEmailSent.value) {
                                final email =
                                    emailController.text.trim().toLowerCase();
                                if (email.isEmpty) {
                                  errorMessage.value =
                                      'Please enter your email';
                                  return;
                                }

                                final domain = email.split('@').last;
                                const blocked = [
                                  'tempmail.com',
                                  'mailinator.com',
                                  'guerrillamail.com',
                                  '10minutemail.com',
                                  'harinv.com',
                                  'idoidraw.com',
                                ];

                                if (blocked.contains(domain)) {
                                  errorMessage.value =
                                      'Temporary emails are not allowed';
                                  return;
                                }

                                final privy = PrivyService();
                                await privy.initialize();
                                privy.loginWithEmail(email);
                                isEmailSent.value = true;
                              } else {
                                if (otpController.text.trim().isEmpty) {
                                  errorMessage.value =
                                      'Please enter the verification code';
                                  return;
                                }

                                final privy = PrivyService();
                                await privy.initialize();
                                if (context.mounted) {
                                  await privy.verifyOtp(
                                    emailController.text.trim(),
                                    otpController.text.trim(),
                                    context,
                                  );
                                  context
                                      .read<PortalBloc>()
                                      .add(PortalInitialEvent());
                                }
                              }
                            } catch (e) {
                              errorMessage.value = 'Something went wrong';
                            } finally {
                              isLoading.value = false;
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEmailSent.value
                                ? 'Verify Code'
                                : 'Continue with Email',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                  if (isEmailSent.value) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        isEmailSent.value = false;
                        otpController.clear();
                        errorMessage.value = null;
                      },
                      child: Text(
                        'Back to Email',
                        style:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

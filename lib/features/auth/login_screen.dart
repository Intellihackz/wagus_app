import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/router.dart';
import 'package:wagus/services/privy_service.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/utils.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final otpController = useTextEditingController();
    final isLoading = useState(false);
    final isEmailSent = useState(false);
    final errorMessage = useState<String?>(null);

    // Use useEffect to initialize PrivyService when the widget is built
    useAsyncEffect(
        effect: () async {
          final privyService = PrivyService();
          final user = await privyService.initialize();
          if (user != null) {
            // User is already authenticated, update PortalBloc
            if (context.mounted) {
              context.read<PortalBloc>().add(PortalAuthorizeEvent(context));
            }
          }

          return null;
        },
        keys: []);

    return BlocListener<PortalBloc, PortalState>(
      listener: (context, state) {
        if (state.user != null) {
          context.go(home);
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.contrastDark,
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/icons/logo_text.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.3),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or title
                      Text(
                        'WAGUS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appColors.contrastLight,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email or OTP input
                      if (!isEmailSent.value) ...[
                        Text(
                          '[ Enter your email to login ]',
                          style: TextStyle(
                            color: context.appColors.contrastLight,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style:
                              TextStyle(color: context.appColors.contrastLight),
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                                color: context.appColors.slightlyGrey),
                            filled: true,
                            fillColor: context.appColors.contrastDark
                                .withValues(alpha: 0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.slightlyGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.slightlyGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.contrastLight),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Enter the verification code sent to ${emailController.text}',
                          style: TextStyle(
                            color: context.appColors.contrastLight,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                            fillColor: context.appColors.contrastDark
                                .withValues(alpha: 0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.slightlyGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.slightlyGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: context.appColors.contrastLight),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Error message
                      if (errorMessage.value != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            errorMessage.value!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 14,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action button
                      ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                isLoading.value = true;
                                errorMessage.value = null;

                                try {
                                  if (!isEmailSent.value) {
                                    // Send email verification
                                    if (emailController.text.trim().isEmpty) {
                                      errorMessage.value =
                                          'Please enter your email';
                                      isLoading.value = false;
                                      return;
                                    }

                                    PrivyService().loginWithEmail(
                                      emailController.text.trim(),
                                    );
                                    isEmailSent.value = true;
                                  } else {
                                    // Verify OTP
                                    if (otpController.text.trim().isEmpty) {
                                      errorMessage.value =
                                          'Please enter the verification code';
                                      isLoading.value = false;
                                      return;
                                    }

                                    PrivyService().verifyOtp(
                                      emailController.text.trim(),
                                      otpController.text.trim(),
                                      context,
                                    );
                                  }
                                } finally {
                                  isLoading.value = false;
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.contrastLight,
                          foregroundColor: context.appColors.contrastDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.appColors.contrastDark,
                                ),
                              )
                            : Text(
                                !isEmailSent.value
                                    ? 'Continue with Email'
                                    : 'Verify Code',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),

                      if (isEmailSent.value) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isLoading.value
                              ? null
                              : () {
                                  isEmailSent.value = false;
                                  otpController.clear();
                                  errorMessage.value = null;
                                },
                          child: Text(
                            'Back to Email',
                            style: TextStyle(
                              color: context.appColors.contrastLight,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

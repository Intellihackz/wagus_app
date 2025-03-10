import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:wagus/wagus.dart';

class Bank extends StatelessWidget {
  const Bank({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortalBloc, PortalState>(
      builder: (context, portalState) {
        return CustomPaint(
          painter: CryptoBackgroundPainter(),
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 24.0,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 128.0, left: 32.0, right: 32.0),
                  child: Column(
                    spacing: 12.0,
                    children: [
                      Text(
                        'Bank Balance',
                        style: TextStyle(
                          color: AppPalette.contrastLight,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${portalState.holder?.tokenAmount.toStringAsFixed(2) ?? '0.00'} \$WAGUS',
                        style: TextStyle(
                          color: AppPalette.contrastLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 32.0, right: 32.0, bottom: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement withdraw funds logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Withdraw Funds feature coming soon!')),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              context.appColors.contrastLight),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 12.0),
                          ),
                        ),
                        child: Text(
                          'Withdraw Funds',
                          style: TextStyle(
                            color: context.appColors.contrastDark,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

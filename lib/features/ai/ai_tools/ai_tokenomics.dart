import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AiTokenomicsGenerator extends HookWidget {
  const AiTokenomicsGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final projectNameController = useTextEditingController();
    final tokenSupplyController = useTextEditingController();
    final tokenUtilityController = useTextEditingController();
    final tokenDistributionController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  BackButton(color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'AI Tokenomics Generator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                label: 'Project Name',
                controller: projectNameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter project name' : null,
                context: context,
              ),
              _buildInputField(
                label: 'Total Token Supply',
                controller: tokenSupplyController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter token supply' : null,
                context: context,
              ),
              _buildInputField(
                label: 'Token Utility',
                controller: tokenUtilityController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter token utility' : null,
                context: context,
              ),
              _buildInputField(
                label: 'Token Distribution',
                controller: tokenDistributionController,
                validator: (val) => val == null || val.isEmpty
                    ? 'Enter token distribution'
                    : null,
                context: context,
                maxLines: 2,
                hintText:
                    'Example: 30% Public Sale, 25% Ecosystem, 20% Team, 15% Treasury, 10% Advisors',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (formKey.currentState!.validate()) {
                      _handleGenerate(
                        context,
                        projectNameController,
                        tokenSupplyController,
                        tokenUtilityController,
                        tokenDistributionController,
                      );
                    }
                  },
                  child: const Text('Generate Tokenomics'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required BuildContext context,
    int maxLines = 1,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.greenAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green),
          ),
        ),
      ),
    );
  }

  void _handleGenerate(
    BuildContext context,
    TextEditingController name,
    TextEditingController supply,
    TextEditingController utility,
    TextEditingController distribution,
  ) {
    context.read<AiBloc>().add(
          AISubmitTokenomicsFormEvent(
            projectName: name.text,
            tokenSupply: supply.text,
            tokenUtility: utility.text,
            tokenDistribution: distribution.text,
          ),
        );

    name.clear();
    supply.clear();
    utility.clear();
    distribution.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<AiBloc, AiState>(
          builder: (context, state) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Generated Tokenomics',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: _buildDialogContent(state, context),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<AiBloc>().add(AIResetStateEvent());
                  },
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white)),
                ),
                if (state.tokenomicsFormState == AITokenomicsFormState.success)
                  TextButton(
                    onPressed: () async {
                      final pdf = pw.Document();
                      pdf.addPage(
                        pw.Page(
                          build: (context) => pw.Text(
                            state.tokenomics!,
                            style: const pw.TextStyle(
                                fontSize: 12, lineSpacing: 1.5),
                          ),
                        ),
                      );
                      final dir = await getApplicationDocumentsDirectory();
                      final filePath =
                          '${dir.path}/tokenomics_${DateTime.now().millisecondsSinceEpoch}.pdf';
                      final file = File(filePath);
                      await file.writeAsBytes(await pdf.save());
                      await Share.shareXFiles([XFile(filePath)]);
                    },
                    child: const Text('Save as PDF',
                        style: TextStyle(color: Colors.greenAccent)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogContent(AiState state, BuildContext context) {
    if (state.tokenomicsFormState == AITokenomicsFormState.loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.tokenomicsFormState == AITokenomicsFormState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate tokenomics',
          style: const TextStyle(color: Colors.red),
        ),
      );
    } else if (state.tokenomics != null) {
      return SingleChildScrollView(
        child: Text(
          state.tokenomics!,
          style: TextStyle(
            color: context.appColors.contrastDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    } else {
      return Center(
          child: Text('Generating tokenomics...',
              style: TextStyle(color: context.appColors.contrastDark)));
    }
  }
}

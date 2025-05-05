import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:wagus/features/incubator/bloc/incubator_bloc.dart';
import 'package:wagus/features/incubator/domain/project.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';
import 'package:uuid/uuid.dart';

class ProjectInterface extends HookWidget {
  const ProjectInterface({super.key});

  @override
  Widget build(BuildContext context) {
    final whitePaperFile = useState<File?>(null);
    final roadMapFile = useState<File?>(null);

    final projectNameController = useTextEditingController();
    final projectDescriptionController = useTextEditingController();
    final projectDateController = useTextEditingController();
    final projectGitHubController = useTextEditingController();
    final projectWebsiteController = useTextEditingController();
    final projectWhitePaperController = useTextEditingController();
    final projectRoadMapController = useTextEditingController();
    final projectSocialMediaController = useTextEditingController();
    final projectTelegramController = useTextEditingController();
    final projectWalletAddressController = useTextEditingController();

    // create a form with form key
    final formKey = useMemoized(() => GlobalKey<FormState>());

    Future<void> pickAndSaveWhitePaperPdf() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          final String originalPath = result.files.single.path!;
          final File file = File(originalPath);

          projectWhitePaperController.text = result.files.single.name;
          whitePaperFile.value = file; // Store the File object

          print('Whitepaper PDF selected: $originalPath');
        } else {
          print('No whitepaper file selected');
        }
      } catch (e) {
        print('Error picking whitepaper PDF: $e');
        rethrow;
      }
    }

    Future<void> pickAndSaveRoadMapPdf() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          final String originalPath = result.files.single.path!;
          final File file = File(originalPath);

          projectRoadMapController.text = result.files.single.name;
          roadMapFile.value = file; // Store the File object

          print('Roadmap PDF selected: $originalPath');
        } else {
          print('No roadmap file selected');
        }
      } catch (e) {
        print('Error picking roadmap PDF: $e');
        rethrow;
      }
    }

    return BlocConsumer<IncubatorBloc, IncubatorState>(
      listener: (context, state) {
        if (state.status == IncubatorSubmissionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project submitted successfully!'),
            ),
          );
          if (context.canPop()) {
            context.pop();
          }
        } else if (state.status == IncubatorSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project submission failed. Please try again.'),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child:
                            BackButton(color: context.appColors.contrastLight)),
                    const SizedBox(height: 16),
                    const Text(
                      'Project Interface',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: projectNameController,
                      decoration: InputDecoration(
                        labelText: 'Project Name',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: projectDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Project Description',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project description';
                        }
                        return null;
                      },
                    ),
                    // date picker with read only textfield showing selected date
                    GestureDetector(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          projectDateController.text =
                              '${pickedDate.toLocal()}'.split(' ')[0];
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: projectDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Project Launch Date',
                            labelStyle: TextStyle(
                                color: context.appColors.contrastLight),
                          ),
                          onTapOutside: (_) {
                            FocusScope.of(context).unfocus();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a project launch date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: projectWalletAddressController,
                      decoration: InputDecoration(
                        labelText: 'Project Wallet Address',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project wallet address';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: projectGitHubController,
                      decoration: InputDecoration(
                        labelText: 'GitHub Link',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (!newValue.text.startsWith('https://')) {
                            return TextEditingValue(
                              text: 'https://${newValue.text}',
                              selection: TextSelection.collapsed(
                                offset:
                                    'https://'.length + newValue.selection.end,
                              ),
                            );
                          }
                          if (newValue.text == 'https://') {
                            return oldValue; // Prevent deleting "https://"
                          }
                          return newValue;
                        }),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value == 'https://') {
                          return 'Please enter a GitHub link';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: projectWebsiteController,
                      decoration: InputDecoration(
                        labelText: 'Website Link',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (!newValue.text.startsWith('https://')) {
                            return TextEditingValue(
                              text: 'https://${newValue.text}',
                              selection: TextSelection.collapsed(
                                offset:
                                    'https://'.length + newValue.selection.end,
                              ),
                            );
                          }
                          if (newValue.text == 'https://') {
                            return oldValue; // Prevent deleting "https://"
                          }
                          return newValue;
                        }),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value == 'https://') {
                          return 'Please enter a website link';
                        }
                        return null;
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Suggested change here to make it cleaner
                        Expanded(
                          child: TextFormField(
                            controller: projectWhitePaperController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Whitepaper PDF',
                              labelStyle: TextStyle(
                                  color: context.appColors.contrastLight),
                            ),
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please attach a whitepaper PDF'
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file,
                              color: context.appColors.contrastLight),
                          onPressed: pickAndSaveWhitePaperPdf,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: projectRoadMapController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Roadmap PDF',
                              labelStyle: TextStyle(
                                  color: context.appColors.contrastLight),
                            ),
                            onTapOutside: (_) {
                              FocusScope.of(context).unfocus();
                            },
                            validator: (value) => value == null || value.isEmpty
                                ? 'Please attach a roadmap PDF'
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file,
                              color: context.appColors.contrastLight),
                          onPressed: pickAndSaveRoadMapPdf,
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: projectSocialMediaController,
                      decoration: InputDecoration(
                        labelText: 'Social Media Link',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (!newValue.text.startsWith('https://')) {
                            return TextEditingValue(
                              text: 'https://${newValue.text}',
                              selection: TextSelection.collapsed(
                                offset:
                                    'https://'.length + newValue.selection.end,
                              ),
                            );
                          }
                          if (newValue.text == 'https://') {
                            return oldValue; // Prevent deleting "https://"
                          }
                          return newValue;
                        }),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value == 'https://') {
                          return 'Please enter a Social Media link';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: projectTelegramController,
                      decoration: InputDecoration(
                        labelText: 'Telegram Link',
                        labelStyle:
                            TextStyle(color: context.appColors.contrastLight),
                      ),
                      onTapOutside: (_) {
                        FocusScope.of(context).unfocus();
                      },
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (!newValue.text.startsWith('https://')) {
                            return TextEditingValue(
                              text: 'https://${newValue.text}',
                              selection: TextSelection.collapsed(
                                offset:
                                    'https://'.length + newValue.selection.end,
                              ),
                            );
                          }
                          if (newValue.text == 'https://') {
                            return oldValue; // Prevent deleting "https://"
                          }
                          return newValue;
                        }),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value == 'https://') {
                          return 'Please enter a Telegram link';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context)
                              .unfocus(); // Dismiss the keyboard
                          if (formKey.currentState!.validate()) {
                            final emailId = (context
                                        .read<PortalBloc>()
                                        .state
                                        .user!
                                        .linkedAccounts
                                        .firstWhere((account) =>
                                            account.type == 'email')
                                    as EmailAccount)
                                .emailAddress;
                            context
                                .read<IncubatorBloc>()
                                .add(IncubatorProjectSubmitEvent(
                                  Project(
                                    id: Uuid().v4(),
                                    contactEmail: emailId,
                                    name: projectNameController.text,
                                    description:
                                        projectDescriptionController.text,
                                    walletAddress:
                                        projectWalletAddressController.text,
                                    gitHubLink: projectGitHubController.text,
                                    websiteLink: projectWebsiteController.text,
                                    whitePaperLink: '',
                                    roadmapLink: '',
                                    socialsLink:
                                        projectSocialMediaController.text,
                                    telegramLink:
                                        projectTelegramController.text,
                                    fundingProgress: 0,
                                    likesCount: 0,
                                    launchDate: DateTime.now(),
                                    addressesFunded: [],
                                    totalFunded: 0,
                                  ),
                                  whitePaperFile: whitePaperFile.value,
                                  roadMapFile: roadMapFile.value,
                                ));
                          }

                          // Clear the form fields after submission
                          projectNameController.clear();
                          projectDescriptionController.clear();
                          projectDateController.clear();
                          projectWalletAddressController.clear();
                          projectGitHubController.clear();
                          projectWebsiteController.clear();
                          projectWhitePaperController.clear();
                          projectRoadMapController.clear();
                          projectSocialMediaController.clear();
                          projectTelegramController.clear();
                          whitePaperFile.value = null;
                          roadMapFile.value = null;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appColors.contrastLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child:
                            state.status == IncubatorSubmissionStatus.submitting
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: const CircularProgressIndicator(
                                      color: AppPalette.deepMidnightBlue,
                                    ),
                                  )
                                : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wagus/features/ai/bloc/ai_bloc.dart';
import 'package:wagus/features/ai/data/ai_repository.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';
import 'package:wagus/theme/app_palette.dart';

class AIImageGeneration extends HookWidget {
  const AIImageGeneration({super.key});

  @override
  Widget build(BuildContext context) {
    final promptController = useTextEditingController();
    final promptFocusNode = useFocusNode();
    final isFocused = useState(false);

    useEffect(() {
      void onFocusChange() {
        isFocused.value = promptFocusNode.hasFocus;
        if (!promptFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
        }
      }

      promptFocusNode.addListener(onFocusChange);

      return null;
    }, []);

    return BlocSelector<PortalBloc, PortalState, TierStatus>(
      selector: (state) {
        return state.tierStatus;
      },
      builder: (context, portalState) {
        return BlocBuilder<AiBloc, AiState>(
          builder: (context, state) {
            return PopScope(
              onPopInvokedWithResult: (onPop, result) async {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<AiBloc>().add(AIResetStateEvent());
                  }
                });
              },
              child: Scaffold(
                resizeToAvoidBottomInset: true,
                body: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          BackButton(color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'AI Image Generation',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: portalState == TierStatus.adventurer
                                  ? TierStatus.adventurer.color
                                  : TierStatus.basic.color,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildImageContent(
                              state, context, isFocused.value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: promptController,
                        focusNode: promptFocusNode,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Enter your prompt here',
                          labelStyle: TextStyle(color: Colors.white60),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: portalState == TierStatus.adventurer
                                  ? TierStatus.adventurer.color
                                  : TierStatus.basic.color,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: portalState == TierStatus.adventurer
                                    ? TierStatus.adventurer.color
                                    : TierStatus.basic.color),
                          ),
                          fillColor: Colors.grey[850],
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                portalState == TierStatus.adventurer
                                    ? TierStatus.adventurer.color
                                    : TierStatus.basic.color,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state.imageGenerationState ==
                                  AIImageGenerationState.loading
                              ? null
                              : () {
                                  final prompt = promptController.text.trim();
                                  if (prompt.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Please enter a prompt')),
                                    );
                                    return;
                                  }
                                  context
                                      .read<AiBloc>()
                                      .add(AIGenerateImageEvent(prompt));
                                  promptController.clear();

                                  if (isFocused.value) {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                          child: state.imageGenerationState ==
                                  AIImageGenerationState.loading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text('Generate Image'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageContent(
      AiState state, BuildContext context, bool isFocused) {
    if (state.imageGenerationState == AIImageGenerationState.loading) {
      return Center(child: CircularProgressIndicator());
    } else if (state.imageGenerationState == AIImageGenerationState.failure) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Failed to generate image',
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (state.imageUrl != null) {
      return GestureDetector(
        onTap: () {
          if (isFocused) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.1),
                BlendMode.darken,
              ),
              child: Image.network(
                state.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator()));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Text('Failed to load image');
                },
              ),
            ),
            Visibility(
              visible: state.imageGenerationState ==
                      AIImageGenerationState.success &&
                  !isFocused,
              child: Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.download,
                    color: context.appColors.contrastLight,
                  ),
                  onPressed: () async {
                    final hasSaved = await context
                        .read<AIRepository>()
                        .saveImage(imageUrl: state.imageUrl!);
                    if (context.mounted) {
                      if (hasSaved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Image saved')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save image')),
                        );
                      }
                    } else {
                      print('Context is not mounted');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Generated Image will appear here',
          textAlign: TextAlign.center,
        ),
      ));
    }
  }
}

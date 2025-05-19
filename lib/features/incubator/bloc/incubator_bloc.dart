import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:wagus/features/home/data/home_repository.dart';
import 'package:wagus/features/home/domain/message.dart';
import 'package:wagus/features/incubator/data/incubator_repository.dart';
import 'package:wagus/features/incubator/domain/project.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:wagus/features/portal/bloc/portal_bloc.dart';

part 'incubator_event.dart';
part 'incubator_state.dart';

class IncubatorBloc extends Bloc<IncubatorEvent, IncubatorState> {
  final IncubatorRepository incubatorRepository;
  final HomeRepository homeRepository;

  IncubatorBloc(
      {required this.incubatorRepository, required this.homeRepository})
      : super(IncubatorState(
          status: IncubatorSubmissionStatus.initial,
          projects: [],
          likedProjectsIds: const {},
          transactionStatus: IncubatorTransactionStatus.initial,
        )) {
    on<IncubatorInitialEvent>((event, emit) async {
      final userId = event.userId;

      // Listen to projects stream
      await emit.forEach(incubatorRepository.getProjects(), onData: (data) {
        final projects = data.docs.map((doc) {
          return {
            'id': doc.id, // Include the document ID
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();

        return state.copyWith(
          projects:
              projects.map((project) => Project.fromJson(project)).toList(),
        );
      });

      // Listen to liked projects stream
      add(IncubatorFindLikedProjectsEvent(userId: userId));
    });

    on<IncubatorFindLikedProjectsEvent>((event, emit) async {
      print(
          'Handling IncubatorFindLikedProjectsEvent for userId: ${event.userId}');
      await emit.forEach(incubatorRepository.getUserLikedProjects(event.userId),
          onData: (data) {
        final likedProjectIds =
            data.docs.map((doc) => doc.reference.parent.parent!.id).toSet();
        print('Liked project IDs: $likedProjectIds');
        return state.copyWith(likedProjectIds: likedProjectIds);
      }, onError: (error, __) {
        print('Error in IncubatorFindLikedProjectsEvent: $error');
        return state;
      });
    });

    on<IncubatorProjectSubmitEvent>((event, emit) async {
      emit(state.copyWith(status: IncubatorSubmissionStatus.submitting));
      try {
        final projectId = await incubatorRepository.submitProject(
            event.project, event.whitePaperFile, event.roadMapFile);
        final updatedProject = event.project.copyWithId(projectId);
        final updatedProjects = [...state.projects, updatedProject];
        emit(state.copyWith(
          status: IncubatorSubmissionStatus.success,
          projects: updatedProjects,
        ));
      } on Exception catch (e, __) {
        emit(state.copyWith(status: IncubatorSubmissionStatus.failure));
        return;
      }
    });

    on<IncubatorProjectLikeEvent>((event, emit) async {
      try {
        final hasLiked = state.likedProjectsIds.contains(event.projectId);
        if (!hasLiked) {
          // Optimistic update
          final newLikedIds = Set<String>.from(state.likedProjectsIds)
            ..add(event.projectId);
          final updatedProjects = state.projects.map((p) {
            if (p.id == event.projectId) {
              return Project(
                id: p.id,
                contactEmail: p.contactEmail,
                name: p.name,
                description: p.description,
                fundingProgress: p.fundingProgress,
                likesCount: p.likesCount + 1, // Increment likesCount locally
                launchDate: p.launchDate,
                walletAddress: p.walletAddress,
                gitHubLink: p.gitHubLink,
                websiteLink: p.websiteLink,
                whitePaperLink: p.whitePaperLink,
                roadmapLink: p.roadmapLink,
                socialsLink: p.socialsLink,
                telegramLink: p.telegramLink,
                addressesFunded: p.addressesFunded,
                totalFunded: p.totalFunded,
                preferredTokenAddress: p.preferredTokenAddress,
                preferredTokenTicker: p.preferredTokenTicker,
              );
            }
            return p;
          }).toList();

          emit(state.copyWith(
            likedProjectIds: newLikedIds,
            projects: updatedProjects,
          ));

          await incubatorRepository.likeProject(event.projectId, event.userId);
        }
      } catch (e) {
        // Revert on failure
        emit(state.copyWith(
          likedProjectIds: state.likedProjectsIds,
          projects: state.projects, // Revert projects as well
        ));
        print('Error liking project: $e');
      }
    });

    on<IncubatorProjectUnlikeEvent>((event, emit) async {
      try {
        final hasLiked = state.likedProjectsIds.contains(event.projectId);
        if (hasLiked) {
          // Optimistic update
          final newLikedIds = Set<String>.from(state.likedProjectsIds)
            ..remove(event.projectId);
          final updatedProjects = state.projects.map((p) {
            if (p.id == event.projectId && p.likesCount > 0) {
              return Project(
                id: p.id,
                contactEmail: p.contactEmail,
                name: p.name,
                description: p.description,
                fundingProgress: p.fundingProgress,
                likesCount: p.likesCount - 1, // Decrement likesCount locally
                launchDate: p.launchDate,
                walletAddress: p.walletAddress,
                gitHubLink: p.gitHubLink,
                websiteLink: p.websiteLink,
                whitePaperLink: p.whitePaperLink,
                roadmapLink: p.roadmapLink,
                socialsLink: p.socialsLink,
                telegramLink: p.telegramLink,
                addressesFunded: p.addressesFunded,
                totalFunded: p.totalFunded,
                preferredTokenAddress: p.preferredTokenAddress,
                preferredTokenTicker: p.preferredTokenTicker,
              );
            }
            return p;
          }).toList();

          emit(state.copyWith(
            likedProjectIds: newLikedIds,
            projects: updatedProjects,
          ));

          await incubatorRepository.unlikeProject(
              event.projectId, event.userId);
        }
      } catch (e) {
        // Revert on failure
        emit(state.copyWith(
          likedProjectIds: state.likedProjectsIds,
          projects: state.projects, // Revert projects as well
        ));
        print('Error unliking project: $e');
      }
    });

    on<IncubatorWithdrawEvent>((event, emit) async {
      emit(state.copyWith(
          transactionStatus: IncubatorTransactionStatus.submitting));
      try {
        await incubatorRepository.withdrawToProject(
          wallet: event.wallet,
          amount: event.amount,
          projectId: event.projectId,
          userId: event.userId,
          tokenAddress: event.tokenAddress,
          tokenTicker: event.tokenTicker,
        );

        // Update the project in state
        final updatedProjects = state.projects.map((p) {
          if (p.id == event.projectId) {
            final maxCap = p.maxAllocation;
            final newTotal = (p.totalFunded ?? 0) + event.amount;

            return p.copyWith(
              totalFunded: () => newTotal,
              fundingProgress: newTotal / maxCap,
            );
          }
          return p;
        }).toList();

        emit(state.copyWith(
          transactionStatus: IncubatorTransactionStatus.success,
          projects: updatedProjects,
        ));

        final project = updatedProjects
            .firstWhere((project) => project.id == event.projectId);

        final message = Message(
          text:
              '[FUND] ${event.wallet.address} funded ${event.amount} \$${event.tokenTicker} to project "${project.name}" 🚀',
          sender: 'System',
          tier: TierStatus.system,
          room: 'General',
        );

        await homeRepository.sendMessage(message);
      } catch (e) {
        print('Error withdrawing to project: $e');
        emit(state.copyWith(
            transactionStatus: IncubatorTransactionStatus.failure));
      }
    });

    on<IncubatorResetTransactionStatusEvent>((event, emit) async {
      emit(state.copyWith(
          transactionStatus: IncubatorTransactionStatus.initial));
    });
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wagus/features/incubator/domain/project.dart';

class IncubatorRepository {
  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  Future<String> _uploadPdfToStorage(File file, String fileName) async {
    try {
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('project_pdfs/$fileName');
      final UploadTask uploadTask = storageRef.putFile(file);
      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  // Like a project (add user to likes subcollection and increment likesCount)
  Future<void> likeProject(String projectId, String userId) async {
    try {
      final projectRef = projectsCollection.doc(projectId);
      final likeRef = projectRef.collection('likes').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final projectSnapshot = await transaction.get(projectRef);
        if (!projectSnapshot.exists) {
          throw Exception('Project does not exist!');
        }

        final data = projectSnapshot.data() as Map<String, dynamic>;
        if (data['id'] != projectId) {
          throw Exception('Project ID mismatch in document data!');
        }

        final currentLikes = data['likesCount'] ?? 0;
        final likeSnapshot = await transaction.get(likeRef);

        if (!likeSnapshot.exists) {
          transaction.set(likeRef, {
            'userId': userId, // Add userId as a field
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(projectRef, {
            'likesCount': currentLikes + 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to like project: $e');
    }
  }

  // Unlike a project (remove user from likes subcollection and decrement likesCount)
  Future<void> unlikeProject(String projectId, String userId) async {
    try {
      final projectRef = projectsCollection.doc(projectId);
      final likeRef = projectRef.collection('likes').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final projectSnapshot = await transaction.get(projectRef);
        if (!projectSnapshot.exists) {
          throw Exception('Project does not exist!');
        }

        final currentLikes =
            (projectSnapshot.data() as Map<String, dynamic>)['likesCount'] ?? 0;
        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists && currentLikes > 0) {
          transaction.delete(likeRef);
          transaction.update(projectRef, {
            'likesCount': currentLikes - 1,
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to unlike project: $e');
    }
  }

  // Check if a user has liked a project
  Future<bool> hasUserLikedProject(String projectId, String userId) async {
    final likeDoc = await projectsCollection
        .doc(projectId)
        .collection('likes')
        .doc(userId)
        .get();
    return likeDoc.exists;
  }

  // Submit a project with PDFs to Firebase
  Future<String> submitProject(
      Project project, File? whitePaperFile, File? roadMapFile) async {
    try {
      // Generate a document reference with an ID upfront
      final docRef = projectsCollection.doc();
      final projectId = docRef.id;

      String? whitePaperUrl;
      if (whitePaperFile != null) {
        whitePaperUrl = await _uploadPdfToStorage(
          whitePaperFile,
          '${project.name}_whitepaper_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      String? roadMapUrl;
      if (roadMapFile != null) {
        roadMapUrl = await _uploadPdfToStorage(
          roadMapFile,
          '${project.name}_roadmap_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      // Use set() with the pre-generated ID instead of add()
      await docRef.set({
        'id': projectId, // Store the ID in the document data
        'name': project.name,
        'description': project.description,
        'walletAddress': project.walletAddress,
        'gitHubLink': project.gitHubLink,
        'websiteLink': project.websiteLink,
        'whitePaperLink': whitePaperUrl,
        'roadmapLink': roadMapUrl,
        'socialsLink': project.socialsLink,
        'telegramLink': project.telegramLink,
        'fundingProgress': project.fundingProgress,
        'likesCount': 0,
        'launchDate': project.launchDate.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      return projectId; // Return the ID for use in project.id
    } catch (e) {
      throw Exception('Failed to submit project: $e');
    }
  }

  // Retrieve projects as a stream, ordered by timestamp
  Stream<QuerySnapshot> getProjects() {
    return projectsCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserLikedProjects(String userId) {
    print('Querying liked projects for userId: $userId');
    final stream = FirebaseFirestore.instance
        .collectionGroup('likes')
        .where('userId', isEqualTo: userId)
        .snapshots();
    stream.listen((snapshot) {
      print(
          'Liked projects snapshot: ${snapshot.docs.map((doc) => doc.reference.path).toList()}');
      // Log all likes documents to see what's in the subcollections
      FirebaseFirestore.instance
          .collectionGroup('likes')
          .get()
          .then((allLikes) {
        print(
            'All likes documents: ${allLikes.docs.map((doc) => "${doc.reference.path}: ${doc.data()}").toList()}');
      });
    }, onError: (error) {
      print('Error in getUserLikedProjects: $error');
    });
    return stream;
  }
}

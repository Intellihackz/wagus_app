import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Commented out
import 'package:wagus/features/incubator/incubator.dart';

class IncubatorRepository {
  // Reference to the 'projects' collection in Firestore
  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  Future<String> _uploadPdfToStorage(File file, String fileName) async {
    try {
      // Create a reference in Firebase Storage under 'project_pdfs' folder
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('project_pdfs/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(file);
      await uploadTask;

      // Get the download URL
      final String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  // Submit a project with PDFs to Firebase
  Future<void> submitProject(
      Project project, File? whitePaperFile, File? roadMapFile) async {
    try {
      // Upload whitepaper PDF if provided
      String? whitePaperUrl;
      if (whitePaperFile != null) {
        whitePaperUrl = await _uploadPdfToStorage(
          whitePaperFile,
          '${project.name}_whitepaper_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      // Upload roadmap PDF if provided
      String? roadMapUrl;
      if (roadMapFile != null) {
        roadMapUrl = await _uploadPdfToStorage(
          roadMapFile,
          '${project.name}_roadmap_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      // Save project details to Firestore
      await projectsCollection.add({
        'name': project.name,
        'description': project.description,
        'walletAddress': project.walletAddress,
        'gitHubLink': project.gitHubLink,
        'websiteLink': project.websiteLink,
        'whitePaperLink': whitePaperUrl, // Use uploaded URL or null
        'roadmapLink': roadMapUrl, // Use uploaded URL or null
        'socialsLink': project.socialsLink,
        'telegramLink': project.telegramLink,
        'fundingProgress': project.fundingProgress,
        'likes': project.likes,
        'launchDate': project.launchDate.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(), // For ordering
      });
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
}

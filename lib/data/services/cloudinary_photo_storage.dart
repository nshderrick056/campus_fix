import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/uploaded_photo.dart';
import 'photo_storage_service.dart';

/// Cloudinary account settings. Only the cloud name and an UNSIGNED upload
/// preset are used; the API secret never ships in the app.
class CloudinaryConfig {
  const CloudinaryConfig({required this.cloudName, required this.uploadPreset});

  /// Reads `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_UPLOAD_PRESET` passed with
  /// `flutter run --dart-define-from-file=env.json` (env.json is git-ignored;
  /// copy env.example.json).
  const CloudinaryConfig.fromEnvironment()
      : cloudName = const String.fromEnvironment('CLOUDINARY_CLOUD_NAME'),
        uploadPreset = const String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  final String cloudName;
  final String uploadPreset;

  bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  Uri get uploadUri =>
      Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload');
}

/// [PhotoStorageService] using Cloudinary unsigned uploads.
class CloudinaryPhotoStorage implements PhotoStorageService {
  CloudinaryPhotoStorage({
    required this.config,
    http.Client? client,
    this.folder = 'campus_incidents',
  }) : _client = client ?? http.Client();

  final CloudinaryConfig config;
  final String folder;
  final http.Client _client;

  @override
  Future<UploadedPhoto> uploadPhoto(File file) async {
    if (!config.isConfigured) {
      throw const PhotoUploadException(
          'Photo uploads are not configured yet. Please try again later.');
    }
    final request = http.MultipartRequest('POST', config.uploadUri)
      ..fields['upload_preset'] = config.uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on SocketException {
      throw const PhotoUploadException(
          'No connection. Check your internet and try again.');
    } on http.ClientException {
      throw const PhotoUploadException(
          'No connection. Check your internet and try again.');
    }
    return parseUploadResponse(response.statusCode, response.body);
  }

  /// Parses Cloudinary's JSON reply. Visible for tests.
  static UploadedPhoto parseUploadResponse(int statusCode, String body) {
    Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      json = null;
    }
    if (statusCode >= 200 && statusCode < 300 && json is Map) {
      final url = json['secure_url'];
      final publicId = json['public_id'];
      if (url is String && publicId is String) {
        return UploadedPhoto(url: url, publicId: publicId);
      }
    }
    final detail = json is Map && json['error'] is Map
        ? (json['error'] as Map)['message']
        : null;
    throw PhotoUploadException(
      'Photo upload failed${detail is String ? ': $detail' : ''}. '
      'Please try again.',
    );
  }

  /// Inserts `w_<width>,q_auto,f_auto` after `/upload/`. Non-Cloudinary URLs
  /// are returned unchanged.
  @override
  String thumbnailUrl(String url, {int width = 400}) {
    const marker = '/upload/';
    final i = url.indexOf(marker);
    if (i < 0) return url;
    final at = i + marker.length;
    return '${url.substring(0, at)}w_$width,q_auto,f_auto/${url.substring(at)}';
  }
}

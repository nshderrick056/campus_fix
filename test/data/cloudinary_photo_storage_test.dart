import 'dart:convert';
import 'dart:io';

import 'package:campus_incident_app/data/services/cloudinary_photo_storage.dart';
import 'package:campus_incident_app/data/services/photo_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = CloudinaryConfig(cloudName: 'demo', uploadPreset: 'unsigned_preset');
  final storage = CloudinaryPhotoStorage(config: config);

  group('thumbnailUrl', () {
    test('inserts the transformation after /upload/', () {
      expect(
        storage.thumbnailUrl(
            'https://res.cloudinary.com/demo/image/upload/v17/campus_incidents/a.jpg'),
        'https://res.cloudinary.com/demo/image/upload/w_400,q_auto,f_auto/v17/campus_incidents/a.jpg',
      );
      expect(
        storage.thumbnailUrl('https://res.cloudinary.com/demo/image/upload/a.jpg', width: 120),
        'https://res.cloudinary.com/demo/image/upload/w_120,q_auto,f_auto/a.jpg',
      );
    });

    test('leaves other URLs alone', () {
      expect(storage.thumbnailUrl('https://example.com/a.jpg'), 'https://example.com/a.jpg');
    });
  });

  group('parseUploadResponse', () {
    test('reads secure_url and public_id', () {
      final photo = CloudinaryPhotoStorage.parseUploadResponse(
        200,
        jsonEncode({'secure_url': 'https://res.cloudinary.com/x.jpg', 'public_id': 'campus_incidents/x'}),
      );
      expect(photo.url, 'https://res.cloudinary.com/x.jpg');
      expect(photo.publicId, 'campus_incidents/x');
    });

    test('surfaces the Cloudinary error message', () {
      expect(
        () => CloudinaryPhotoStorage.parseUploadResponse(
            400, jsonEncode({'error': {'message': 'Upload preset not found'}})),
        throwsA(isA<PhotoUploadException>()
            .having((e) => e.message, 'message', contains('Upload preset not found'))),
      );
      expect(
        () => CloudinaryPhotoStorage.parseUploadResponse(502, '<html>'),
        throwsA(isA<PhotoUploadException>()),
      );
    });
  });

  group('uploadPhoto', () {
    late File file;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('cloudinary_test');
      file = File('${dir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
      addTearDown(() => dir.delete(recursive: true));
    });

    test('POSTs an unsigned multipart upload to the right endpoint', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({'secure_url': 'https://res.cloudinary.com/demo/p.jpg', 'public_id': 'campus_incidents/p'}),
          200,
        );
      });

      final photo = await CloudinaryPhotoStorage(config: config, client: client).uploadPhoto(file);

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'https://api.cloudinary.com/v1_1/demo/image/upload');
      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      final body = utf8.decode(sent.bodyBytes, allowMalformed: true);
      expect(body, contains('unsigned_preset'));
      expect(body, contains('campus_incidents'));
      expect(body, isNot(contains('api_secret')));
      expect(photo.publicId, 'campus_incidents/p');
    });

    test('fails clearly when not configured', () async {
      final unconfigured = CloudinaryPhotoStorage(
          config: const CloudinaryConfig(cloudName: '', uploadPreset: ''));
      await expectLater(unconfigured.uploadPhoto(file), throwsA(isA<PhotoUploadException>()));
    });
  });
}

// Template for local, git-ignored configuration.
//
// Setup:
//   1. Copy this file to `lib/config/env.dart` (already in .gitignore).
//   2. Replace the placeholders with your Cloudinary cloud name and the
//      name of an UNSIGNED upload preset.
//
// Never put the Cloudinary API secret in the app: unsigned uploads only
// need the cloud name and the preset name.

abstract final class Env {
  static const cloudinaryCloudName = 'your-cloud-name';
  static const cloudinaryUploadPreset = 'your-unsigned-upload-preset';
}

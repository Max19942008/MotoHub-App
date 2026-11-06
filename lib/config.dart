/// Backend address. Override for local testing:
///   flutter run --dart-define=API_URL=http://192.168.1.10:3007
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://motohub-ci05.onrender.com',
);

const String graphqlUrl = '$apiUrl/graphql';

/// Listing images are stored either as full URLs (Cloudinary) or as paths
/// relative to the API ("uploads/property/x.jpg").
String imageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$apiUrl/$path';
}

const int pageSize = 10;

/// Public website — privacy policy and account deletion pages (linked from Google Play).
const String siteUrl = 'https://ignition-plum.vercel.app';
const String privacyUrl = '$siteUrl/privacy';

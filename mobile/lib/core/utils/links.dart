import 'package:url_launcher/url_launcher.dart';

import 'package:ufuq_imperium/core/config/app_config.dart';

/// Resolves a value stored by the backend (path, `/storage/...`, full URL) to a loadable URL.
String mediaUrl(String? value) {
  if (value == null || value.isEmpty || value.startsWith('/tmp/')) return '';
  final origin = AppConfig.origin;
  final storage = _storagePath(value);
  if (storage.isNotEmpty) return '$origin/storage/$storage';
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) return value;
  if (value.startsWith('/')) return '$origin$value';
  return '$origin/storage/${value.replaceFirst(RegExp(r'^/+'), '')}';
}

String _storagePath(String value) {
  var path = value;
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(value)) {
    path = Uri.tryParse(value)?.path ?? '';
  }
  const marker = '/storage/';
  final at = path.indexOf(marker);
  if (at == -1) return '';
  return path.substring(at + marker.length).replaceFirst(RegExp(r'^/+'), '');
}

Uri telUri(String phone) =>
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));

Uri mailUri(String email) => Uri(scheme: 'mailto', path: email);

Uri whatsappUri(String number) {
  var digits = number.replaceAll(RegExp(r'\D'), '');
  // wa.me needs the country code: 00… is the international prefix, a single leading 0 is a local Syrian number.
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0')) {
    digits = '963${digits.substring(1)}';
  }
  return Uri.parse('https://wa.me/$digits');
}

/// Accepts a full link, `facebook.com/page` or a plain handle; anything else is hidden.
String socialLink(String value, String base) {
  final text = value.trim();
  if (text.isEmpty) return '';
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(text)) return text;
  if (RegExp(
    r'^([a-z0-9-]+\.)+[a-z]{2,}(/|$)',
    caseSensitive: false,
  ).hasMatch(text)) {
    return 'https://$text';
  }
  final handle = text.replaceFirst(RegExp(r'^@'), '');
  return RegExp(r'^[A-Za-z0-9._-]{2,60}$').hasMatch(handle)
      ? '$base$handle'
      : '';
}

List<String> paragraphs(String? text) => (text ?? '')
    .split(RegExp(r'\n\n+'))
    .map((part) => part.trim())
    .where((part) => part.isNotEmpty)
    .toList();

/// A YouTube or Vimeo link as a thumbnail-able id, or null.
({String kind, String id})? videoRef(String link) {
  final url = Uri.tryParse(link);
  if (url == null) return null;
  final host = url.host
      .replaceFirst(RegExp(r'^www\.'), '')
      .replaceFirst(RegExp(r'^m\.'), '');
  var id = '';
  if (host == 'youtu.be') {
    id = url.pathSegments.isEmpty ? '' : url.pathSegments.first;
  } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
    final parts = url.pathSegments.where((p) => p.isNotEmpty).toList();
    id =
        url.queryParameters['v'] ??
        (parts.isNotEmpty &&
                const ['embed', 'shorts', 'live'].contains(parts.first) &&
                parts.length > 1
            ? parts[1]
            : '');
  }
  if (RegExp(r'^[\w-]{6,20}$').hasMatch(id)) return (kind: 'youtube', id: id);
  if (host == 'vimeo.com' || host == 'player.vimeo.com') {
    final vimeo = url.pathSegments.where((p) => RegExp(r'^\d+$').hasMatch(p));
    if (vimeo.isNotEmpty) return (kind: 'vimeo', id: vimeo.first);
  }
  return null;
}

/// Opens a link in the phone's own apps (dialer, mail, browser, WhatsApp). No WebView.
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

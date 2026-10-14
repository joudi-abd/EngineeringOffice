import 'package:flutter_test/flutter_test.dart';
import 'package:ufuq_imperium/core/utils/links.dart';

void main() {
  test('whatsappUri adds the country code to local numbers', () {
    expect(
      whatsappUri('0944 123 456').toString(),
      'https://wa.me/963944123456',
    );
    expect(
      whatsappUri('00971 50 000 0000').toString(),
      'https://wa.me/971500000000',
    );
    expect(
      whatsappUri('+963 944 123 456').toString(),
      'https://wa.me/963944123456',
    );
  });

  test('telUri keeps digits and plus only', () {
    expect(telUri('+963 11 000-0000').toString(), 'tel:+963110000000');
  });

  test('socialLink accepts links, domains and handles, hides the rest', () {
    const base = 'https://www.instagram.com/';
    expect(
      socialLink('https://instagram.com/x', base),
      'https://instagram.com/x',
    );
    expect(socialLink('instagram.com/x', base), 'https://instagram.com/x');
    expect(socialLink('@ufuq', base), '${base}ufuq');
    expect(socialLink('not a link!', base), '');
    expect(socialLink('', base), '');
  });

  test('mediaUrl resolves storage paths against the API origin', () {
    expect(mediaUrl(null), '');
    expect(mediaUrl('/tmp/php123'), '');
    expect(mediaUrl('projects/a.jpg'), endsWith('/storage/projects/a.jpg'));
    expect(
      mediaUrl('http://localhost:8000/storage/projects/a.jpg'),
      endsWith('/storage/projects/a.jpg'),
    );
    expect(
      mediaUrl('https://cdn.example.com/a.jpg'),
      'https://cdn.example.com/a.jpg',
    );
  });
}

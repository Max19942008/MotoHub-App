// Uzbek labels for backend enum values, plus formatting helpers.

const motorbikeBrands = [
  'HONDA',
  'YAMAHA',
  'SUZUKI',
  'KAWASAKI',
  'DUCATI',
  'BMW',
  'HARLEY_DAVIDSON'
];
const motorbikeTypes = ['SPORT', 'CRUISER', 'SCOOTER'];
const motorbikeConditions = ['NEW', 'USED'];

const partBrands = [...motorbikeBrands, 'UNIVERSAL', 'OTHER'];
const partConditions = ['NEW', 'USED', 'REFURBISHED'];
const sparePartTypes = [
  'ENGINE',
  'EXHAUST',
  'BRAKE',
  'SUSPENSION',
  'TIRE',
  'BATTERY',
  'FILTER',
  'CHAIN',
  'ELECTRICAL',
  'BODY_PANEL',
  'OTHER',
];
const accessoryTypes = [
  'HELMET',
  'GLOVES',
  'JACKET',
  'BOOTS',
  'LUGGAGE',
  'PHONE_MOUNT',
  'COVER',
  'OTHER'
];

const locations = [
  'TASHKENT',
  'ANDIJAN',
  'BUKHARA',
  'FERGANA',
  'JIZZAKH',
  'KHOREZM',
  'NAMANGAN',
  'NAVOI',
  'KASHKADARYA',
  'SAMARKAND',
  'SIRDARYA',
  'SURKHANDARYA',
  'KARAKALPAKSTAN',
];

const _labels = <String, String>{
  // brands
  'HARLEY_DAVIDSON': 'Harley-Davidson', 'BMW': 'BMW', 'UNIVERSAL': 'Universal',
  // motorbike types
  'SPORT': 'Sport', 'CRUISER': 'Kruizer', 'SCOOTER': 'Skuter',
  // conditions
  'NEW': 'Yangi', 'USED': 'Ishlatilgan', 'REFURBISHED': 'Tiklangan',
  // part categories & types
  'SPARE_PART': 'Ehtiyot qism', 'ACCESSORY': 'Aksessuar',
  'ENGINE': 'Dvigatel', 'EXHAUST': 'Glushitel', 'BRAKE': 'Tormoz',
  'SUSPENSION': 'Amortizator',
  'TIRE': 'Shina', 'BATTERY': 'Akkumulyator', 'FILTER': 'Filtr',
  'CHAIN': 'Zanjir',
  'ELECTRICAL': 'Elektrika', 'BODY_PANEL': 'Kuzov detali',
  'HELMET': 'Dubulg\'a',
  'GLOVES': 'Qo\'lqop', 'JACKET': 'Kurtka', 'BOOTS': 'Botinka',
  'LUGGAGE': 'Yukxalta',
  'PHONE_MOUNT': 'Telefon ushlagich', 'COVER': 'G\'ilof', 'OTHER': 'Boshqa',
  // regions
  'TASHKENT': 'Toshkent', 'ANDIJAN': 'Andijon', 'BUKHARA': 'Buxoro',
  'FERGANA': 'Farg\'ona',
  'JIZZAKH': 'Jizzax', 'KHOREZM': 'Xorazm', 'NAMANGAN': 'Namangan',
  'NAVOI': 'Navoiy',
  'KASHKADARYA': 'Qashqadaryo', 'SAMARKAND': 'Samarqand',
  'SIRDARYA': 'Sirdaryo',
  'SURKHANDARYA': 'Surxondaryo', 'KARAKALPAKSTAN': 'Qoraqalpog\'iston',
};

/// "HONDA" -> "Honda", "TASHKENT" -> "Toshkent".
String label(String value) {
  final known = _labels[value];
  if (known != null) return known;
  if (value.isEmpty) return value;
  final words = value.toLowerCase().split('_');
  return words
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// 12500 -> "12 500".
String groupDigits(num n, {String sep = ' '}) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(sep);
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatPrice(num price, String currency) {
  switch (currency) {
    case 'USD':
      return '\$${groupDigits(price, sep: ',')}'; // same as the website
    case 'UZS':
      return '${groupDigits(price)} so\'m';
    case 'KRW':
      return '₩${groupDigits(price)}';
    default:
      return '${groupDigits(price)} $currency';
  }
}

/// Descriptions come from a rich-text editor; show them as plain text.
String plainText(String? html) {
  if (html == null) return '';
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} daqiqa oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  if (diff.inDays < 30) return '${diff.inDays} kun oldin';
  if (diff.inDays < 365) return '${diff.inDays ~/ 30} oy oldin';
  return '${diff.inDays ~/ 365} yil oldin';
}

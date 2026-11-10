import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';

const _violet = Color(0xFF667EEA);
const _purple = Color(0xFF764BA2);

/// The site's "Yangi mototsikl qo'shish" / "Qism qo'shish" form.
/// Pass [bike] or [part] to edit an existing listing. Pops `true` when saved.
class AddListingScreen extends StatefulWidget {
  const AddListingScreen(
      {super.key, required this.isPart, this.bike, this.part})
      : assert(!isPart || bike == null);
  final bool isPart;
  final Motorbike? bike;
  final Part? part;

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  late final _title =
      TextEditingController(text: widget.bike?.title ?? widget.part?.title);
  late final _price = TextEditingController(
      text: _num(widget.bike?.price ?? widget.part?.price));
  late final _address = TextEditingController(text: widget.bike?.address);
  late final _year = TextEditingController(text: _num(widget.bike?.year));
  late final _engine = TextEditingController(text: _num(widget.bike?.engineCc));
  late final _mileage = TextEditingController(text: _num(widget.bike?.mileage));
  late final _stock =
      TextEditingController(text: _num(widget.part?.stock) ?? '1');
  late final _desc = TextEditingController(
      text: plainText(widget.bike?.description ?? widget.part?.description));

  late String _currency =
      widget.bike?.currency ?? widget.part?.currency ?? 'USD';
  late String? _location =
      _nonEmpty(widget.bike?.location ?? widget.part?.location);
  late String? _brand = _nonEmpty(widget.bike?.brand ?? widget.part?.brand);
  late String? _condition =
      _nonEmpty(widget.bike?.condition ?? widget.part?.condition);
  late String? _type = _nonEmpty(widget.bike?.type ?? widget.part?.type);
  late String _category = widget.part?.category ?? 'SPARE_PART';
  late bool _barter = widget.bike?.barter ?? widget.part?.barter ?? false;
  late bool _rent = widget.bike?.rent ?? false;
  late final List<String> _images = [
    ...?widget.bike?.images,
    ...?widget.part?.images,
  ];
  bool _uploading = false;
  bool _saving = false;

  bool get _editing => widget.bike != null || widget.part != null;

  static String? _num(num? n) => n == null || n == 0 ? null : '$n';
  static String? _nonEmpty(String? s) => s == null || s.isEmpty ? null : s;

  @override
  void dispose() {
    for (final c in [
      _title,
      _price,
      _address,
      _year,
      _engine,
      _mileage,
      _stock,
      _desc
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _addPhotos() async {
    final files = await ImagePicker()
        .pickMultiImage(maxWidth: 2048, maxHeight: 2048, imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final f in files.take(10 - _images.length)) {
        final path = await Repository.instance
            .uploadImage(f.path, widget.isPart ? 'part' : 'property');
        if (!mounted) return;
        setState(() => _images.add(path));
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Same rules as the backend DTOs, checked here so the user sees Uzbek text.
  String? _problem() {
    final title = _title.text.trim();
    if (title.length < 3 || title.length > 100) {
      return "Sarlavha 3–100 belgidan iborat bo'lishi kerak";
    }
    if ((num.tryParse(_price.text.trim()) ?? 0) <= 0) return 'Narxni kiriting';
    if (_type == null) return 'Turni tanlang';
    if (_location == null) return 'Manzilni tanlang';
    if (_brand == null) return 'Brendni tanlang';
    if (_condition == null) return 'Holatini tanlang';
    if (_images.isEmpty) return "Kamida bitta rasm qo'shing";
    final desc = _desc.text.trim();
    if (desc.isNotEmpty && (desc.length < 5 || desc.length > 500)) {
      return "Tavsif 5–500 belgidan iborat bo'lishi kerak";
    }
    if (widget.isPart) {
      if ((int.tryParse(_stock.text.trim()) ?? 0) < 1) {
        return 'Omborda kamida 1 dona bo\'lishi kerak';
      }
    } else {
      final address = _address.text.trim();
      if (address.length < 3 || address.length > 100) {
        return "Manzil 3–100 belgidan iborat bo'lishi kerak";
      }
      final year = int.tryParse(_year.text.trim()) ?? 0;
      if (year < 1950 || year > DateTime.now().year + 1) {
        return 'Yilni kiriting';
      }
      if ((int.tryParse(_engine.text.trim()) ?? 0) < 125) {
        return 'Dvigatel hajmi kamida 125 CC';
      }
      if ((int.tryParse(_mileage.text.trim()) ?? 0) < 10) {
        return 'Yurgan masofa kamida 10 km';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _problem();
    if (problem != null) return _snack(problem);
    final desc = _desc.text.trim();
    final price = num.parse(_price.text.trim());
    setState(() => _saving = true);
    try {
      if (widget.isPart) {
        await Repository.instance.savePart({
          'partCategory': _category,
          'partType': _type,
          'partLocation': _location,
          'partBrand': _brand,
          'partCondition': _condition,
          'partTitle': _title.text.trim(),
          'partPrice': price,
          'partCurrency': _currency,
          'partStockCount': int.parse(_stock.text.trim()),
          'partImages': _images,
          if (desc.isNotEmpty) 'partDesc': desc,
          'partBarter': _barter,
        }, id: widget.part?.id);
      } else {
        await Repository.instance.saveMotorbike({
          'propertyType': _type,
          'propertyLocation': _location,
          'propertyBrand': _brand,
          'propertyCondition': _condition,
          'propertyAddress': _address.text.trim(),
          'propertyTitle': _title.text.trim(),
          'propertyPrice': price,
          'propertyCurrency': _currency,
          'propertyYear': int.parse(_year.text.trim()),
          'propertyEngineCc': int.parse(_engine.text.trim()),
          'propertyMileAge': int.parse(_mileage.text.trim()),
          'propertyImages': _images,
          if (desc.isNotEmpty) 'propertyDesc': desc,
          'propertyBarter': _barter,
          'propertyRent': _rent,
        }, id: widget.bike?.id);
      }
      if (!mounted) return;
      _snack(_editing ? 'E\'lon yangilandi' : 'E\'lon joylandi');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------ widgets

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: _violet.withValues(alpha: 0.2), width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _violet, width: 2)),
      );

  Widget _labeled(String label, Widget field) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Brand.ink)),
            const SizedBox(height: 8),
            field,
          ],
        ),
      );

  Widget _text(String label, TextEditingController c, String hint,
          {bool number = false, int lines = 1}) =>
      _labeled(
        label,
        TextField(
          controller: c,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 4,
          keyboardType: number ? TextInputType.number : null,
          decoration: _decoration(hint),
        ),
      );

  Widget _select(String caption, String? value, List<String> options,
          ValueChanged<String?> onChanged,
          {String Function(String)? text}) =>
      _labeled(
        caption,
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : null,
          isExpanded: true,
          hint:
              const Text('Tanlang', style: TextStyle(color: Color(0xFF999999))),
          decoration: _decoration(''),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text((text ?? label)(o))),
          ],
          onChanged: onChanged,
        ),
      );

  Widget _row(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final isPart = widget.isPart;
    final types = isPart
        ? (_category == 'ACCESSORY' ? accessoryTypes : sparePartTypes)
        : motorbikeTypes;
    String yesNo(String v) => v == 'true' ? 'Ha' : "Yo'q";
    return Scaffold(
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 36)),
      backgroundColor: const Color(0xFFF6F6F6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, _purple]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _editing
                        ? "E'lonni tahrirlash"
                        : (isPart
                            ? "Qism qo'shish"
                            : "Yangi mototsikl qo'shish"),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text('We are glad to see you again!',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F9FF)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _violet.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _text('Sarlavha', _title, 'Sarlavha'),
                _row(
                  _text('Narx', _price, 'Narx', number: true),
                  _select('Valyuta', _currency, const ['USD', 'UZS', 'KRW'],
                      (v) => setState(() => _currency = v ?? 'USD'),
                      text: (v) => v),
                ),
                if (isPart)
                  _select(
                      'Turkum',
                      _category,
                      const ['SPARE_PART', 'ACCESSORY'],
                      (v) => setState(() {
                            _category = v ?? 'SPARE_PART';
                            _type = null;
                          }),
                      text: (v) =>
                          v == 'ACCESSORY' ? 'Aksessuar' : 'Ehtiyot qism'),
                _row(
                  _select('Turni tanlang', _type, types,
                      (v) => setState(() => _type = v)),
                  _select('Manzilni tanlang', _location, locations,
                      (v) => setState(() => _location = v)),
                ),
                if (!isPart) _text('Manzil', _address, 'Manzil'),
                _row(
                  _select('Ayirboshlash', '$_barter', const ['true', 'false'],
                      (v) => setState(() => _barter = v == 'true'),
                      text: yesNo),
                  isPart
                      ? _text('Omborda (dona)', _stock, '1', number: true)
                      : _select('Ijara', '$_rent', const ['true', 'false'],
                          (v) => setState(() => _rent = v == 'true'),
                          text: yesNo),
                ),
                _row(
                  _select(
                      'Brend',
                      _brand,
                      isPart ? partBrands : motorbikeBrands,
                      (v) => setState(() => _brand = v)),
                  _select(
                      'Holati',
                      _condition,
                      isPart ? partConditions : motorbikeConditions,
                      (v) => setState(() => _condition = v)),
                ),
                if (!isPart) ...[
                  _row(
                    _text('Yil', _year, 'Masalan, 2020', number: true),
                    _text('Dvigatel (CC)', _engine, 'Masalan, 250',
                        number: true),
                  ),
                  _text('Yurgan masofa', _mileage, 'Km', number: true),
                ],
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (r) =>
                      const LinearGradient(colors: [_violet, _purple])
                          .createShader(r),
                  child: const Text("E'lon tavsifi",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(height: 14),
                _text('Tavsif', _desc, "E'lon haqida yozing", lines: 5),
                const Text("E'loningiz rasmlarini yuklang",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Brand.ink)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _violet.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Column(children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 40, color: _violet),
                    const SizedBox(height: 8),
                    const Text('Rasmlarni tanlang',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Brand.ink)),
                    const SizedBox(height: 4),
                    const Text(
                        "Rasmlar JPEG yoki PNG formatida bo'lishi kerak (10 tagacha)",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: Brand.muted)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _uploading || _images.length >= 10
                          ? null
                          : _addPhotos,
                      icon: _uploading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.photo_library_outlined),
                      label: const Text('Fayllarni tanlash'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Brand.ink,
                        side: const BorderSide(color: Brand.ink),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final img in _images)
                        Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                                width: 96, height: 76, child: NetImage(img)),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => setState(() => _images.remove(img)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.red),
                              ),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Brand.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saving || _uploading ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Saqlash'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

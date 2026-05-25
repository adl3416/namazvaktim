import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';

class DistrictSelectionScreen extends StatefulWidget {
  const DistrictSelectionScreen({
    super.key,
    required this.city,
    required this.countryName,
  });

  final String city;
  final String countryName;

  @override
  State<DistrictSelectionScreen> createState() => _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen> {
  static const Map<String, int> _plateByCity = {
    'ADANA': 1,
    'ADIYAMAN': 2,
    'AFYONKARAHISAR': 3,
    'AGRI': 4,
    'AMASYA': 5,
    'ANKARA': 6,
    'ANTALYA': 7,
    'ARTVIN': 8,
    'AYDIN': 9,
    'BALIKESIR': 10,
    'BILECIK': 11,
    'BINGOL': 12,
    'BITLIS': 13,
    'BOLU': 14,
    'BURDUR': 15,
    'BURSA': 16,
    'CANAKKALE': 17,
    'CANKIRI': 18,
    'CORUM': 19,
    'DENIZLI': 20,
    'DIYARBAKIR': 21,
    'EDIRNE': 22,
    'ELAZIG': 23,
    'ERZINCAN': 24,
    'ERZURUM': 25,
    'ESKISEHIR': 26,
    'GAZIANTEP': 27,
    'GIRESUN': 28,
    'GUMUSHANE': 29,
    'HAKKARI': 30,
    'HATAY': 31,
    'ISPARTA': 32,
    'MERSIN': 33,
    'ISTANBUL': 34,
    'IZMIR': 35,
    'KARS': 36,
    'KASTAMONU': 37,
    'KAYSERI': 38,
    'KIRKLARELI': 39,
    'KIRSEHIR': 40,
    'KOCAELI': 41,
    'KONYA': 42,
    'KUTAHYA': 43,
    'MALATYA': 44,
    'MANISA': 45,
    'KAHRAMANMARAS': 46,
    'MARDIN': 47,
    'MUGLA': 48,
    'MUS': 49,
    'NEVSEHIR': 50,
    'NIGDE': 51,
    'ORDU': 52,
    'RIZE': 53,
    'SAKARYA': 54,
    'SAMSUN': 55,
    'SIIRT': 56,
    'SINOP': 57,
    'SIVAS': 58,
    'TEKIRDAG': 59,
    'TOKAT': 60,
    'TRABZON': 61,
    'TUNCELI': 62,
    'SANLIURFA': 63,
    'USAK': 64,
    'VAN': 65,
    'YOZGAT': 66,
    'ZONGULDAK': 67,
    'AKSARAY': 68,
    'BAYBURT': 69,
    'KARAMAN': 70,
    'KIRIKKALE': 71,
    'BATMAN': 72,
    'SIRNAK': 73,
    'BARTIN': 74,
    'ARDAHAN': 75,
    'IGDIR': 76,
    'YALOVA': 77,
    'KARABUK': 78,
    'KILIS': 79,
    'OSMANIYE': 80,
    'DUZCE': 81,
  };

  static const Map<String, String> _textFixes = {
    'Ä°': 'İ',
    'Ä±': 'ı',
    'Ã‡': 'Ç',
    'Ã§': 'ç',
    'Ã–': 'Ö',
    'Ã¶': 'ö',
    'Ãœ': 'Ü',
    'Ã¼': 'ü',
    'Äž': 'Ğ',
    'ÄŸ': 'ğ',
    'Åž': 'Ş',
    'ÅŸ': 'ş',
  };

  final TextEditingController _districtController = TextEditingController();

  bool _isLoading = false;
  bool _isDistrictsLoading = true;
  String? _districtLoadError;
  List<String> _districts = const [];

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  List<String> get _filteredDistricts {
    final query = _normalizeLookupValue(_districtController.text);
    if (query.isEmpty) {
      return _districts;
    }

    return _districts
        .where((district) => _normalizeLookupValue(district).contains(query))
        .toList();
  }

  String _text(
    String locale, {
    required String tr,
    required String en,
    required String ar,
  }) {
    switch (locale) {
      case 'tr':
        return tr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  Future<void> _loadDistricts() async {
    final plateCode = _plateByCity[_normalizeLookupValue(widget.city)];

    if (plateCode == null) {
      setState(() {
        _isDistrictsLoading = false;
      });
      return;
    }

    try {
      final rawJson = await rootBundle.loadString('lib/data/tr_districts_raw.json');
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      final districts = decoded
          .whereType<Map<String, dynamic>>()
          .where((entry) => entry['il_plaka'] == plateCode)
          .map((entry) => _cleanText(entry['ilce_adi']?.toString() ?? ''))
          .where((district) => district.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) =>
            _normalizeLookupValue(a).compareTo(_normalizeLookupValue(b)));

      if (!mounted) {
        return;
      }

      setState(() {
        _districts = districts;
        _isDistrictsLoading = false;
        _districtLoadError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDistrictsLoading = false;
        _districtLoadError = 'load_failed';
      });
    }
  }

  Future<void> _continue({String? district}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.setManualLocation(
        widget.city,
        widget.countryName,
        district: district ?? _districtController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) {
        return;
      }

      final locale = context.read<AppSettings>().language;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              locale,
              tr: 'İlçe güncellenirken hata oluştu: $e',
              en: 'An error occurred while updating the district: $e',
              ar: 'حدث خطأ أثناء تحديث المنطقة: $e',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;
    final filteredDistricts = _filteredDistricts;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _text(
            locale,
            tr: '${widget.city} ilçeleri',
            en: '${widget.city} districts',
            ar: 'مناطق ${widget.city}',
          ),
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(
                locale,
                tr: 'İlçe seçebilir ya da boş bırakıp şehir ile devam edebilirsin.',
                en: 'You can choose a district or leave it empty to continue with the city.',
                ar: 'يمكنك اختيار منطقة أو تركها فارغة والمتابعة بالمدينة.',
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _districtController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _text(
                  locale,
                  tr: 'İlçe ara veya yaz',
                  en: 'Search or type a district',
                  ar: 'ابحث عن منطقة أو اكتبها',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkAccentPrimary
                        : AppColors.accentPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildDistrictSection(
                locale: locale,
                isDark: isDark,
                filteredDistricts: filteredDistricts,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _continue,
                child: Text(
                  _text(
                    locale,
                    tr: _districtController.text.trim().isEmpty
                        ? 'Şehir ile devam et'
                        : 'İlçe ile devam et',
                    en: _districtController.text.trim().isEmpty
                        ? 'Continue with city'
                        : 'Continue with district',
                    ar: _districtController.text.trim().isEmpty
                        ? 'المتابعة بالمدينة'
                        : 'المتابعة بالمنطقة',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictSection({
    required String locale,
    required bool isDark,
    required List<String> filteredDistricts,
  }) {
    if (_isDistrictsLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark
              ? AppColors.darkAccentPrimary
              : AppColors.accentPrimary,
        ),
      );
    }

    if (_districtLoadError != null) {
      return _buildInfoText(
        isDark: isDark,
        text: _text(
          locale,
          tr: 'İlçe listesi yüklenemedi. İstersen ilçeyi yazarak devam edebilirsin.',
          en: 'The district list could not be loaded. You can still type a district and continue.',
          ar: 'تعذر تحميل قائمة المناطق. ما زال بإمكانك كتابة المنطقة والمتابعة.',
        ),
      );
    }

    if (_districts.isEmpty) {
      return _buildInfoText(
        isDark: isDark,
        text: _text(
          locale,
          tr: 'Bu şehir için ilçe listesi bulunamadı. İstersen ilçeyi elle yazabilirsin.',
          en: 'No district list was found for this city. You can still type the district manually.',
          ar: 'لم يتم العثور على قائمة مناطق لهذه المدينة. ما زال بإمكانك كتابة المنطقة يدويًا.',
        ),
      );
    }

    if (filteredDistricts.isEmpty) {
      return _buildInfoText(
        isDark: isDark,
        text: _text(
          locale,
          tr: 'Aramana uyan ilçe bulunamadı.',
          en: 'No district matched your search.',
          ar: 'لم يتم العثور على منطقة مطابقة لبحثك.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text(
            locale,
            tr: 'Tüm ilçeler',
            en: 'All districts',
            ar: 'كل المناطق',
          ),
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredDistricts.map((district) {
                return ActionChip(
                  label: Text(district),
                  onPressed: _isLoading ? null : () => _continue(district: district),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText({
    required bool isDark,
    required String text,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  static String _cleanText(String value) {
    var cleaned = value.trim();
    _textFixes.forEach((broken, fixed) {
      cleaned = cleaned.replaceAll(broken, fixed);
    });
    return cleaned;
  }

  static String _normalizeLookupValue(String value) {
    var normalized = _cleanText(value).toUpperCase();

    const replacements = {
      'İ': 'I',
      'I': 'I',
      'ı': 'I',
      'Ş': 'S',
      'ş': 'S',
      'Ğ': 'G',
      'ğ': 'G',
      'Ü': 'U',
      'ü': 'U',
      'Ö': 'O',
      'ö': 'O',
      'Ç': 'C',
      'ç': 'C',
      'Â': 'A',
      'â': 'A',
      'Î': 'I',
      'î': 'I',
      'Û': 'U',
      'û': 'U',
      "'": '',
      '`': '',
      '(': ' ',
      ')': ' ',
      '-': ' ',
      '.': ' ',
      ',': ' ',
    };

    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

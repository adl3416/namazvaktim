import 'package:flutter/material.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';
import 'package:namaz_vakitleri/providers/app_settings.dart';
import 'package:namaz_vakitleri/providers/prayer_provider.dart';
import 'package:provider/provider.dart';

import 'common_widgets.dart';

class CitySearchDialog extends StatefulWidget {
  final PrayerProvider prayerProvider;

  const CitySearchDialog({super.key, required this.prayerProvider});

  @override
  State<CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<CitySearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _hasFocus = false;
  String? _selectedCountry;

  final List<String> _countryCodes = const [
    'TR',
    'DE',
    'SA',
    'AE',
    'US',
    'GB',
    'FR',
    'NL',
    'CA',
    'AU',
  ];

  final Map<String, List<String>> _citiesByCountry = {
    'TR': [
      'Istanbul',
      'Ankara',
      'Izmir',
      'Bursa',
      'Antalya',
      'Adana',
      'Gaziantep',
      'Konya',
      'Kayseri',
      'Samsun',
      'Diyarbakır',
      'Mersin',
      'Eskişehir',
      'Malatya',
      'Erzurum',
      'Rize',
      'Çanakkale',
      'Muğla',
      'Denizli',
      'Trabzon',
    ],
    'DE': [
      'Berlin',
      'Hamburg',
      'Munich',
      'Cologne',
      'Frankfurt',
      'Stuttgart',
      'Düsseldorf',
      'Dortmund',
      'Essen',
      'Leipzig',
    ],
    'SA': [
      'Mecca',
      'Medina',
      'Riyadh',
      'Jeddah',
      'Dammam',
      'Taif',
      'Khobar',
      'Abha',
      'Tabuk',
      'Hail',
    ],
    'AE': [
      'Dubai',
      'Abu Dhabi',
      'Sharjah',
      'Ajman',
      'Ras Al Khaimah',
      'Fujairah',
      'Umm Al Quwain',
    ],
    'US': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
      'Dallas',
      'San Jose',
    ],
    'GB': [
      'London',
      'Birmingham',
      'Manchester',
      'Liverpool',
      'Leeds',
      'Glasgow',
      'Edinburgh',
      'Bristol',
      'Cardiff',
      'Belfast',
    ],
    'FR': [
      'Paris',
      'Marseille',
      'Lyon',
      'Toulouse',
      'Nice',
      'Nantes',
      'Strasbourg',
      'Montpellier',
      'Bordeaux',
      'Lille',
    ],
    'NL': [
      'Amsterdam',
      'Rotterdam',
      'The Hague',
      'Utrecht',
      'Eindhoven',
      'Tilburg',
      'Groningen',
      'Almere',
      'Breda',
      'Nijmegen',
    ],
    'CA': [
      'Toronto',
      'Montreal',
      'Vancouver',
      'Calgary',
      'Edmonton',
      'Ottawa',
      'Winnipeg',
      'Quebec City',
      'Hamilton',
      'Kitchener',
    ],
    'AU': [
      'Sydney',
      'Melbourne',
      'Brisbane',
      'Perth',
      'Adelaide',
      'Gold Coast',
      'Canberra',
      'Newcastle',
      'Central Coast',
      'Wollongong',
    ],
  };

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  String _text(
    String language, {
    required String tr,
    required String en,
    required String ar,
  }) {
    switch (language) {
      case 'tr':
        return tr;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  String _countryApiName(String code) {
    switch (code) {
      case 'TR':
        return 'Turkey';
      case 'DE':
        return 'Germany';
      case 'SA':
        return 'Saudi Arabia';
      case 'AE':
        return 'United Arab Emirates';
      case 'US':
        return 'United States';
      case 'GB':
        return 'United Kingdom';
      case 'FR':
        return 'France';
      case 'NL':
        return 'Netherlands';
      case 'CA':
        return 'Canada';
      case 'AU':
        return 'Australia';
      default:
        return 'Turkey';
    }
  }

  String _countryLabel(String code, String language) {
    switch (code) {
      case 'TR':
        return _text(language, tr: 'Türkiye', en: 'Turkey', ar: 'تركيا');
      case 'DE':
        return _text(language, tr: 'Almanya', en: 'Germany', ar: 'ألمانيا');
      case 'SA':
        return _text(
          language,
          tr: 'Suudi Arabistan',
          en: 'Saudi Arabia',
          ar: 'السعودية',
        );
      case 'AE':
        return _text(
          language,
          tr: 'Birleşik Arap Emirlikleri',
          en: 'United Arab Emirates',
          ar: 'الإمارات العربية المتحدة',
        );
      case 'US':
        return _text(
          language,
          tr: 'Amerika Birleşik Devletleri',
          en: 'United States',
          ar: 'الولايات المتحدة',
        );
      case 'GB':
        return _text(
          language,
          tr: 'Birleşik Krallık',
          en: 'United Kingdom',
          ar: 'المملكة المتحدة',
        );
      case 'FR':
        return _text(language, tr: 'Fransa', en: 'France', ar: 'فرنسا');
      case 'NL':
        return _text(language, tr: 'Hollanda', en: 'Netherlands', ar: 'هولندا');
      case 'CA':
        return _text(language, tr: 'Kanada', en: 'Canada', ar: 'كندا');
      case 'AU':
        return _text(
          language,
          tr: 'Avustralya',
          en: 'Australia',
          ar: 'أستراليا',
        );
      default:
        return code;
    }
  }

  Future<void> _selectCity(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.prayerProvider.setManualLocation(
        city,
        _countryApiName(_selectedCountry ?? 'TR'),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final locale = context.read<AppSettings>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                locale,
                tr: 'Şehir bulunamadı: $e',
                en: 'City not found: $e',
                ar: 'لم يتم العثور على المدينة: $e',
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<AppSettings>().language;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedCountry == null
                  ? AppLocalizations.translate('select_country', locale)
                  : AppLocalizations.translate('search_city', locale),
              style: AppTypography.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_selectedCountry == null) ...[
              Text(
                _text(
                  locale,
                  tr: 'Ülke seçin',
                  en: 'Choose a country',
                  ar: 'اختر دولة',
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _countryCodes.map((code) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCountry = code;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBgSecondary
                                : AppColors.lightBgSecondary,
                            border: Border.all(
                              color: AppColors.divider,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            _countryLabel(code, locale),
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedCountry = null;
                        _controller.clear();
                      });
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_countryLabel(_selectedCountry!, locale)} - ${_text(locale, tr: 'Şehir seçin', en: 'Choose a city', ar: 'اختر مدينة')}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText:
                      '${_countryLabel(_selectedCountry!, locale)} ${_text(locale, tr: 'için şehir arayın...', en: 'city search...', ar: 'ابحث عن مدينة...')}',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextLight
                        : AppColors.textLight,
                  ),
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                    ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _selectCity(value);
                  }
                },
              ),
              SizedBox(height: AppSpacing.xl),
              if (!_hasFocus && _controller.text.trim().isEmpty) ...[
                Text(
                  '${_countryLabel(_selectedCountry!, locale)} ${_text(locale, tr: 'Şehirleri', en: 'Cities', ar: 'المدن')}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (_citiesByCountry[_selectedCountry] ?? [])
                          .map((city) {
                        return GestureDetector(
                          onTap: _isLoading ? null : () => _selectCity(city),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBgSecondary
                                  : AppColors.lightBgSecondary,
                              border: Border.all(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              city,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
            SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SoftButton(
                  label: AppLocalizations.translate('cancel', locale),
                  onPressed: _isLoading ? () {} : () => Navigator.pop(context),
                  locale: locale,
                  width: 100,
                ),
                if (_selectedCountry != null) ...[
                  SizedBox(width: AppSpacing.md),
                  SoftButton(
                    label: _isLoading
                        ? AppLocalizations.translate('loading', locale)
                        : AppLocalizations.translate('search', locale),
                    onPressed: _isLoading || _controller.text.isEmpty
                        ? () {}
                        : () => _selectCity(_controller.text),
                    locale: locale,
                    width: 100,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

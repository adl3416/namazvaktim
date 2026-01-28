import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namaz_vakitleri/config/color_system.dart';
import 'package:namaz_vakitleri/config/localization.dart';
import 'package:namaz_vakitleri/providers/app_settings.dart';
import 'package:namaz_vakitleri/providers/prayer_provider.dart';
import 'common_widgets.dart';

class CitySearchDialog extends StatefulWidget {
  final PrayerProvider prayerProvider;

  const CitySearchDialog({Key? key, required this.prayerProvider})
    : super(key: key);

  @override
  State<CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<CitySearchDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;
  String? _selectedCountry;

  // Popular countries
  final Map<String, String> _countries = {
    'TR': 'Türkiye',
    'DE': 'Almanya',
    'SA': 'Suudi Arabistan',
    'AE': 'Birleşik Arap Emirlikleri',
    'US': 'Amerika Birleşik Devletleri',
    'GB': 'Birleşik Krallık',
    'FR': 'Fransa',
    'NL': 'Hollanda',
    'CA': 'Kanada',
    'AU': 'Avustralya',
  };

  // Popular cities by country
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

  Future<void> _selectCity(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.prayerProvider.setLocation(city, 'TR');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şehir bulunamadı: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;

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
              // Country Selection
              Text(
                'Ülke Seçin',
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
                    children: _countries.entries.map((entry) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCountry = entry.key;
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
                            entry.value,
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
              // Back to Country Selection
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
                  Text(
                    '${_countries[_selectedCountry]} - Şehir Seçin',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),

              // Search Field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: '${_countries[_selectedCountry]} şehrini arayın...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextLight : AppColors.textLight,
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
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _selectCity(value);
                  }
                },
              ),

              SizedBox(height: AppSpacing.xl),

              // Show Cities for selected country
              if (!_hasFocus && _controller.text.trim().isEmpty) ...[
                Text(
                  '${_countries[_selectedCountry]} Şehirleri',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Cities Grid
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (_citiesByCountry[_selectedCountry] ?? []).map((city) {
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

            // Buttons
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
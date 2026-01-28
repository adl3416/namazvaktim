import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import 'city_selection_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, String> _countries = {
    'TR': 'Türkiye',
    'US': 'Amerika Birleşik Devletleri',
    'GB': 'Birleşik Krallık',
    'DE': 'Almanya',
    'FR': 'Fransa',
    'IT': 'İtalya',
    'ES': 'İspanya',
    'NL': 'Hollanda',
    'BE': 'Belçika',
    'CH': 'İsviçre',
    'AT': 'Avusturya',
    'SE': 'İsveç',
    'NO': 'Norveç',
    'DK': 'Danimarka',
    'FI': 'Finlandiya',
    'PL': 'Polonya',
    'CZ': 'Çekya',
    'HU': 'Macaristan',
    'SK': 'Slovakya',
    'SI': 'Slovenya',
    'HR': 'Hırvatistan',
    'BA': 'Bosna Hersek',
    'ME': 'Karadağ',
    'MK': 'Kuzey Makedonya',
    'AL': 'Arnavutluk',
    'GR': 'Yunanistan',
    'BG': 'Bulgaristan',
    'RO': 'Romanya',
    'MD': 'Moldova',
    'UA': 'Ukrayna',
    'BY': 'Belarus',
    'RU': 'Rusya',
    'LT': 'Litvanya',
    'LV': 'Letonya',
    'EE': 'Estonya',
    'PT': 'Portekiz',
    'IE': 'İrlanda',
    'IS': 'İzlanda',
    'CA': 'Kanada',
    'MX': 'Meksika',
    'BR': 'Brezilya',
    'AR': 'Arjantin',
    'CL': 'Şili',
    'CO': 'Kolombiya',
    'PE': 'Peru',
    'VE': 'Venezuela',
    'EC': 'Ekvador',
    'BO': 'Bolivya',
    'PY': 'Paraguay',
    'UY': 'Uruguay',
    'AU': 'Avustralya',
    'NZ': 'Yeni Zelanda',
    'JP': 'Japonya',
    'KR': 'Güney Kore',
    'CN': 'Çin',
    'IN': 'Hindistan',
    'PK': 'Pakistan',
    'BD': 'Bangladeş',
    'NP': 'Nepal',
    'LK': 'Sri Lanka',
    'TH': 'Tayland',
    'MY': 'Malezya',
    'SG': 'Singapur',
    'ID': 'Endonezya',
    'PH': 'Filipinler',
    'VN': 'Vietnam',
    'KH': 'Kamboçya',
    'LA': 'Laos',
    'MM': 'Myanmar',
    'EG': 'Mısır',
    'SA': 'Suudi Arabistan',
    'AE': 'Birleşik Arap Emirlikleri',
    'QA': 'Katar',
    'KW': 'Kuveyt',
    'BH': 'Bahreyn',
    'OM': 'Umman',
    'JO': 'Ürdün',
    'LB': 'Lübnan',
    'SY': 'Suriye',
    'IQ': 'Irak',
    'IR': 'İran',
    'AF': 'Afganistan',
    'UZ': 'Özbekistan',
    'KZ': 'Kazakistan',
    'KG': 'Kırgızistan',
    'TJ': 'Tacikistan',
    'TM': 'Türkmenistan',
    'AZ': 'Azerbaycan',
    'GE': 'Gürcistan',
    'AM': 'Ermenistan',
    'ZA': 'Güney Afrika',
    'NG': 'Nijerya',
    'KE': 'Kenya',
    'TZ': 'Tanzanya',
    'UG': 'Uganda',
    'GH': 'Gana',
    'CI': 'Fildişi Sahili',
    'SN': 'Senegal',
    'MA': 'Fas',
    'TN': 'Tunus',
    'DZ': 'Cezayir',
    'LY': 'Libya',
    'TN': 'Tunus',
    'SD': 'Sudan',
    'ET': 'Etiyopya',
    'SO': 'Somali',
    'DJ': 'Cibuti',
    'ER': 'Eritre',
  };

  List<MapEntry<String, String>> get _filteredCountries {
    if (_searchQuery.isEmpty) {
      return _countries.entries.toList();
    }
    return _countries.entries
        .where((entry) =>
            entry.value.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.read<AppSettings>().language;

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
          AppLocalizations.translate('select_country', locale),
          style: AppTypography.h3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ülke ara...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                ),
                prefixIcon: Icon(
                  Icons.search,
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
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Countries List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(
                    country.value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    country.key,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CitySelectionScreen(
                          countryCode: country.key,
                          countryName: country.value,
                        ),
                      ),
                    );
                  },
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../services/emushaf_prayer_service.dart';
import 'city_selection_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<EmushafCountry> _countries = const [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final countries = await EmushafPrayerService.fetchCountries();
      countries.sort((a, b) => _displayName(a).compareTo(_displayName(b)));

      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  List<EmushafCountry> get _filteredCountries {
    final query = _normalize(_searchController.text);
    if (query.isEmpty) {
      return _countries;
    }

    return _countries.where((country) {
      return _normalize(country.name).contains(query) ||
          _normalize(country.englishName).contains(query) ||
          _normalize(_displayName(country)).contains(query);
    }).toList();
  }

  String _displayName(EmushafCountry country) {
    final source = country.englishName.isNotEmpty ? country.englishName : country.name;
    return _titleCase(source);
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) {
            return part.toUpperCase();
          }
          return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
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
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _text(
                  locale,
                  tr: 'Ulke ara...',
                  en: 'Search country...',
                  ar: 'ابحث عن دولة...',
                ),
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
              ),
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _buildBody(isDark: isDark, locale: locale),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required String locale,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.darkAccentPrimary : AppColors.accentPrimary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _text(
              locale,
              tr: 'Ulke listesi yuklenemedi.\n$_errorMessage',
              en: 'Country list could not be loaded.\n$_errorMessage',
              ar: 'تعذر تحميل قائمة الدول.\n$_errorMessage',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filtered = _filteredCountries;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _text(
            locale,
            tr: 'Aramana uygun ulke bulunamadi.',
            en: 'No country matched your search.',
            ar: 'لم يتم العثور على دولة مطابقة لبحثك.',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final country = filtered[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            _displayName(country),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            country.name,
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
                builder: (context) => CitySelectionScreen(country: country),
              ),
            );
          },
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        );
      },
    );
  }
}

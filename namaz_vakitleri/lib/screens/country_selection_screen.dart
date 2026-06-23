import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../services/emushaf_prayer_service.dart';
import 'city_selection_screen.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({
    super.key,
    this.canPop = true,
  });

  final bool canPop;

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
      countries.sort(_compareCountries);

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
    final source =
        country.englishName.isNotEmpty ? country.englishName : country.name;
    return _titleCase(source);
  }

  int _compareCountries(EmushafCountry a, EmushafCountry b) {
    final priorityA = _countryPriority(a);
    final priorityB = _countryPriority(b);
    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB);
    }
    return _displayName(a).compareTo(_displayName(b));
  }

  int _countryPriority(EmushafCountry country) {
    final normalized = _normalize('${country.name} ${country.englishName}');
    if (normalized.contains('turkiye') || normalized.contains('turkey')) {
      return 0;
    }
    if (normalized.contains('almanya') ||
        normalized.contains('germany') ||
        normalized.contains('deutschland')) {
      return 1;
    }
    if (normalized.contains('hollanda') ||
        normalized.contains('netherlands')) {
      return 2;
    }
    if (normalized.contains('fransa') || normalized.contains('france')) {
      return 3;
    }
    if (normalized.contains('belcika') || normalized.contains('belgium')) {
      return 4;
    }
    if (normalized.contains('abd') ||
        normalized.contains('amerika birlesik devletleri') ||
        normalized.contains('united states') ||
        normalized.contains('usa')) {
      return 5;
    }
    return 100;
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
    var normalized = value.trim().toLowerCase();
    const replacements = <String, String>{
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i̇': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      '-': ' ',
      '\'': ' ',
      '.': ' ',
      ',': ' ',
      '(': ' ',
      ')': ' ',
      '/': ' ',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    final locale = context.read<AppSettings>().language;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardVisible = viewInsets.bottom > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScale = (screenWidth / 390).clamp(0.88, 1.16).toDouble();

    const backgroundTop = Color(0xFFF4F0FF);
    const backgroundBottom = Color(0xFFE9F0FF);
    const cardStart = Color(0xFFFFFCF6);
    const cardMid = Color(0xFFFFF3DD);
    const cardEnd = Color(0xFFFFFBF2);
    const titleColor = Color(0xFF143D36);
    const accentColor = Color(0xFFE0A52C);
    const bodyColor = Color(0xFF6D7684);

    return PopScope(
      canPop: widget.canPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: keyboardVisible
            ? _buildKeyboardBody(
                context: context,
                locale: locale,
                viewInsets: viewInsets,
                titleColor: titleColor,
                accentColor: accentColor,
                bodyColor: bodyColor,
                backgroundTop: backgroundTop,
                backgroundBottom: backgroundBottom,
                widthScale: widthScale,
              )
            : AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [backgroundTop, backgroundBottom],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            8 * widthScale,
                            0,
                            0,
                          ),
                          child: Row(
                            children: [
                              if (widget.canPop)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.78),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: titleColor,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              if (widget.canPop) const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.78),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.asset(
                                          'assets/images/icon3.jpg',
                                      width: 34 * widthScale,
                                      height: 34 * widthScale,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                      SizedBox(width: 12 * widthScale),
                                      Flexible(
                                        child: Text(
                                          'Ezanlar',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: titleColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22 * widthScale,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              0,
                              8 * widthScale,
                              0,
                              0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [cardStart, cardMid, cardEnd],
                                ),
                                borderRadius: BorderRadius.circular(0),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.92),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.16),
                                    blurRadius: 30,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20 * widthScale,
                                  22 * widthScale,
                                  20 * widthScale,
                                  18 * widthScale,
                                ),
                                child: Column(
                                  children: [
                                    if (!widget.canPop) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7EBCF),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color(0xFFE8C97E),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.public_rounded,
                                              color: accentColor,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              AppLocalizations.translate(
                                                'select_country',
                                                locale,
                                              ),
                                              style: const TextStyle(
                                                color: titleColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 18 * widthScale),
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: accentColor,
                                        size: 42,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _text(
                                          locale,
                                          tr: 'Önce ülkenizi seçin',
                                          en: 'Choose your country first',
                                          ar: 'Choose your country first',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: titleColor,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          height: 1.16,
                                        ),
                                      ),
                                      SizedBox(height: 12 * widthScale),
                                      Text(
                                        _text(
                                          locale,
                                          tr:
                                              'Namaz vakitlerinin doğru gösterilmesi için önce ülkenizi, sonra şehrinizi seçin.',
                                          en:
                                              'Choose your country first, then your city, to see accurate prayer times.',
                                          ar:
                                              'Choose your country first, then your city, to see accurate prayer times.',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: bodyColor,
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 18 * widthScale),
                                    ] else ...[
                                      Text(
                                        AppLocalizations.translate(
                                          'select_country',
                                          locale,
                                        ),
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 26 * widthScale,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 18 * widthScale),
                                    ],
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(22 * widthScale),
                                        border: Border.all(color: Colors.white),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accentColor.withOpacity(0.08),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: _text(
                                            locale,
                                            tr: 'Ülke ara...',
                                            en: 'Search country...',
                                            ar: 'Search country...',
                                          ),
                                          hintStyle: const TextStyle(color: bodyColor),
                                          prefixIcon: const Icon(
                                            Icons.search_rounded,
                                            color: accentColor,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 18,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: titleColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    SizedBox(height: 14 * widthScale),
                                    Expanded(
                                      child: _buildBody(locale: locale),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildKeyboardBody({
    required BuildContext context,
    required String locale,
    required EdgeInsets viewInsets,
    required Color titleColor,
    required Color accentColor,
    required Color bodyColor,
    required Color backgroundTop,
    required Color backgroundBottom,
    required double widthScale,
  }) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundTop, backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16 * widthScale,
              10 * widthScale,
              16 * widthScale,
              12 * widthScale,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.canPop)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: titleColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    if (widget.canPop) SizedBox(width: 10 * widthScale),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14 * widthScale,
                          vertical: 12 * widthScale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/icon3.jpg',
                            width: 28 * widthScale,
                            height: 28 * widthScale,
                            fit: BoxFit.cover,
                          ),
                        ),
                            SizedBox(width: 10 * widthScale),
                            Expanded(
                              child: Text(
                                _text(
                                  locale,
                                  tr: 'Ülke seç',
                                  en: 'Choose country',
                                  ar: 'Choose country',
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12 * widthScale),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(22 * widthScale),
                    border: Border.all(color: Colors.white),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: _text(
                        locale,
                        tr: 'Ülke ara...',
                        en: 'Search country...',
                        ar: 'Search country...',
                      ),
                      hintStyle: TextStyle(color: bodyColor.withOpacity(0.95)),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: accentColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 18,
                      ),
                    ),
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(height: 12 * widthScale),
                Expanded(
                  child: _buildBody(locale: locale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required String locale,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE0A52C)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _text(
                  locale,
                  tr: 'Ülke listesi yüklenemedi.\n$_errorMessage',
                  en: 'Country list could not be loaded.\n$_errorMessage',
                  ar: 'Country list could not be loaded.\n$_errorMessage',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6D7684),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE7A72B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                onPressed: _loadCountries,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _text(
                    locale,
                    tr: 'Tekrar dene',
                    en: 'Try again',
                    ar: 'Try again',
                  ),
                ),
              ),
            ],
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
            tr: 'Aramana uygun ülke bulunamadı.',
            en: 'No country matched your search.',
            ar: 'No country matched your search.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6D7684),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final country = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE0A52C).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            title: Text(
              _displayName(country),
              style: const TextStyle(
                color: Color(0xFF143D36),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              country.name,
              style: const TextStyle(
                color: Color(0xFF6D7684),
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
            trailing: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8E8BF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Color(0xFFE0A52C),
              ),
            ),
          ),
        );
      },
    );
  }
}

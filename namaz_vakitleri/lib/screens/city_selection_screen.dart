import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../config/localization.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../services/emushaf_prayer_service.dart';
import 'district_selection_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({
    super.key,
    required this.country,
  });

  final EmushafCountry country;

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSelecting = false;
  bool _isSearchingNested = false;
  String? _errorMessage;
  List<EmushafLookupItem> _items = const [];
  List<_NestedMatch> _nestedMatches = const [];
  Timer? _debounce;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await EmushafPrayerService.fetchCities(widget.country.id);
      items.sort((a, b) => _displayLookupName(a).compareTo(_displayLookupName(b)));

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
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

  List<EmushafLookupItem> get _topLevelMatches {
    final query = _normalize(_searchController.text);
    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      return _normalize(item.name).contains(query) ||
          _normalize(item.englishName).contains(query) ||
          _normalize(_displayLookupName(item)).contains(query);
    }).toList();
  }

  Future<void> _onSearchChanged(String value) async {
    setState(() {});
    _debounce?.cancel();

    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _nestedMatches = const [];
        _isSearchingNested = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchNestedMatches(query);
    });
  }

  Future<void> _searchNestedMatches(String query) async {
    final version = ++_searchVersion;

    setState(() {
      _isSearchingNested = true;
      _nestedMatches = const [];
    });

    final normalizedQuery = _normalize(query);
    final matches = <_NestedMatch>[];

    for (final item in _items) {
      if (matches.length >= 60) {
        break;
      }

      final children = await EmushafPrayerService.fetchDistricts(item.id);
      if (!mounted || version != _searchVersion) {
        return;
      }

      for (final child in children) {
        final searchable = [
          child.name,
          child.englishName,
          _displayLookupName(child),
        ];

        if (searchable.any((value) => _normalize(value).contains(normalizedQuery))) {
          matches.add(_NestedMatch(parent: item, child: child));
          if (matches.length >= 60) {
            break;
          }
        }
      }
    }

    if (!mounted || version != _searchVersion) {
      return;
    }

    setState(() {
      _nestedMatches = matches;
      _isSearchingNested = false;
    });
  }

  Future<void> _selectTopLevel(EmushafLookupItem item) async {
    if (widget.country.isTurkey) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DistrictSelectionScreen(
            country: widget.country,
            parentItem: item,
          ),
        ),
      );
      return;
    }

    final children = await EmushafPrayerService.fetchDistricts(item.id);
    if (!mounted) {
      return;
    }

    if (children.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DistrictSelectionScreen(
            country: widget.country,
            parentItem: item,
          ),
        ),
      );
      return;
    }

    await _applySelection(
      city: item.searchName,
      cityId: item.id,
    );
  }

  Future<void> _selectNested(_NestedMatch match) async {
    if (widget.country.isTurkey) {
      await _applySelection(
        city: match.parent.searchName,
        district: match.child.searchName,
        cityId: match.parent.id,
        districtId: match.child.id,
      );
      return;
    }

    await _applySelection(
      city: match.child.searchName,
      state: match.parent.searchName,
      cityId: match.parent.id,
      districtId: match.child.id,
    );
  }

  Future<void> _applySelection({
    required String city,
    String? district,
    String? state,
    String? cityId,
    String? districtId,
  }) async {
    setState(() {
      _isSelecting = true;
    });

    try {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.setManualLocation(
        city,
        widget.country.searchName,
        district: district,
        state: state,
        countryId: widget.country.id,
        cityId: cityId,
        districtId: districtId,
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
              tr: 'Secim uygulanamadi: $e',
              en: 'Selection could not be applied: $e',
              ar: 'تعذر تطبيق الاختيار: $e',
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
        _isSelecting = false;
      });
    }
  }

  String _displayLookupName(EmushafLookupItem item) {
    final source = item.englishName.isNotEmpty ? item.englishName : item.name;
    return _titleCase(source);
  }

  String _displayCountryName() {
    final source = widget.country.englishName.isNotEmpty
        ? widget.country.englishName
        : widget.country.name;
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
    var normalized = value.trim().toLowerCase();
    const replacements = <String, String>{
      'ç': 'c',
      'Ç': 'c',
      'ğ': 'g',
      'Ğ': 'g',
      'ı': 'i',
      'I': 'i',
      'İ': 'i',
      'i̇': 'i',
      'ö': 'o',
      'Ö': 'o',
      'ş': 's',
      'Ş': 's',
      'ü': 'u',
      'Ü': 'u',
      'Ã§': 'c',
      'ÄŸ': 'g',
      'Ä±': 'i',
      'Ã¶': 'o',
      'ÅŸ': 's',
      'Ã¼': 'u',
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
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.read<AppSettings>().language;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF143D36),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_displayCountryName()} • ${AppLocalizations.translate('search_city', locale)}',
          style: const TextStyle(
            color: Color(0xFF143D36),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _text(
                  locale,
                  tr: '${_displayCountryName()} icin sehir veya bolge ara...',
                  en: 'Search a city or region in ${_displayCountryName()}...',
                  ar: 'ابحث عن مدينة أو منطقة في ${_displayCountryName()}...',
                ),
                hintStyle: const TextStyle(
                  color: Color(0xFF6D7684),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFE0A52C),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: Color(0xFFE0A52C),
                    width: 1.6,
                  ),
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF143D36),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _buildBody(locale: locale),
          ),
        ],
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
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _text(
              locale,
              tr: 'Liste yuklenemedi.\n$_errorMessage',
              en: 'The list could not be loaded.\n$_errorMessage',
              ar: 'تعذر تحميل القائمة.\n$_errorMessage',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final query = _searchController.text.trim();
    final topLevelMatches = _topLevelMatches;

    if (query.isEmpty) {
      return _buildTopLevelList(topLevelMatches);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (topLevelMatches.isNotEmpty) ...[
          _SectionHeader(
            title: _text(
              locale,
              tr: 'Bolgeler / ust seviye yerler',
              en: 'Regions / top-level places',
              ar: 'المناطق / الأماكن الرئيسية',
            ),
          ),
          ...topLevelMatches.map(_buildTopLevelTile),
        ],
        if (_isSearchingNested) ...[
          const SizedBox(height: 12),
          Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFE0A52C),
            ),
          ),
        ] else if (_nestedMatches.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionHeader(
            title: _text(
              locale,
              tr: 'Bulunan alt sehirler / ilceler',
              en: 'Matching nested cities / districts',
              ar: 'المدن / المناطق الفرعية المطابقة',
            ),
          ),
          ..._nestedMatches.map(_buildNestedTile),
        ] else if (topLevelMatches.isEmpty) ...[
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: Center(
              child: Text(
                _text(
                  locale,
                  tr: 'Aramana uygun yer bulunamadi.',
                  en: 'No place matched your search.',
                  ar: 'لم يتم العثور على مكان مطابق لبحثك.',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopLevelList(List<EmushafLookupItem> items) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildTopLevelTile(items[index]);
      },
    );
  }

  Widget _buildTopLevelTile(EmushafLookupItem item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(
          _displayLookupName(item),
          style: const TextStyle(
            color: Color(0xFF143D36),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFF6D7684),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: _isSelecting ? null : () => _selectTopLevel(item),
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
  }

  Widget _buildNestedTile(_NestedMatch match) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      title: Text(
        _displayLookupName(match.child),
        style: const TextStyle(
          color: Color(0xFF143D36),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        '${_displayLookupName(match.parent)} • ${match.child.name}',
        style: const TextStyle(
          color: Color(0xFF6D7684),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: _isSelecting ? null : () => _selectNested(match),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8E8BF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.location_on_rounded,
          size: 18,
          color: Color(0xFFE0A52C),
        ),
      ),
    ));
  }
}

class _NestedMatch {
  const _NestedMatch({
    required this.parent,
    required this.child,
  });

  final EmushafLookupItem parent;
  final EmushafLookupItem child;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

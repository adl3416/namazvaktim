import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';
import '../providers/prayer_provider.dart';
import '../services/emushaf_prayer_service.dart';

class DistrictSelectionScreen extends StatefulWidget {
  const DistrictSelectionScreen({
    super.key,
    required this.country,
    required this.parentItem,
  });

  final EmushafCountry country;
  final EmushafLookupItem parentItem;

  @override
  State<DistrictSelectionScreen> createState() => _DistrictSelectionScreenState();
}

class _DistrictSelectionScreenState extends State<DistrictSelectionScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = true;
  bool _isSelecting = false;
  String? _errorMessage;
  List<EmushafLookupItem> _items = const [];

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
      final items = await EmushafPrayerService.fetchDistricts(widget.parentItem.id);
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

  List<EmushafLookupItem> get _filteredItems {
    final query = _normalize(_controller.text);
    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      return _normalize(item.name).contains(query) ||
          _normalize(item.englishName).contains(query) ||
          _normalize(_displayLookupName(item)).contains(query);
    }).toList();
  }

  Future<void> _selectItem(EmushafLookupItem item) async {
    if (widget.country.isTurkey) {
      await _applySelection(
        city: widget.parentItem.searchName,
        district: item.searchName,
        cityId: widget.parentItem.id,
        districtId: item.id,
      );
      return;
    }

    await _applySelection(
      city: item.searchName,
      state: widget.parentItem.searchName,
      cityId: widget.parentItem.id,
      districtId: item.id,
    );
  }

  Future<void> _continueWithText() async {
    final input = _controller.text.trim();

    if (widget.country.isTurkey) {
      await _applySelection(
        city: widget.parentItem.searchName,
        district: input.isEmpty ? null : input,
      );
      return;
    }

    if (input.isEmpty && _items.isNotEmpty) {
      return;
    }

    await _applySelection(
      city: input.isEmpty ? widget.parentItem.searchName : input,
      state: input.isEmpty ? null : widget.parentItem.searchName,
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

  String _levelTitle(String locale) {
    if (widget.country.isTurkey) {
      return _text(
        locale,
        tr: '${_displayLookupName(widget.parentItem)} ilceleri',
        en: '${_displayLookupName(widget.parentItem)} districts',
        ar: 'مناطق ${_displayLookupName(widget.parentItem)}',
      );
    }

    return _text(
      locale,
      tr: '${_displayLookupName(widget.parentItem)} sehirleri',
      en: '${_displayLookupName(widget.parentItem)} cities',
      ar: 'مدن ${_displayLookupName(widget.parentItem)}',
    );
  }

  String _inputHint(String locale) {
    if (widget.country.isTurkey) {
      return _text(
        locale,
        tr: 'Ilce ara veya yaz',
        en: 'Search or type a district',
        ar: 'ابحث عن منطقة أو اكتبها',
      );
    }

    return _text(
      locale,
      tr: 'Sehir ara veya yaz',
      en: 'Search or type a city',
      ar: 'ابحث عن مدينة أو اكتبها',
    );
  }

  String _buttonLabel(String locale) {
    if (widget.country.isTurkey) {
      return _controller.text.trim().isEmpty
          ? _text(
              locale,
              tr: 'Secilen sehir ile devam et',
              en: 'Continue with selected city',
              ar: 'المتابعة بالمدينة المحددة',
            )
          : _text(
              locale,
              tr: 'Ilce ile devam et',
              en: 'Continue with district',
              ar: 'المتابعة بالمنطقة',
            );
    }

    return _controller.text.trim().isEmpty
        ? _text(
            locale,
            tr: 'Sehir sec',
            en: 'Choose a city',
            ar: 'اختر مدينة',
          )
        : _text(
            locale,
            tr: 'Sehir ile devam et',
            en: 'Continue with city',
            ar: 'المتابعة بالمدينة',
          );
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
    _controller.dispose();
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
          _levelTitle(locale),
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
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: _inputHint(locale),
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
              child: _buildBody(isDark: isDark, locale: locale),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSelecting ||
                        (!widget.country.isTurkey &&
                            _controller.text.trim().isEmpty &&
                            _items.isNotEmpty)
                    ? null
                    : _continueWithText,
                child: Text(_buttonLabel(locale)),
              ),
            ),
          ],
        ),
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
        child: Text(
          _text(
            locale,
            tr: 'Liste yuklenemedi.\n$_errorMessage',
            en: 'The list could not be loaded.\n$_errorMessage',
            ar: 'تعذر تحميل القائمة.\n$_errorMessage',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_items.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          _text(
            locale,
            tr: 'Bu seviye icin alt liste bulunamadi. Elle yazarak devam edebilirsin.',
            en: 'No child list was found for this level. You can continue by typing manually.',
            ar: 'لم يتم العثور على قائمة فرعية لهذا المستوى. يمكنك المتابعة بالكتابة اليدوية.',
          ),
        ),
      );
    }

    final filtered = _filteredItems;
    if (filtered.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          _text(
            locale,
            tr: 'Aramana uygun sonuc bulunamadi.',
            en: 'No result matched your search.',
            ar: 'لم يتم العثور على نتيجة مطابقة لبحثك.',
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            _displayLookupName(item),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            item.name,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          onTap: _isSelecting ? null : () => _selectItem(item),
          trailing: Icon(
            Icons.location_on,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        );
      },
    );
  }
}

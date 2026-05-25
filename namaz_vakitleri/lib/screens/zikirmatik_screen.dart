import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class ZikirmatikScreen extends StatefulWidget {
  const ZikirmatikScreen({super.key});

  @override
  State<ZikirmatikScreen> createState() => _ZikirmatikScreenState();
}

class _ZikirmatikScreenState extends State<ZikirmatikScreen>
    with SingleTickerProviderStateMixin {
  static const _hapticChannel = MethodChannel(
    'com.vakit.app.namaz_vakitleri/haptics',
  );
  static const _countKey = 'zikirmatik_count';
  static const _targetKey = 'zikirmatik_target';
  static const _hapticModeKey = 'zikirmatik_haptic_mode';
  static const _currentZikirKey = 'zikirmatik_current_zikir';
  static const _savedZikirListKey = 'zikirmatik_saved_zikir_list';
  static const _zikirCountsKey = 'zikirmatik_zikir_counts';
  static const _defaultZikirler = [
    _SavedZikir(name: 'Subhanallah', target: 33),
    _SavedZikir(name: 'Elhamdulillah', target: 33),
    _SavedZikir(name: 'Allahu Ekber', target: 33),
  ];

  int _count = 0;
  int _target = 33;
  bool _isLoading = true;
  bool _isSavedZikirExpanded = false;
  _ZikirHapticMode _hapticMode = _ZikirHapticMode.everyTap;
  final TextEditingController _zikirController = TextEditingController();
  final TextEditingController _zikirTargetController = TextEditingController(
    text: '33',
  );
  late final AnimationController _tapPulseController;
  String _currentZikir = 'Subhanallah';
  List<_SavedZikir> _savedZikirler = _defaultZikirler;
  Map<String, int> _zikirCounts = const {};

  @override
  void initState() {
    super.initState();
    _tapPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _loadState();
  }

  @override
  void dispose() {
    _tapPulseController.dispose();
    _zikirController.dispose();
    _zikirTargetController.dispose();
    super.dispose();
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

  String _hapticModeLabel(_ZikirHapticMode mode, String language) {
    switch (mode) {
      case _ZikirHapticMode.off:
        return _text(language, tr: 'Kapalı', en: 'Off', ar: 'إيقاف');
      case _ZikirHapticMode.everyTap:
        return _text(
          language,
          tr: 'Her dokunuş',
          en: 'Every tap',
          ar: 'كل لمسة',
        );
      case _ZikirHapticMode.every33:
        return _text(language, tr: 'Her 33', en: 'Every 33', ar: 'كل 33');
      case _ZikirHapticMode.onTarget:
        return _text(language, tr: 'Hedefte', en: 'On target', ar: 'عند الهدف');
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final saved = _decodeSavedZikirler(prefs.getStringList(_savedZikirListKey));
    final currentZikir = prefs.getString(_currentZikirKey) ?? 'Subhanallah';
    final zikirCounts = _decodeZikirCounts(prefs.getString(_zikirCountsKey));
    final active = saved.firstWhere(
      (item) => item.name == currentZikir,
      orElse: () => saved.first,
    );

    setState(() {
      _zikirCounts = zikirCounts;
      _count = zikirCounts[active.name] ?? prefs.getInt(_countKey) ?? 0;
      _target = prefs.getInt(_targetKey) ?? active.target;
      _hapticMode = _ZikirHapticMode.values.byName(
        prefs.getString(_hapticModeKey) ?? _ZikirHapticMode.everyTap.name,
      );
      _currentZikir = active.name;
      _savedZikirler = saved;
      _zikirTargetController.text = _target.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = Map<String, int>.from(_zikirCounts);
    counts[_currentZikir] = _count;
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_targetKey, _target);
    await prefs.setString(_hapticModeKey, _hapticMode.name);
    await prefs.setString(_currentZikirKey, _currentZikir);
    await prefs.setString(_zikirCountsKey, jsonEncode(counts));
    await prefs.setStringList(
      _savedZikirListKey,
      _savedZikirler.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _increment() async {
    final nextCount = _count + 1;
    _tapPulseController.forward(from: 0);
    setState(() {
      _count = nextCount;
      _zikirCounts = {
        ..._zikirCounts,
        _currentZikir: nextCount,
      };
    });
    await _triggerHapticIfNeeded(nextCount);
    await _saveState();
  }

  Future<void> _reset() async {
    setState(() {
      _count = 0;
      _zikirCounts = {
        ..._zikirCounts,
        _currentZikir: 0,
      };
    });
    await _saveState();
  }

  Future<void> _setTarget(int value) async {
    setState(() {
      _target = value;
      if (_count > value) {
        _count = 0;
      }
      _zikirTargetController.text = value.toString();
    });
    await _saveState();
  }

  Future<void> _setHapticMode(_ZikirHapticMode mode) async {
    setState(() {
      _hapticMode = mode;
    });
    await _saveState();
  }

  Future<void> _saveZikir() async {
    final raw = _zikirController.text.trim();
    if (raw.isEmpty) return;
    final parsedTarget = int.tryParse(_zikirTargetController.text.trim()) ?? 33;
    final target = parsedTarget <= 0 ? 33 : parsedTarget;

    final exists = _savedZikirler.any(
      (item) => item.name.toLowerCase() == raw.toLowerCase(),
    );

    setState(() {
      if (!exists) {
        _savedZikirler = [
          _SavedZikir(name: raw, target: target),
          ..._savedZikirler,
        ].take(8).toList();
      } else {
        _savedZikirler = _savedZikirler
            .map(
              (item) => item.name.toLowerCase() == raw.toLowerCase()
                  ? _SavedZikir(name: raw, target: target)
                  : item,
            )
            .toList();
      }
      _currentZikir = raw;
      _target = target;
      _count = 0;
      _zikirCounts = {
        ..._zikirCounts,
        raw: _zikirCounts[raw] ?? 0,
      };
      _zikirController.clear();
      _zikirTargetController.text = target.toString();
    });

    await _saveState();
  }

  Future<void> _selectZikir(String zikir) async {
    final selected = _savedZikirler.firstWhere(
      (item) => item.name == zikir,
      orElse: () => _SavedZikir(name: zikir, target: 33),
    );
    setState(() {
      _currentZikir = selected.name;
      _target = selected.target;
      _count = _zikirCounts[selected.name] ?? 0;
      if (_count > _target) {
        _count = 0;
        _zikirCounts = {
          ..._zikirCounts,
          selected.name: 0,
        };
      }
      _zikirTargetController.text = selected.target.toString();
    });
    await _saveState();
  }

  bool _isDefaultZikir(String zikir) {
    return _defaultZikirler.any(
      (item) => item.name.toLowerCase() == zikir.toLowerCase(),
    );
  }

  Future<void> _removeZikir(String zikir) async {
    if (_isDefaultZikir(zikir)) return;

    final updated = _savedZikirler.where((item) => item.name != zikir).toList();
    if (updated.isEmpty) return;

    final nextSelected = updated.firstWhere(
      (item) => item.name == _currentZikir,
      orElse: () => updated.first,
    );

    setState(() {
      _savedZikirler = updated;
      _currentZikir = nextSelected.name;
      _target = nextSelected.target;
      _zikirCounts = Map<String, int>.from(_zikirCounts)..remove(zikir);
      _count = _zikirCounts[nextSelected.name] ?? 0;
      if (_count > _target) {
        _count = 0;
        _zikirCounts = {
          ..._zikirCounts,
          nextSelected.name: 0,
        };
      }
      _zikirTargetController.text = _target.toString();
    });

    await _saveState();
  }

  void _toggleSavedZikirExpanded() {
    setState(() {
      _isSavedZikirExpanded = !_isSavedZikirExpanded;
    });
  }

  void _dismissSettingsSheetIfDraggedDown(
    BuildContext context,
    DragEndDetails details,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 250) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _triggerHapticIfNeeded(int nextCount) async {
    switch (_hapticMode) {
      case _ZikirHapticMode.off:
        return;
      case _ZikirHapticMode.everyTap:
        await _performNativeVibration('tap');
        return;
      case _ZikirHapticMode.every33:
        if (nextCount % 33 == 0) {
          await _performNativeVibration('milestone');
        }
        return;
      case _ZikirHapticMode.onTarget:
        if (nextCount >= _target) {
          await _performNativeVibration('target');
        }
        return;
    }
  }

  Future<void> _performNativeVibration(String mode) async {
    try {
      await _hapticChannel.invokeMethod('vibrate', {'mode': mode});
    } catch (_) {
      switch (mode) {
        case 'target':
          await HapticFeedback.heavyImpact();
          break;
        case 'milestone':
          await HapticFeedback.mediumImpact();
          break;
        default:
          await HapticFeedback.selectionClick();
      }
    }
  }

  List<_SavedZikir> _decodeSavedZikirler(List<String>? rawList) {
    if (rawList == null || rawList.isEmpty) {
      return _defaultZikirler;
    }

    final parsed = <_SavedZikir>[];
    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          parsed.add(_SavedZikir.fromJson(decoded));
          continue;
        }
      } catch (_) {
        parsed.add(_SavedZikir(name: item, target: 33));
      }
    }

    return parsed.isEmpty ? _defaultZikirler : parsed;
  }

  Map<String, int> _decodeZikirCounts(String? raw) {
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};

      final counts = <String, int>{};
      for (final entry in decoded.entries) {
        counts[entry.key.toString()] =
            int.tryParse(entry.value?.toString() ?? '') ?? 0;
      }
      return counts;
    } catch (_) {
      return const {};
    }
  }

  Future<void> _showSettingsSheet({
    required BuildContext context,
    required String language,
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color accent,
    required Color accentSoft,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        Future<void> refreshSheet(
          Future<void> Function() action,
          StateSetter setSheetState,
        ) async {
          await action();
          if (!mounted) return;
          setSheetState(() {});
        }

        return SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.86),
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setSheetState) => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragEnd: (details) =>
                            _dismissSettingsSheetIfDraggedDown(
                          context,
                          details,
                        ),
                        child: Column(
                          children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: textPrimary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _text(
                                    language,
                                    tr: 'Zikirmatik ayarları',
                                    en: 'Dhikr counter settings',
                                    ar: 'إعدادات السبحة',
                                  ),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _text(
                                    language,
                                    tr:
                                        'Hedefini, titreşimi ve kayıtlı zikirlerini düzenle.',
                                    en:
                                        'Manage your target, haptics, and saved dhikr list.',
                                    ar:
                                        'أدر الهدف والاهتزاز وقائمة الأذكار المحفوظة.',
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary.withOpacity(0.68),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: accentSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _text(
                                    language,
                                    tr: 'Aktif',
                                    en: 'Active',
                                    ar: 'النشط',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary.withOpacity(0.65),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_target',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SettingsSectionCard(
                        title: _text(
                          language,
                          tr: 'Hedef',
                          en: 'Target',
                          ar: 'الهدف',
                        ),
                        subtitle: _text(
                          language,
                          tr: 'Sayaç tamamlanma sayısını seç.',
                          en: 'Choose the completion count for the counter.',
                          ar: 'اختر عدد الإكمال للعداد.',
                        ),
                        textPrimary: textPrimary,
                        borderColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        accentSoft: accentSoft,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [33, 99, 100, 500].map((value) {
                            final isSelected = _target == value;
                            return ChoiceChip(
                              label: Text('$value'),
                              selected: isSelected,
                              onSelected: (_) => refreshSheet(
                                () => _setTarget(value),
                                setSheetState,
                              ),
                              selectedColor: accent,
                              backgroundColor: accentSoft,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkBg
                                        : Colors.white)
                                    : textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsSectionCard(
                        title: _text(
                          language,
                          tr: 'Titreşim',
                          en: 'Haptics',
                          ar: 'الاهتزاز',
                        ),
                        subtitle: _text(
                          language,
                          tr: 'Dokunuşta hangi geri bildirim verilsin.',
                          en: 'Choose the feedback you want on tap.',
                          ar: 'اختر نوع الاستجابة عند اللمس.',
                        ),
                        textPrimary: textPrimary,
                        borderColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        accentSoft: accentSoft,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _ZikirHapticMode.values.map((mode) {
                            final isSelected = _hapticMode == mode;
                            return ChoiceChip(
                              label: Text(_hapticModeLabel(mode, language)),
                              selected: isSelected,
                              onSelected: (_) => refreshSheet(
                                () => _setHapticMode(mode),
                                setSheetState,
                              ),
                              selectedColor: accent,
                              backgroundColor: accentSoft,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkBg
                                        : Colors.white)
                                    : textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsSectionCard(
                        title: _text(
                          language,
                          tr: 'Zikir ekle',
                          en: 'Add dhikr',
                          ar: 'أضف ذكرًا',
                        ),
                        subtitle: _text(
                          language,
                          tr: 'Yeni zikir ve hedef kaydı oluştur.',
                          en: 'Create a new dhikr entry and target.',
                          ar: 'أنشئ ذكرًا جديدًا وهدفًا له.',
                        ),
                        textPrimary: textPrimary,
                        borderColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        accentSoft: accentSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _zikirController,
                                    style: TextStyle(color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: _text(
                                        language,
                                        tr: 'Mesela: Estağfirullah',
                                        en: 'Example: Astaghfirullah',
                                        ar: 'مثال: أستغفر الله',
                                      ),
                                      isDense: true,
                                      filled: true,
                                      fillColor: accentSoft,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (_) => refreshSheet(
                                      _saveZikir,
                                      setSheetState,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 86,
                                  child: TextField(
                                    controller: _zikirTargetController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: textPrimary),
                                    decoration: InputDecoration(
                                      hintText: '33',
                                      isDense: true,
                                      filled: true,
                                      fillColor: accentSoft,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (_) => refreshSheet(
                                      _saveZikir,
                                      setSheetState,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => refreshSheet(
                                  _saveZikir,
                                  setSheetState,
                                ),
                                icon: const Icon(Icons.add_rounded),
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor:
                                      isDark ? AppColors.darkBg : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                label: Text(
                                  _text(
                                    language,
                                    tr: 'Kayda ekle',
                                    en: 'Save to list',
                                    ar: 'احفظ في القائمة',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => refreshSheet(() async {
                                _toggleSavedZikirExpanded();
                              }, setSheetState),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: accentSoft.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _text(
                                              language,
                                              tr: 'Kayitli zikirler',
                                              en: 'Saved dhikr',
                                              ar: 'الاذكار المحفوظة',
                                            ),
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_savedZikirler.length}',
                                            style: TextStyle(
                                              color:
                                                  textPrimary.withOpacity(0.65),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _isSavedZikirExpanded ? 0.5 : 0,
                                      duration:
                                          const Duration(milliseconds: 180),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_isSavedZikirExpanded)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: accentSoft.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _savedZikirler.map((zikir) {
                                  final isSelected =
                                      zikir.name == _currentZikir;
                                  return InputChip(
                                    label: Text('${zikir.name} • ${zikir.target}'),
                                    selected: isSelected,
                                    onSelected: (_) => refreshSheet(
                                      () => _selectZikir(zikir.name),
                                      setSheetState,
                                    ),
                                    onDeleted: _isDefaultZikir(zikir.name)
                                        ? null
                                        : () => refreshSheet(
                                            () => _removeZikir(zikir.name),
                                            setSheetState,
                                          ),
                                    deleteIcon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.darkBg
                                              : Colors.white)
                                          : textPrimary.withOpacity(0.75),
                                    ),
                                    selectedColor: accent,
                                    backgroundColor: Colors.white.withOpacity(
                                      isDark ? 0.06 : 0.75,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? (isDark
                                              ? AppColors.darkBg
                                              : Colors.white)
                                          : textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    side: BorderSide.none,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppSettings>().language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBg : const Color(0xFFF6F1E8);
    final cardColor = isDark
        ? AppColors.darkBgSecondary
        : Colors.white.withOpacity(0.88);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF655B51);
    final accent = isDark
        ? AppColors.darkAccentPrimary
        : const Color(0xFF0F766E);
    final accentSoft = isDark
        ? accent.withOpacity(0.16)
        : const Color(0xFF0F766E).withOpacity(0.10);
    final progress = _target == 0 ? 0.0 : (_count / _target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0F172A),
                    Color(0xFF111827),
                    Color(0xFF172033),
                  ]
                : const [
                    Color(0xFFF6F0E6),
                    Color(0xFFE7DCCB),
                    Color(0xFFF9F6F1),
                  ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: accent),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _text(
                              language,
                              tr: 'Zikirmatik',
                              en: 'Dhikr Counter',
                              ar: 'السبحة',
                            ),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showSettingsSheet(
                            context: context,
                            language: language,
                            isDark: isDark,
                            cardColor: cardColor,
                            textPrimary: textPrimary,
                            accent: accent,
                            accentSoft: accentSoft,
                          ),
                          icon: Icon(Icons.tune_rounded, color: textPrimary),
                          tooltip: _text(
                            language,
                            tr: 'Ayarlar',
                            en: 'Settings',
                            ar: 'الإعدادات',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.85),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.28 : 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _InfoPill(
                                  label: _text(
                                    language,
                                    tr: 'Hedef',
                                    en: 'Target',
                                    ar: 'الهدف',
                                  ),
                                  value: '$_target',
                                  accentSoft: accentSoft,
                                  textColor: textPrimary,
                                  subtitleColor: textSecondary,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  Text(
                                    '$_count',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 62,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _count >= _target
                                        ? _text(
                                            language,
                                            tr: 'Tamam',
                                            en: 'Done',
                                            ar: 'تم',
                                          )
                                        : _text(
                                            language,
                                            tr: 'Sayaç',
                                            en: 'Counter',
                                            ar: 'العداد',
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoPill(
                                  label: _text(
                                    language,
                                    tr: 'Kalan',
                                    en: 'Left',
                                    ar: 'المتبقي',
                                  ),
                                  value: '${(_target - _count).clamp(0, _target)}',
                                  accentSoft: accentSoft,
                                  textColor: textPrimary,
                                  subtitleColor: textSecondary,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: accentSoft,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _increment,
                      child: SizedBox(
                        height: 300,
                        child: AnimatedBuilder(
                          animation: _tapPulseController,
                          builder: (context, child) {
                            final pulse = Curves.easeOutCubic.transform(
                              _tapPulseController.value,
                            );
                            final ringScale = 1 + (pulse * 0.16);
                            final coreScale = 1 - (pulse * 0.035);

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.scale(
                                  scale: ringScale,
                                  child: Opacity(
                                    opacity: (1 - pulse) * 0.42,
                                    child: Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.80),
                                          width: 2.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 1 + (pulse * 0.08),
                                  child: Opacity(
                                    opacity: (1 - pulse) * 0.20,
                                    child: Container(
                                      width: 280,
                                      height: 280,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent.withOpacity(0.22),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.scale(scale: coreScale, child: child),
                              ],
                            );
                          },
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        accent.withOpacity(0.92),
                                        Color.lerp(
                                          accent,
                                          Colors.white,
                                          0.18,
                                        )!,
                                      ]
                                    : const [
                                        Color(0xFF0F766E),
                                        Color(0xFF14B8A6),
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(
                                    isDark ? 0.34 : 0.26,
                                  ),
                                  blurRadius: 26,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.touch_app_rounded,
                                    size: 52,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _text(
                                      language,
                                      tr: 'Dokun',
                                      en: 'Tap',
                                      ar: 'المس',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        _currentZikir,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _text(
                          language,
                          tr: 'Sayacı sıfırla',
                          en: 'Reset counter',
                          ar: 'إعادة ضبط العداد',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

enum _ZikirHapticMode { off, everyTap, every33, onTarget }

class _SavedZikir {
  const _SavedZikir({
    required this.name,
    required this.target,
  });

  final String name;
  final int target;

  Map<String, dynamic> toJson() => {
        'name': name,
        'target': target,
      };

  factory _SavedZikir.fromJson(Map<String, dynamic> json) {
    return _SavedZikir(
      name: json['name']?.toString() ?? 'Zikir',
      target: json['target'] is int
          ? json['target'] as int
          : int.tryParse(json['target']?.toString() ?? '') ?? 33,
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.borderColor,
    required this.accentSoft,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color borderColor;
  final Color accentSoft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentSoft.withOpacity(0.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: textPrimary.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    required this.accentSoft,
    required this.textColor,
    required this.subtitleColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color accentSoft;
  final Color textColor;
  final Color subtitleColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

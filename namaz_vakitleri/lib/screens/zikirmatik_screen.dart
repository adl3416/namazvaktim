import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/color_system.dart';
import '../providers/app_settings.dart';

class ZikirmatikScreen extends StatefulWidget {
  const ZikirmatikScreen({
    super.key,
    this.initialZikirName,
    this.initialTargetCount,
    this.openLibraryFirst = false,
    this.onExitRequested,
  });

  final String? initialZikirName;
  final int? initialTargetCount;
  final bool openLibraryFirst;
  final VoidCallback? onExitRequested;

  @override
  State<ZikirmatikScreen> createState() => _ZikirmatikScreenState();
}

class _ZikirmatikScreenState extends State<ZikirmatikScreen>
    with SingleTickerProviderStateMixin {
  static const _hapticChannel = MethodChannel(
    'com.vakit.app.ezanlar/haptics',
  );
  static const _countKey = 'zikirmatik_count';
  static const _targetKey = 'zikirmatik_target';
  static const _hapticModeKey = 'zikirmatik_haptic_mode';
  static const _currentZikirKey = 'zikirmatik_current_zikir';
  static const _savedZikirListKey = 'zikirmatik_saved_zikir_list';
  static const _zikirCountsKey = 'zikirmatik_zikir_counts';
  static const _storageVersionKey = 'zikirmatik_storage_version';
  static const _currentStorageVersion = 2;
  static const _defaultZikirler = [
    _SavedZikir(name: 'Sübhanallah', target: 33),
    _SavedZikir(name: 'Elhamdülillah', target: 33),
    _SavedZikir(name: 'Allahu ekber', target: 33),
    _SavedZikir(name: 'Allahümme salli alâ seyyidinâ Muhammed', target: 100),
    _SavedZikir(name: 'Lâ ilâhe illallah', target: 99),
    _SavedZikir(name: 'Yâ Rahmân', target: 298),
    _SavedZikir(name: 'Yâ Rahîm', target: 258),
    _SavedZikir(name: 'Yâ Melik', target: 90),
    _SavedZikir(name: 'Yâ Kuddûs', target: 170),
    _SavedZikir(name: 'Yâ Selâm', target: 131),
    _SavedZikir(name: "Yâ Mü'min", target: 136),
    _SavedZikir(name: 'Yâ Azîz', target: 94),
    _SavedZikir(name: 'Yâ Latîf, Yâ Allâh', target: 129),
    _SavedZikir(
      name: 'Lâ ilâhe illâ ente sübhâneke innî küntü minez zâlimîn',
      target: 100,
    ),
    _SavedZikir(
      name: 'Ferdün Hayyün Kayyûmün Hakemün Adlün Kuddûs',
      target: 33,
    ),
  ];
  int _count = 0;
  int _target = 33;
  bool _isLoading = true;
  bool _isSavedZikirExpanded = false;
  bool _isHapticMenuOpen = false;
  _ZikirHapticMode _hapticMode = _ZikirHapticMode.everyTap;
  late _ZikirViewMode _viewMode;
  final TextEditingController _zikirController = TextEditingController();
  final TextEditingController _zikirTargetController = TextEditingController(
    text: '33',
  );
  late final AnimationController _tapPulseController;
  String _currentZikir = '';
  List<_SavedZikir> _savedZikirler = _defaultZikirler;
  Map<String, int> _zikirCounts = const {};

  @override
  void initState() {
    super.initState();
    final hasInitialZikir = (widget.initialZikirName?.trim().isNotEmpty ?? false);
    _viewMode =
        widget.openLibraryFirst && !hasInitialZikir
            ? _ZikirViewMode.library
            : _ZikirViewMode.counter;
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
        return _text(language, tr: 'Kapali', en: 'Off', ar: 'Ã˜Â¥Ã™Å Ã™â€šÃ˜Â§Ã™Â');
      case _ZikirHapticMode.everyTap:
        return _text(
          language,
          tr: 'Her dokunus',
          en: 'Every tap',
          ar: 'Ã™Æ’Ã™â€ž Ã™â€žÃ™â€¦Ã˜Â³Ã˜Â©',
        );
      case _ZikirHapticMode.every33:
        return _text(language, tr: 'Her 33', en: 'Every 33', ar: 'Ã™Æ’Ã™â€ž 33');
      case _ZikirHapticMode.onTarget:
        return _text(language, tr: 'Hedefte', en: 'On target', ar: 'Ã˜Â¹Ã™â€ Ã˜Â¯ Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â¯Ã™Â');
    }
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final shouldStartWithEmptyDraft =
          widget.openLibraryFirst &&
          !(widget.initialZikirName?.trim().isNotEmpty ?? false);
      final requestedZikir = _normalizeLegacyZikirName(
        widget.initialZikirName?.trim(),
      );
      final requestedTarget =
          (widget.initialTargetCount != null && widget.initialTargetCount! > 0)
              ? widget.initialTargetCount!
              : null;
      final storedVersion = prefs.getInt(_storageVersionKey) ?? 0;
      var saved = _decodeSavedZikirler(prefs.getStringList(_savedZikirListKey));
      var currentZikir = _normalizeLegacyZikirName(
        prefs.getString(_currentZikirKey),
      );
      final zikirCounts = _decodeZikirCounts(prefs.getString(_zikirCountsKey));
      var shouldPersistRecoveredState = storedVersion < _currentStorageVersion;

      if (requestedZikir != null && requestedZikir.isNotEmpty) {
        final existingIndex = saved.indexWhere(
          (item) => item.name.toLowerCase() == requestedZikir.toLowerCase(),
        );

        if (existingIndex >= 0) {
          if (requestedTarget != null &&
              saved[existingIndex].target != requestedTarget) {
            saved = List<_SavedZikir>.from(saved);
            saved[existingIndex] = _SavedZikir(
              name: saved[existingIndex].name,
              target: requestedTarget,
            );
          }
          currentZikir = saved[existingIndex].name;
        } else {
          saved = [
            _SavedZikir(name: requestedZikir, target: requestedTarget ?? 33),
            ...saved,
          ];
          currentZikir = requestedZikir;
          shouldPersistRecoveredState = true;
        }
      }

      final active =
          currentZikir.isEmpty
              ? null
              : saved.cast<_SavedZikir?>().firstWhere(
                  (item) => item?.name == currentZikir,
                  orElse: () => null,
                );
      final target =
          requestedTarget ?? prefs.getInt(_targetKey) ?? active?.target ?? 33;

      setState(() {
        _zikirCounts = zikirCounts;
        _count =
            active != null
                ? zikirCounts[active.name] ?? prefs.getInt(_countKey) ?? 0
                : prefs.getInt(_countKey) ?? 0;
        _target = target;
        _hapticMode = _ZikirHapticMode.values.byName(
          prefs.getString(_hapticModeKey) ?? _ZikirHapticMode.everyTap.name,
        );
        _currentZikir = active?.name ?? '';
        _savedZikirler = saved;
        _zikirController.clear();
        _zikirTargetController.text =
            shouldStartWithEmptyDraft ? '' : _target.toString();
        _isLoading = false;
      });

      if (requestedZikir != null && requestedZikir.isNotEmpty) {
        await _saveState();
      } else if (shouldPersistRecoveredState) {
        await _saveState();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedZikirler = _defaultZikirler;
        _currentZikir = '';
        _target = 33;
        _count = 0;
        _zikirCounts = const {};
        _zikirTargetController.text = _target.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final counts = Map<String, int>.from(_zikirCounts);
    if (_currentZikir.isNotEmpty) {
      counts[_currentZikir] = _count;
    }
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_targetKey, _target);
    await prefs.setString(_hapticModeKey, _hapticMode.name);
    await prefs.setString(_currentZikirKey, _currentZikir);
    await prefs.setString(_zikirCountsKey, jsonEncode(counts));
    await prefs.setInt(_storageVersionKey, _currentStorageVersion);
    await prefs.setStringList(
      _savedZikirListKey,
      _savedZikirler.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _increment() async {
    final nextCount = _count + 1;
    _tapPulseController.forward(from: 0);
    setState(() {
      _isHapticMenuOpen = false;
      _count = nextCount;
      if (_currentZikir.isNotEmpty) {
        _zikirCounts = {
          ..._zikirCounts,
          _currentZikir: nextCount,
        };
      }
    });
    await _triggerHapticIfNeeded(nextCount);
    await _saveState();
  }

  Future<void> _clearCounter() async {
    setState(() {
      _currentZikir = '';
      _count = 0;
      _target = 33;
      _zikirTargetController.text = '33';
      _zikirController.clear();
    });
    await _saveState();
  }

  Future<void> _reset() async {
    setState(() {
      _count = 0;
      if (_currentZikir.isNotEmpty) {
        _zikirCounts = {
          ..._zikirCounts,
          _currentZikir: 0,
        };
      }
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

  Future<void> _applyTypedTarget() async {
    final parsedTarget = int.tryParse(_zikirTargetController.text.trim()) ?? _target;
    final nextTarget = parsedTarget <= 0 ? _target : parsedTarget;
    await _setTarget(nextTarget);
  }

  Future<void> _setHapticMode(_ZikirHapticMode mode) async {
    setState(() {
      _hapticMode = mode;
      _isHapticMenuOpen = false;
    });
    await _saveState();
  }

  Future<void> _saveZikir({bool openCounter = false}) async {
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
        ];
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
      if (openCounter) {
        _viewMode = _ZikirViewMode.counter;
      }
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

  Future<void> _openCounterForZikir(String zikir) async {
    await _selectZikir(zikir);
    if (!mounted) return;
    setState(() {
      _viewMode = _ZikirViewMode.counter;
    });
  }

  void _openLibrary() {
    setState(() {
      _viewMode = _ZikirViewMode.library;
    });
  }

  void _exitZikirmatik() {
    if (widget.onExitRequested != null) {
      widget.onExitRequested!.call();
      return;
    }
    Navigator.of(context).maybePop();
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

  String _normalizeLegacyZikirName(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return '';
    }

    final normalized = raw
        .toLowerCase()
        .replaceAll('Ã¢', 'a') // Legacy broken characters
        .replaceAll('Ã®', 'i')
        .replaceAll('Ã»', 'u')
        .replaceAll('Ã¼', 'u')
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã£', 'a')
        .replaceAll('Â¢', 'a')
        .replaceAll('Ã ', 'a')
        .replaceAll('Ã¤', 'a')
        .replaceAll('ã¼', 'u')
        .replaceAll('ã¢', 'a')
        .replaceAll('ã®', 'i')
        .replaceAll('ã»', 'u')
        .replaceAll('â¢', 'a')
        .replaceAll('â', 'a') // Proper Turkish/Arabic characters
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll("'", '');

    const aliases = {
      'subhanallah': 'Sübhanallah',
      'subhanallahh': 'Sübhanallah',
      'elhamdulillah': 'Elhamdülillah',
      'allahuekber': 'Allahu ekber',
      'allahuakbar': 'Allahu ekber',
      'allahummesallialaseyyidinamuhammed':
          'Allahümme salli alâ seyyidinâ Muhammed',
      'allah': 'Allâh',
      'lailaheillallah': 'Lâ ilâhe illallah',
      'yaallah': 'Yâ Allâh',
      'yarahman': 'Yâ Rahmân',
      'yarahim': 'Yâ Rahîm',
      'yamelik': 'Yâ Melik',
      'yakuddus': 'Yâ Kuddûs',
      'yaselam': 'Yâ Selâm',
      'yamumin': "Yâ Mü'min",
      'yaaziz': 'Yâ Azîz',
      'yalatifyaallah': 'Yâ Latîf, Yâ Allâh',
      'lailaheillaentesubhanekeinnikuntuminezzalimin':
          'Lâ ilâhe illâ ente sübhâneke innî küntü minez zâlimîn',
      'ferdunhayyunkayyumunhakemunadlunkuddus':
          'Ferdün Hayyün Kayyûmün Hakemün Adlün Kuddûs',
    };

    return aliases[normalized] ?? raw;
  }

  List<_SavedZikir> _decodeSavedZikirler(List<String>? rawList) {
    if (rawList == null || rawList.isEmpty) {
      return _defaultZikirler;
    }

    final parsed = <_SavedZikir>[];
    final seen = <String>{};
    for (final item in rawList.whereType<String>()) {
      if (item.trim().isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          final saved = _SavedZikir.fromJson(
            decoded.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          );
          final normalized = _SavedZikir(
            name: _normalizeLegacyZikirName(saved.name),
            target: saved.target,
          );
          final lookupKey = normalized.name.toLowerCase();
          if (seen.add(lookupKey)) {
            parsed.add(normalized);
          }
          continue;
        }
      } catch (_) {
        final normalized = _SavedZikir(
          name: _normalizeLegacyZikirName(item),
          target: 33,
        );
        final lookupKey = normalized.name.toLowerCase();
        if (seen.add(lookupKey)) {
          parsed.add(normalized);
        }
      }
    }

    if (parsed.isEmpty) {
      return _defaultZikirler;
    }

    final merged = List<_SavedZikir>.from(parsed);
    for (final defaultZikir in _defaultZikirler) {
      final exists = merged.any(
        (item) => item.name.toLowerCase() == defaultZikir.name.toLowerCase(),
      );
      if (!exists) {
        merged.add(defaultZikir);
      }
    }

    return merged;
  }

  Map<String, int> _decodeZikirCounts(String? raw) {
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};

      final counts = <String, int>{};
      for (final entry in decoded.entries) {
        if (entry.key == null) {
          continue;
        }
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
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(0),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.86),
                  ),
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
                                    tr: 'Zikirmatik ayarlari',
                                    en: 'Dhikr counter settings',
                                    ar: 'Ã˜Â¥Ã˜Â¹Ã˜Â¯Ã˜Â§Ã˜Â¯Ã˜Â§Ã˜Âª Ã˜Â§Ã™â€žÃ˜Â³Ã˜Â¨Ã˜Â­Ã˜Â©',
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
                                        'Hedefini, titresimi ve kayitli zikirlerini duzenle.',
                                    en:
                                        'Manage your target, haptics, and saved dhikr list.',
                                    ar:
                                        'Ã˜Â£Ã˜Â¯Ã˜Â± Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â¯Ã™Â Ã™Ë†Ã˜Â§Ã™â€žÃ˜Â§Ã™â€¡Ã˜ÂªÃ˜Â²Ã˜Â§Ã˜Â² Ã™Ë†Ã™â€šÃ˜Â§Ã˜Â¦Ã™â€¦Ã˜Â© Ã˜Â§Ã™â€žÃ˜Â£Ã˜Â°Ã™Æ’Ã˜Â§Ã˜Â± Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â­Ã™ÂÃ™Ë†Ã˜Â¸Ã˜Â©.',
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
                                    ar: 'Ã˜Â§Ã™â€žÃ™â€ Ã˜Â´Ã˜Â·',
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
                        isExpandable: true,
                        isExpanded: _isSavedZikirExpanded,
                        onToggle: () {
                          setSheetState(() {
                            _isSavedZikirExpanded = !_isSavedZikirExpanded;
                          });
                        },
                        title: _text(
                          language,
                          tr: 'Kayıtlı zikirler',
                          en: 'Saved dhikr',
                          ar: 'Saved dhikr',
                        ),
                        subtitle: _text(
                          language,
                          tr: 'Yeni zikir ekle, sec veya gerekmeyenleri kaldir.',
                          en: 'Add, select, or remove your saved dhikr entries.',
                          ar: 'Add, select, or remove your saved dhikr entries.',
                        ),
                        textPrimary: textPrimary,
                        borderColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        accentSoft: accentSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _zikirController,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                labelText: _text(
                                  language,
                                  tr: 'Zikir metni',
                                  en: 'Dhikr text',
                                  ar: 'Dhikr text',
                                ),
                                hintText: _text(
                                  language,
                                  tr: 'Ornek: Subhanallah',
                                  en: 'Example: Subhanallah',
                                  ar: 'Example: Subhanallah',
                                ),
                                filled: true,
                                fillColor: accentSoft.withOpacity(0.92),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => refreshSheet(
                                () => _saveZikir(openCounter: true),
                                setSheetState,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _zikirTargetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                labelText: _text(
                                  language,
                                  tr: 'Hedef sayisi',
                                  en: 'Target count',
                                  ar: 'Target count',
                                ),
                                hintText: '33',
                                filled: true,
                                fillColor: accentSoft.withOpacity(0.92),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => refreshSheet(
                                () => _saveZikir(openCounter: true),
                                setSheetState,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => refreshSheet(
                                  () => _saveZikir(openCounter: true),
                                  setSheetState,
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor:
                                      isDark ? AppColors.darkBg : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                label: Text(
                                  _text(
                                    language,
                                    tr: 'Listeye kaydet',
                                    en: 'Save to list',
                                    ar: 'Save to list',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ..._savedZikirler.map((zikir) {
                              final count = _zikirCounts[zikir.name] ?? 0;
                              final isSelected = zikir.name == _currentZikir;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () async {
                                      await refreshSheet(
                                        () => _openCounterForZikir(zikir.name),
                                        setSheetState,
                                      );
                                      if (context.mounted) {
                                        Navigator.of(context).maybePop();
                                      }
                                    },
                                    child: Ink(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        14,
                                        10,
                                        14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? accent.withOpacity(0.12)
                                            : accentSoft.withOpacity(0.58),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? accent.withOpacity(0.28)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  zikir.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: textPrimary,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _LibraryMetaChip(
                                                      label: _text(
                                                        language,
                                                        tr: 'Sayac',
                                                        en: 'Count',
                                                        ar: 'Count',
                                                      ),
                                                      value: '$count',
                                                      accent: accent,
                                                      background: Colors.white
                                                          .withOpacity(
                                                        isDark ? 0.06 : 0.62,
                                                      ),
                                                      textColor: textPrimary,
                                                    ),
                                                    _LibraryMetaChip(
                                                      label: _text(
                                                        language,
                                                        tr: 'Hedef',
                                                        en: 'Target',
                                                        ar: 'Target',
                                                      ),
                                                      value: '${zikir.target}',
                                                      accent: accent,
                                                      background: Colors.white
                                                          .withOpacity(
                                                        isDark ? 0.06 : 0.62,
                                                      ),
                                                      textColor: textPrimary,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!_isDefaultZikir(zikir.name))
                                            IconButton(
                                              onPressed: () => refreshSheet(
                                                () => _removeZikir(zikir.name),
                                                setSheetState,
                                              ),
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                color: textPrimary.withOpacity(
                                                  0.62,
                                                ),
                                              ),
                                              tooltip: _text(
                                                language,
                                                tr: 'Sil',
                                                en: 'Delete',
                                                ar: 'Delete',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
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
              : _buildCounterView(
                  context: context,
                  language: language,
                  isDark: isDark,
                  cardColor: cardColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: accent,
                  accentSoft: accentSoft,
                  progress: progress,
                ),
        ),
      ),
    );
  }

  Widget _buildHapticQuickMenu({
    required String language,
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required Color accentSoft,
  }) {
    return Positioned(
      left: 0,
      top: -30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _isHapticMenuOpen = !_isHapticMenuOpen;
                });
              },
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(isDark ? 0.72 : 0.82),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.vibration_rounded,
                  color: _hapticMode == _ZikirHapticMode.off
                      ? textSecondary
                      : accent,
                  size: 22,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _isHapticMenuOpen ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_isHapticMenuOpen,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(isDark ? 0.82 : 0.90),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _ZikirHapticMode.values.map((mode) {
                    final isSelected = _hapticMode == mode;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: mode != _ZikirHapticMode.values.last ? 6 : 0),
                      child: Material(
                        color: isSelected
                            ? accent.withOpacity(0.88)
                            : accentSoft.withOpacity(isDark ? 0.34 : 0.62),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () => _setHapticMode(mode),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Text(
                              _hapticModeLabel(mode, language),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? (isDark
                                        ? AppColors.darkBg
                                        : Colors.white)
                                    : textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterView({
    required BuildContext context,
    required String language,
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required Color accentSoft,
    required double progress,
  }) {
    return RefreshIndicator(
      onRefresh: _clearCounter,
      color: accent,
      backgroundColor: cardColor,
      child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _exitZikirmatik,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textPrimary,
                            size: 20,
                          ),
                          tooltip: _text(
                            language,
                            tr: 'Anasayfaya dön',
                            en: 'Go home',
                            ar: 'العودة للرئيسية',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _text(
                              language,
                              tr: 'Zikirmatik',
                              en: 'Dhikr Counter',
                              ar: 'السبحة',
                            ),
                            style: TextStyle(
                              fontSize: 24,
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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(26),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accentSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _text(
                                          language,
                                          tr: 'Hedef',
                                          en: 'Target',
                                          ar: 'Ã˜Â§Ã™â€žÃ™â€¡Ã˜Â¯Ã™Â',
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      TextField(
                                        controller: _zikirTargetController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: textPrimary,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onTapOutside: (_) {
                                          FocusScope.of(context).unfocus();
                                          _applyTypedTarget();
                                        },
                                        onSubmitted: (_) {
                                          FocusScope.of(context).unfocus();
                                          _applyTypedTarget();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                children: [
                                  Text(
                                    '$_count',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _count >= _target
                                        ? _text(
                                            language,
                                            tr: 'Tamam',
                                            en: 'Done',
                                            ar: 'Ã˜ÂªÃ™â€¦',
                                          )
                                        : _text(
                                            language,
                                            tr: 'Sayac',
                                            en: 'Counter',
                                            ar: 'Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â¯Ã˜Â§Ã˜Â¯',
                                          ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _InfoPill(
                                  label: _text(
                                    language,
                                    tr: 'Kalan',
                                    en: 'Left',
                                    ar: 'Ã˜Â§Ã™â€žÃ™â€¦Ã˜ÂªÃ˜Â¨Ã™â€šÃ™Å ',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 54),
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
                              clipBehavior: Clip.none,
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
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent.withOpacity(0.22),
                                      ),
                                    ),
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: progress),
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, val, _) {
                                    return Transform.scale(
                                      scale: coreScale,
                                      child: SizedBox(
                                        width: 270,
                                        height: 270,
                                        child: CircularProgressIndicator(
                                          value: val,
                                          strokeWidth: 12,
                                          backgroundColor: accentSoft.withOpacity(0.35),
                                          color: accent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Transform.scale(scale: coreScale, child: child),
                                _buildHapticQuickMenu(
                                  language: language,
                                  isDark: isDark,
                                  cardColor: cardColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  accent: accent,
                                  accentSoft: accentSoft,
                                ),
                              ],
                            );
                          },
                          child: Container(
                            width: 240,
                            height: 240,
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
                                      ar: 'Ã˜Â§Ã™â€žÃ™â€¦Ã˜Â³',
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
                    if (_currentZikir.isNotEmpty) ...[
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
                    ] else
                      const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _text(
                          language,
                          tr: 'Sayaci sifirla',
                          en: 'Reset counter',
                          ar: 'Ã˜Â¥Ã˜Â¹Ã˜Â§Ã˜Â¯Ã˜Â© Ã˜Â¶Ã˜Â¨Ã˜Â· Ã˜Â§Ã™â€žÃ˜Â¹Ã˜Â¯Ã˜Â§Ã˜Â¯',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLibraryView({
    required BuildContext context,
    required String language,
    required bool isDark,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required Color accentSoft,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _exitZikirmatik,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textPrimary,
                size: 20,
              ),
              tooltip: _text(
                language,
                tr: 'Anasayfaya don',
                en: 'Go home',
                ar: 'Go home',
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(
                      language,
                      tr: 'Kayitli zikirler',
                      en: 'Saved dhikr',
                      ar: 'Saved dhikr',
                    ),
                   style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _text(
                      language,
                      tr: 'Bir zikir sec veya yeni bir zikir ekle.',
                      en: 'Choose a dhikr or add a new one.',
                      ar: 'Choose a dhikr or add a new one.',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: textSecondary,
                    ),
                  ),
                ],
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
                ar: 'Settings',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(
                              language,
                              tr: 'Yeni zikir ekle',
                              en: 'Add new dhikr',
                              ar: 'Add new dhikr',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _text(
                              language,
                              tr: 'Kendi zikir listesini hizlica olustur.',
                              en: 'Create a custom dhikr entry in seconds.',
                              ar: 'Create a custom dhikr entry in seconds.',
                            ),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zikirController,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: _text(
                      language,
                      tr: 'Zikir metni',
                      en: 'Dhikr text',
                      ar: 'Dhikr text',
                    ),
                    hintText: _text(
                      language,
                      tr: 'Ornek: Subhanallah',
                      en: 'Example: Subhanallah',
                      ar: 'Example: Subhanallah',
                    ),
                    filled: true,
                    fillColor: accentSoft,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _saveZikir(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _zikirTargetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: _text(
                      language,
                      tr: 'Hedef sayisi',
                      en: 'Target count',
                      ar: 'Target count',
                    ),
                    hintText: '33',
                    filled: true,
                    fillColor: accentSoft,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _saveZikir(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _saveZikir(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    label: Text(
                      _text(
                        language,
                        tr: 'Listeye kaydet',
                        en: 'Save to list',
                        ar: 'Save to list',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ..._savedZikirler.map((zikir) {
          final count = _zikirCounts[zikir.name] ?? 0;
          final isSelected = zikir.name == _currentZikir;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _openCounterForZikir(zikir.name),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? accent.withOpacity(0.32)
                          : (isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white.withOpacity(0.85)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected ? accent.withOpacity(0.16) : accentSoft,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: isSelected ? accent : textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zikir.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _LibraryMetaChip(
                                    label: _text(
                                      language,
                                      tr: 'Sayac',
                                      en: 'Count',
                                      ar: 'Count',
                                    ),
                                    value: '$count',
                                    accent: accent,
                                    background: accentSoft,
                                    textColor: textPrimary,
                                  ),
                                  _LibraryMetaChip(
                                    label: _text(
                                      language,
                                      tr: 'Hedef',
                                      en: 'Target',
                                      ar: 'Target',
                                    ),
                                    value: '${zikir.target}',
                                    accent: accent,
                                    background: accentSoft,
                                    textColor: textPrimary,
                                  ),
                                  if (isSelected)
                                    _LibraryMetaChip(
                                      label: _text(
                                        language,
                                        tr: 'Durum',
                                        en: 'Status',
                                        ar: 'Status',
                                      ),
                                      value: _text(
                                        language,
                                        tr: 'Aktif',
                                        en: 'Active',
                                        ar: 'Active',
                                      ),
                                      accent: accent,
                                      background: accent.withOpacity(0.16),
                                      textColor: accent,
                                    ),
                                ],
                              ),
                            ],
                          ),
                      ),
                      if (!_isDefaultZikir(zikir.name))
                        IconButton(
                          onPressed: () => _removeZikir(zikir.name),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: textSecondary,
                          ),
                          tooltip: _text(
                            language,
                            tr: 'Sil',
                            en: 'Delete',
                            ar: 'Delete',
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

enum _ZikirViewMode { library, counter }

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
    this.isExpandable = false,
    this.isExpanded = true,
    this.onToggle,
  });

  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color borderColor;
  final Color accentSoft;
  final Widget child;
  final bool isExpandable;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: accentSoft.withOpacity(0.42),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isExpandable ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: textPrimary.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpandable)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textPrimary.withOpacity(0.5),
                        size: 26,
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: double.infinity,
                    child: isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: child,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 15 : 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryMetaChip extends StatelessWidget {
  const _LibraryMetaChip({
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
    required this.textColor,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor.withOpacity(0.72),
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

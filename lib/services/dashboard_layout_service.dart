// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// VE = Volumetric Efficiency
// ECT = Engine Coolant Temperature
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dashboard_layout.dart';

/// Service managing persistent multi-layout storage, active layout state,
/// frozen preview states, and design persistence for the telemetry dashboard.
class DashboardLayoutService extends ChangeNotifier {
  DashboardLayoutService._internal();

  /// Singleton access instance.
  static final DashboardLayoutService instance = DashboardLayoutService._internal();

  static const String _activeLayoutFileName = 'active_dashboard_layout.json';
  static const String _savedLayoutsFileName = 'saved_dashboard_layouts.json';

  DashboardDesign _activeDesign = DashboardDesign.createDefault();
  final List<DashboardDesign> _savedDesigns = <DashboardDesign>[];

  // Draft copy during active Edit Mode
  List<CardConfig>? _editDraftCards;

  // Frozen preview state tracking
  bool _isFreezePreview = false;
  DashboardDesign? _previewSnapshot;
  Directory? _storageDirectoryOverrideForTesting;

  bool get _skipDiskPersistence =>
      _storageDirectoryOverrideForTesting == null &&
      Platform.environment.containsKey('FLUTTER_TEST');

  /// Sets an isolated temporary directory for real disk persistence tests.
  @visibleForTesting
  void setStorageDirectoryForTesting(Directory? dir) {
    _storageDirectoryOverrideForTesting = dir;
  }

  /// Current active dashboard design.
  DashboardDesign get activeDesign => _activeDesign;

  /// Read-only collection of all saved dashboard designs.
  List<DashboardDesign> get savedDesigns => List<DashboardDesign>.unmodifiable(_savedDesigns);

  /// Whether the dashboard is currently in a frozen layout preview state.
  bool get isFreezePreview => _isFreezePreview;

  /// Whether two or more designs exist, enabling the App Bar Grid icon.
  bool get canShowGridIcon => _savedDesigns.length >= 2;

  /// Active cards currently being rendered (draft cards if editing, or active design cards).
  List<CardConfig> get displayCards {
    if (_editDraftCards != null) {
      return List<CardConfig>.unmodifiable(_editDraftCards!);
    }
    return List<CardConfig>.unmodifiable(_activeDesign.cards);
  }

  Future<Directory> _getBaseDirectory() async {
    if (_storageDirectoryOverrideForTesting != null) {
      return _storageDirectoryOverrideForTesting!;
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp;
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.current;
    }
  }

  /// Initializes the service by reading saved designs from application storage.
  Future<void> initialize() async {
    if (_skipDiskPersistence) {
      _ensureDefaultAndDeduplicate();
      notifyListeners();
      return;
    }
    _activeDesign = DashboardDesign.createDefault();
    _savedDesigns.clear();
    try {
      final Directory baseDir = await _getBaseDirectory();

      // Load active layout
      final File activeFile = File('${baseDir.path}/$_activeLayoutFileName');
      if (await activeFile.exists()) {
        final String raw = await activeFile.readAsString();
        // dynamic required here: JSON decode returns untyped structure
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _activeDesign = DashboardDesign.fromJson(decoded);
        }
      }

      // Load saved designs
      final File savedFile = File('${baseDir.path}/$_savedLayoutsFileName');
      if (await savedFile.exists()) {
        final String raw = await savedFile.readAsString();
        // dynamic required here: JSON decode returns untyped structure
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          _savedDesigns.clear();
          for (final dynamic item in decoded) {
            if (item is Map<String, dynamic>) {
              _savedDesigns.add(DashboardDesign.fromJson(item));
            }
          }
        }
      }

      final bool changed = _ensureDefaultAndDeduplicate();
      if (changed) {
        await _persistSavedDesigns();
        await _persistActiveLayout();
      }
    } catch (e) {
      debugPrint('[DashboardLayoutService] Initialization fallback: $e');
      _ensureDefaultAndDeduplicate();
    }
    notifyListeners();
  }

  /// Ensures Factory Cockpit exists at index 0 and removes duplicate saved layouts.
  bool _ensureDefaultAndDeduplicate() {
    bool modified = false;
    final DashboardDesign baselineDefault = DashboardDesign.createDefault();

    final int defaultIndex = _savedDesigns.indexWhere((DashboardDesign d) => d.isDefault);
    if (defaultIndex == -1) {
      _savedDesigns.insert(0, baselineDefault);
      modified = true;
    } else {
      if (_savedDesigns[defaultIndex].cards.isEmpty) {
        _savedDesigns[defaultIndex] = baselineDefault;
        modified = true;
      }
      if (defaultIndex != 0) {
        final DashboardDesign foundDefault = _savedDesigns.removeAt(defaultIndex);
        _savedDesigns.insert(0, foundDefault);
        modified = true;
      }
    }

    final List<DashboardDesign> uniqueDesigns = <DashboardDesign>[];
    for (final DashboardDesign candidate in _savedDesigns) {
      final bool duplicateExists = uniqueDesigns.any(
        (DashboardDesign kept) => kept.matchesLayout(candidate.cards),
      );
      if (!duplicateExists) {
        uniqueDesigns.add(candidate);
      } else {
        modified = true;
      }
    }

    if (uniqueDesigns.length != _savedDesigns.length) {
      _savedDesigns
        ..clear()
        ..addAll(uniqueDesigns);
    }

    final DashboardDesign? activeMatch = _findMatchingDesign(_activeDesign.cards);
    if (activeMatch != null && activeMatch.id != _activeDesign.id) {
      _activeDesign = activeMatch;
      modified = true;
    }

    return modified;
  }

  /// Returns the existing saved design whose layout matches [cards], or null if unique.
  DashboardDesign? _findMatchingDesign(List<CardConfig> cards) {
    for (final DashboardDesign design in _savedDesigns) {
      if (design.matchesLayout(cards)) {
        return design;
      }
    }
    final DashboardDesign factoryDefault = DashboardDesign.createDefault();
    if (factoryDefault.matchesLayout(cards)) {
      return _savedDesigns.firstWhere(
        (DashboardDesign d) => d.isDefault,
        orElse: () => factoryDefault,
      );
    }
    return null;
  }

  /// Resets layout service state to factory baseline for deterministic tests.
  @visibleForTesting
  void resetForTesting() {
    _activeDesign = DashboardDesign.createDefault();
    _savedDesigns
      ..clear()
      ..add(_activeDesign);
    _editDraftCards = null;
    _isFreezePreview = false;
    _previewSnapshot = null;
    notifyListeners();
  }

  /// Begins Edit Mode, snapshotting the current cards into an editable draft.
  void startEditMode() {
    _editDraftCards = _activeDesign.cards.map((CardConfig c) => c.copyWith()).toList();
    notifyListeners();
  }

  /// Updates draft cards during editing (e.g. on reorder, resize, or font change).
  void updateDraftCards(List<CardConfig> updated) {
    _editDraftCards = List<CardConfig>.from(updated);
    notifyListeners();
  }

  /// Updates a single card's configuration in the draft.
  void updateCardConfig(CardConfig updatedConfig) {
    if (_editDraftCards == null) return;
    final int index = _editDraftCards!.indexWhere((CardConfig c) => c.metricId == updatedConfig.metricId);
    if (index != -1) {
      _editDraftCards![index] = updatedConfig;
      notifyListeners();
    }
  }

  /// Discards unsaved edits and restores the active design.
  void cancelEditMode() {
    _editDraftCards = null;
    notifyListeners();
  }

  /// Persists the edited layout only when it differs from the factory default and all existing saved layouts.
  ///
  /// Returns true if a new unique cockpit layout was created, or false if the draft
  /// matched an existing saved design (including Factory Cockpit) without duplicating.
  Future<bool> saveEditMode() async {
    if (_editDraftCards == null) return false;

    _ensureDefaultAndDeduplicate();
    final List<CardConfig> draftSnapshot =
        _editDraftCards!.map((CardConfig c) => c.copyWith()).toList();

    final DashboardDesign? existingMatch = _findMatchingDesign(draftSnapshot);
    if (existingMatch != null) {
      _activeDesign = existingMatch;
      _editDraftCards = null;
      await _persistActiveLayout();
      notifyListeners();
      return false;
    }

    int nextNumber = _savedDesigns.length + 1;
    while (_savedDesigns.any((DashboardDesign d) => d.name == 'Cockpit Layout $nextNumber')) {
      nextNumber++;
    }

    final int timestampUs = DateTime.now().microsecondsSinceEpoch;
    String candidateId = 'design_$timestampUs';
    int idSuffix = 1;
    while (_savedDesigns.any((DashboardDesign d) => d.id == candidateId)) {
      candidateId = 'design_${timestampUs}_$idSuffix';
      idSuffix++;
    }

    final DashboardDesign newDesign = DashboardDesign(
      id: candidateId,
      name: 'Cockpit Layout $nextNumber',
      createdAt: DateTime.now(),
      cards: draftSnapshot,
    );

    _savedDesigns.add(newDesign);
    _activeDesign = newDesign;
    _editDraftCards = null;

    await _persistActiveLayout();
    await _persistSavedDesigns();
    notifyListeners();
    return true;
  }

  /// Deletes a saved design by its [id]. The immutable Factory Cockpit default cannot be deleted.
  Future<void> deleteDesign(String id) async {
    if (id == DashboardDesign.defaultDesignId) {
      return;
    }
    final int initialLength = _savedDesigns.length;
    _savedDesigns.removeWhere((DashboardDesign d) => d.id == id && !d.isDefault);
    if (_savedDesigns.length == initialLength) {
      return;
    }
    if (_activeDesign.id == id) {
      _activeDesign = _savedDesigns.isNotEmpty
          ? _savedDesigns.first
          : DashboardDesign.createDefault();
      await _persistActiveLayout();
    }
    await _persistSavedDesigns();
    notifyListeners();
  }

  /// Enters a temporary FROZEN preview of a saved design.
  void startFreezePreview(DashboardDesign designToPreview) {
    _previewSnapshot = _activeDesign;
    _activeDesign = designToPreview;
    _isFreezePreview = true;
    _editDraftCards = null;
    notifyListeners();
  }

  /// Cancels the frozen preview and restores the previous active layout.
  void cancelFreezePreview() {
    if (_previewSnapshot != null) {
      _activeDesign = _previewSnapshot!;
    }
    _isFreezePreview = false;
    _previewSnapshot = null;
    notifyListeners();
  }

  /// Permanently applies the frozen preview design as the active layout.
  Future<void> applyFreezePreview() async {
    _isFreezePreview = false;
    _previewSnapshot = null;
    await _persistActiveLayout();
    notifyListeners();
  }

  Future<void> _persistActiveLayout() async {
    if (_skipDiskPersistence) return;
    try {
      final Directory baseDir = await _getBaseDirectory();
      final File activeFile = File('${baseDir.path}/$_activeLayoutFileName');
      await activeFile.writeAsString(jsonEncode(_activeDesign.toJson()));
    } catch (e) {
      debugPrint('[DashboardLayoutService] Error persisting active layout: $e');
    }
  }

  Future<void> _persistSavedDesigns() async {
    if (_skipDiskPersistence) return;
    try {
      final Directory baseDir = await _getBaseDirectory();
      final File savedFile = File('${baseDir.path}/$_savedLayoutsFileName');
      final List<Map<String, dynamic>> payload =
          _savedDesigns.map((DashboardDesign d) => d.toJson()).toList();
      await savedFile.writeAsString(jsonEncode(payload));
    } catch (e) {
      debugPrint('[DashboardLayoutService] Error persisting saved designs: $e');
    }
  }
}

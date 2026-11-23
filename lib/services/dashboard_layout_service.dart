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
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      if (_savedDesigns.isEmpty) {
        _savedDesigns.add(_activeDesign);
      }
      notifyListeners();
      return;
    }
    try {
      final Directory baseDir = await _getBaseDirectory();

      // Load active layout
      final File activeFile = File('${baseDir.path}/$_activeLayoutFileName');
      if (await activeFile.exists()) {
        final String raw = await activeFile.readAsString();
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _activeDesign = DashboardDesign.fromJson(decoded);
        }
      }

      // Load saved designs
      final File savedFile = File('${baseDir.path}/$_savedLayoutsFileName');
      if (await savedFile.exists()) {
        final String raw = await savedFile.readAsString();
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

      // Ensure at least the initial active design is tracked in saved designs
      if (_savedDesigns.isEmpty) {
        _savedDesigns.add(_activeDesign);
        await _persistSavedDesigns();
      }
    } catch (e) {
      debugPrint('[DashboardLayoutService] Initialization fallback: $e');
      if (_savedDesigns.isEmpty) {
        _savedDesigns.add(_activeDesign);
      }
    }
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

  /// Persists both the previous design and newly saved design as specified in P3.T7.
  Future<void> saveEditMode() async {
    if (_editDraftCards == null) return;

    final DashboardDesign previousDesign = _activeDesign;
    final int newDesignNumber = _savedDesigns.length + 1;
    final DashboardDesign newDesign = DashboardDesign(
      id: 'design_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Cockpit Layout $newDesignNumber',
      createdAt: DateTime.now(),
      cards: _editDraftCards!,
    );

    // Ensure the previous design is preserved in saved designs
    final bool previousAlreadyPresent = _savedDesigns.any((DashboardDesign d) => d.id == previousDesign.id);
    if (!previousAlreadyPresent) {
      _savedDesigns.add(previousDesign);
    }

    // Add newly saved design
    _savedDesigns.add(newDesign);
    _activeDesign = newDesign;
    _editDraftCards = null;

    await _persistActiveLayout();
    await _persistSavedDesigns();
    notifyListeners();
  }

  /// Deletes a saved design by its [id].
  Future<void> deleteDesign(String id) async {
    _savedDesigns.removeWhere((DashboardDesign d) => d.id == id);
    if (_activeDesign.id == id) {
      _activeDesign = _savedDesigns.isNotEmpty ? _savedDesigns.first : DashboardDesign.createDefault();
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
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final Directory baseDir = await _getBaseDirectory();
      final File activeFile = File('${baseDir.path}/$_activeLayoutFileName');
      await activeFile.writeAsString(jsonEncode(_activeDesign.toJson()));
    } catch (e) {
      debugPrint('[DashboardLayoutService] Error persisting active layout: $e');
    }
  }

  Future<void> _persistSavedDesigns() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
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

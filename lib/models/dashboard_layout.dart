// ECU = Electronic Control Unit
// OBD = On-Board Diagnostics
// VE = Volumetric Efficiency
// RPM = Revolutions Per Minute
// TPS = Throttle Position Sensor
// MAP = Manifold Absolute Pressure
// ECT = Engine Coolant Temperature
import '../models/telemetry_metric.dart';

/// Configuration and typography sizing for a single telemetry card on the dashboard.
class CardConfig {
  /// Unique metric identifier matching [TelemetryMetric.id].
  final String metricId;

  /// Horizontal column span on the adaptive 4/6/8-column grid (1..8). Default on install is 2.
  final int colSpan;

  /// Vertical row span on the grid (1..4). Default on install is 2.
  final int rowSpan;

  /// Default title font size used when [titleFontSize] is null.
  static const double defaultTitleFontSize = 10.5;

  /// Default numeric value font size used when [valueFontSize] is null.
  static const double defaultValueFontSize = 28.0;

  /// Default unit badge font size used when [unitFontSize] is null.
  static const double defaultUnitFontSize = 9.5;

  /// Custom override font size for the card title label.
  final double? titleFontSize;

  /// Custom override font size for the numeric value readout.
  final double? valueFontSize;

  /// Custom override font size for the engineering unit pill badge.
  final double? unitFontSize;

  /// Creates a [CardConfig] instance.
  const CardConfig({
    required this.metricId,
    this.colSpan = 2,
    this.rowSpan = 2,
    this.titleFontSize,
    this.valueFontSize,
    this.unitFontSize,
  });

  /// Clones this config with optional overrides.
  CardConfig copyWith({
    String? metricId,
    int? colSpan,
    int? rowSpan,
    double? titleFontSize,
    double? valueFontSize,
    double? unitFontSize,
  }) {
    return CardConfig(
      metricId: metricId ?? this.metricId,
      colSpan: colSpan ?? this.colSpan,
      rowSpan: rowSpan ?? this.rowSpan,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      valueFontSize: valueFontSize ?? this.valueFontSize,
      unitFontSize: unitFontSize ?? this.unitFontSize,
    );
  }

  /// Serializes this config into a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metric_id': metricId,
      'col_span': colSpan,
      'row_span': rowSpan,
      if (titleFontSize != null) 'title_font_size': titleFontSize,
      if (valueFontSize != null) 'value_font_size': valueFontSize,
      if (unitFontSize != null) 'unit_font_size': unitFontSize,
    };
  }

  /// Deserializes a [CardConfig] from a JSON map.
  factory CardConfig.fromJson(Map<String, dynamic> json) {
    return CardConfig(
      metricId: json['metric_id'] as String? ?? 'rpm',
      colSpan: ((json['col_span'] as num?)?.toInt() ?? 2).clamp(1, 8),
      rowSpan: ((json['row_span'] as num?)?.toInt() ?? 2).clamp(1, 4),
      titleFontSize: (json['title_font_size'] as num?)?.toDouble(),
      valueFontSize: (json['value_font_size'] as num?)?.toDouble(),
      unitFontSize: (json['unit_font_size'] as num?)?.toDouble(),
    );
  }
}

/// Persistent record representing a complete saved dashboard design.
class DashboardDesign {
  /// Reserved identifier for the factory baseline layout that cannot be deleted.
  static const String defaultDesignId = 'default_design';

  /// Reserved human-readable name for the factory baseline layout.
  static const String defaultDesignName = 'Factory Cockpit';

  /// Unique identifier for this saved design.
  final String id;

  /// Human-readable design title (e.g. 'Factory Cockpit', 'Cockpit Layout 2').
  final String name;

  /// Timestamp when this design was created or updated.
  final DateTime createdAt;

  /// Ordered list of card configurations.
  final List<CardConfig> cards;

  /// Whether this design is the immutable default baseline cockpit.
  bool get isDefault => id == defaultDesignId;

  /// Creates a [DashboardDesign] instance.
  const DashboardDesign({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.cards,
  });

  /// Clones this design with optional overrides.
  DashboardDesign copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<CardConfig>? cards,
  }) {
    return DashboardDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      cards: cards ?? this.cards,
    );
  }

  /// Serializes this design into a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'cards': cards.map((CardConfig card) => card.toJson()).toList(),
    };
  }

  /// Deserializes a [DashboardDesign] from a JSON map.
  factory DashboardDesign.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawCards = json['cards'] as List<dynamic>?;
    final List<CardConfig> parsedCards = <CardConfig>[];
    if (rawCards != null) {
      for (final dynamic item in rawCards) {
        if (item is Map<String, dynamic>) {
          parsedCards.add(CardConfig.fromJson(item));
        }
      }
    }

    return DashboardDesign(
      id: json['id'] as String? ?? 'default_design',
      name: json['name'] as String? ?? 'Cockpit Design',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      cards: parsedCards,
    );
  }

  /// Compares two card lists for structural and typographic layout equivalence.
  ///
  /// Checks card count, order, [CardConfig.metricId], [CardConfig.colSpan],
  /// [CardConfig.rowSpan], and effective font sizes (treating null as default).
  static bool cardsMatchLayout(List<CardConfig> firstCards, List<CardConfig> secondCards) {
    if (firstCards.length != secondCards.length) return false;
    for (int index = 0; index < firstCards.length; index++) {
      final CardConfig first = firstCards[index];
      final CardConfig second = secondCards[index];
      if (first.metricId != second.metricId) return false;
      if (first.colSpan != second.colSpan) return false;
      if (first.rowSpan != second.rowSpan) return false;

      final double firstTitle = first.titleFontSize ?? CardConfig.defaultTitleFontSize;
      final double secondTitle = second.titleFontSize ?? CardConfig.defaultTitleFontSize;
      if ((firstTitle - secondTitle).abs() >= 0.05) return false;

      final double firstValue = first.valueFontSize ?? CardConfig.defaultValueFontSize;
      final double secondValue = second.valueFontSize ?? CardConfig.defaultValueFontSize;
      if ((firstValue - secondValue).abs() >= 0.05) return false;

      final double firstUnit = first.unitFontSize ?? CardConfig.defaultUnitFontSize;
      final double secondUnit = second.unitFontSize ?? CardConfig.defaultUnitFontSize;
      if ((firstUnit - secondUnit).abs() >= 0.05) return false;
    }
    return true;
  }

  /// Returns true when this design has the exact same layout and font sizes as [otherCards].
  bool matchesLayout(List<CardConfig> otherCards) {
    return cardsMatchLayout(cards, otherCards);
  }

  /// Creates a default baseline design with standard telemetry parameters (2x2 on adaptive grid).
  factory DashboardDesign.createDefault({
    String id = defaultDesignId,
    String name = defaultDesignName,
  }) {
    return DashboardDesign(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      cards: const <CardConfig>[
        CardConfig(metricId: 'rpm', colSpan: 2, rowSpan: 2),
        CardConfig(metricId: 'tps', colSpan: 2, rowSpan: 2),
        CardConfig(metricId: 'map', colSpan: 2, rowSpan: 2),
        CardConfig(metricId: 've', colSpan: 2, rowSpan: 2),
        CardConfig(metricId: 'ect', colSpan: 2, rowSpan: 2),
        CardConfig(metricId: 'vva', colSpan: 2, rowSpan: 2),
      ],
    );
  }
}

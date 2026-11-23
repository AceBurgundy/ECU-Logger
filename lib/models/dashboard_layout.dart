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

  /// Horizontal column span on the 2-column grid: 1 = half width, 2 = full width.
  final int colSpan;

  /// Vertical row span: 1 = standard height, 2 = double/tall height.
  final int rowSpan;

  /// Custom override font size for the card title label.
  final double? titleFontSize;

  /// Custom override font size for the numeric value readout.
  final double? valueFontSize;

  /// Custom override font size for the engineering unit pill badge.
  final double? unitFontSize;

  /// Creates a [CardConfig] instance.
  const CardConfig({
    required this.metricId,
    this.colSpan = 1,
    this.rowSpan = 1,
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
      colSpan: (json['col_span'] as num?)?.toInt() ?? 1,
      rowSpan: (json['row_span'] as num?)?.toInt() ?? 1,
      titleFontSize: (json['title_font_size'] as num?)?.toDouble(),
      valueFontSize: (json['value_font_size'] as num?)?.toDouble(),
      unitFontSize: (json['unit_font_size'] as num?)?.toDouble(),
    );
  }
}

/// Persistent record representing a complete saved dashboard design.
class DashboardDesign {
  /// Unique identifier for this saved design.
  final String id;

  /// Human-readable design title (e.g. 'Default Cockpit', 'Design 2').
  final String name;

  /// Timestamp when this design was created or updated.
  final DateTime createdAt;

  /// Ordered list of card configurations.
  final List<CardConfig> cards;

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

  /// Creates a default baseline design with standard telemetry parameters.
  factory DashboardDesign.createDefault({String id = 'default_design', String name = 'Factory Cockpit'}) {
    return DashboardDesign(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      cards: const <CardConfig>[
        CardConfig(metricId: 'rpm', colSpan: 1, rowSpan: 1),
        CardConfig(metricId: 'tps', colSpan: 1, rowSpan: 1),
        CardConfig(metricId: 'map', colSpan: 1, rowSpan: 1),
        CardConfig(metricId: 've', colSpan: 1, rowSpan: 1),
        CardConfig(metricId: 'ect', colSpan: 1, rowSpan: 1),
        CardConfig(metricId: 'vva', colSpan: 1, rowSpan: 1),
      ],
    );
  }
}

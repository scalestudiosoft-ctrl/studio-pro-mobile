class AppConstants {
  static const String appName = 'Studio Pro';
  static const String syncSchemaVersion = 'sp_mobile_sync_v1';
  static const String appVersion = '2.1.1';
  static const String defaultBusinessId = 'NEG-001';
  static const List<String> paymentMethods = <String>[
    'efectivo',
    'transferencia',
    'tarjeta',
    'nequi',
    'daviplata',
    'otro',
  ];
  static const List<String> appointmentStatuses = <String>[
    'pendiente',
    'llego',
    'en proceso',
    'finalizado',
    'cancelado',
  ];
  static const List<Map<String, String>> businessTypes = <Map<String, String>>[
    <String, String>{'value': 'barbershop', 'label': 'Barbería'},
    <String, String>{'value': 'beauty_salon', 'label': 'Salón de belleza'},
    <String, String>{'value': 'nails_studio', 'label': 'Nails studio'},
    <String, String>{'value': 'spa', 'label': 'Spa'},
  ];
}

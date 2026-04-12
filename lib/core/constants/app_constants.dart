class AppConstants {
  static const String appName = 'Studio Pro';
  static const String syncSchemaVersion = 'sp_mobile_sync_v2';
  static const String appVersion = '2.2.0';
  static const String defaultBusinessId = 'NEG-001';
  static const String defaultPrimaryButtonColor = '#B14E8A';
  static const String defaultSecondaryButtonColor = '#6B6475';

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
}

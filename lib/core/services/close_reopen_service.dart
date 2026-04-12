import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class CloseReopenService {
  const CloseReopenService();

  Future<void> reopenFromExportFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('No se encontró el archivo JSON exportado.');
    }

    final raw = await file.readAsString();
    final payload = jsonDecode(raw);
    if (payload is! Map<String, dynamic>) {
      throw StateError('El archivo JSON no tiene un formato válido.');
    }

    final schema = '${payload['schema_version'] ?? ''}';
    if (schema != 'sp_mobile_sync_v1') {
      throw StateError('El JSON no corresponde al esquema esperado de Studio Pro.');
    }

    final business = (payload['business'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final device = (payload['device'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final closeBatch = (payload['close_batch'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final workers = (payload['workers'] as List?)?.cast<Map>() ?? const <Map>[];
    final clients = (payload['clients'] as List?)?.cast<Map>() ?? const <Map>[];
    final catalog = (payload['services_catalog'] as List?)?.cast<Map>() ?? const <Map>[];
    final appointments = (payload['appointments_pending'] as List?)?.cast<Map>() ?? const <Map>[];
    final services = (payload['services_performed'] as List?)?.cast<Map>() ?? const <Map>[];
    final sales = (payload['sales'] as List?)?.cast<Map>() ?? const <Map>[];
    final cashMovements = (payload['cash_movements'] as List?)?.cast<Map>() ?? const <Map>[];
    final dailySummary = (payload['daily_summary'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final sessionId = '${closeBatch['cash_session_id'] ?? ''}'.trim();
    final workDate = '${closeBatch['work_date'] ?? ''}'.trim();
    if (sessionId.isEmpty || workDate.isEmpty) {
      throw StateError('El JSON no contiene una sesión de caja válida para reabrir.');
    }

    final db = AppDatabase.instance;
    final existingBusiness = await db.firstRow('business_profile');
    await db.executeBatch((batch) async {
      if (existingBusiness != null) {
        batch.update(
          'business_profile',
          <String, Object?>{
            'business_id': business['business_id'] ?? existingBusiness['business_id'],
            'name': business['business_name'] ?? existingBusiness['name'],
            'city': business['city'] ?? existingBusiness['city'],
            'business_type': business['business_type'] ?? existingBusiness['business_type'],
            'device_name': device['device_name'] ?? existingBusiness['device_name'],
          },
          where: 'business_id = ?',
          whereArgs: <Object?>[existingBusiness['business_id']]
        );
      }

      batch.update(
        'cash_sessions',
        <String, Object?>{'status': 'closed'},
        where: 'status = ?',
        whereArgs: <Object?>['open'],
      );

      batch.insert(
        'cash_sessions',
        <String, Object?>{
          'id': sessionId,
          'work_date': workDate,
          'opened_at': closeBatch['opened_at'] ?? DateTime.now().toIso8601String(),
          'closed_at': null,
          'opening_cash': (closeBatch['opening_cash'] as num?)?.toDouble() ?? 0,
          'status': 'open',
          'opened_by': closeBatch['closed_by'] ?? 'mobile_user',
          'closing_notes': '',
        },
          conflictAlgorithm: ConflictAlgorithm.replace,
      );

      batch.delete('daily_closings', where: 'id = ? OR work_date = ?', whereArgs: <Object?>['${closeBatch['close_batch_id'] ?? ''}', workDate]);

      for (final row in workers) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'workers',
          <String, Object?>{
            'id': data['worker_id'],
            'name': data['worker_name'],
            'phone': null,
            'commission_type': 'percent',
            'commission_value': 40,
            'active': (data['active'] == true) ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in clients) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'clients',
          <String, Object?>{
            'id': data['client_id'],
            'name': data['client_name'],
            'phone': data['client_phone'] ?? '',
            'notes': data['client_notes'] ?? '',
            'birthday': data['birthday'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in catalog) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'service_catalog',
          <String, Object?>{
            'code': data['service_code'],
            'name': data['service_name'],
            'base_price': (data['base_price'] as num?)?.toDouble() ?? 0,
            'duration_minutes': (data['duration_minutes'] as num?)?.toInt() ?? 45,
            'commission_percent': (data['commission_percent'] as num?)?.toDouble() ?? 0,
            'description': data['description'] ?? '',
            'active': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in appointments) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'appointments',
          <String, Object?>{
            'id': data['appointment_id'],
            'client_id': data['client_id'] ?? '',
            'client_name': data['client_name'] ?? '',
            'worker_id': data['worker_id'],
            'worker_name': data['worker_name'],
            'service_code': data['service_code'],
            'service_name': data['service_name'],
            'scheduled_at': data['scheduled_at'],
            'status': data['status'] ?? 'pendiente',
            'notes': data['notes'] ?? '',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in services) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'service_records',
          <String, Object?>{
            'id': data['performed_id'],
            'performed_at': data['performed_at'],
            'client_id': data['client_id'] ?? '',
            'client_name': data['client_name'] ?? '',
            'worker_id': data['worker_id'] ?? '',
            'worker_name': data['worker_name'] ?? '',
            'service_code': data['service_code'] ?? '',
            'service_name': data['service_name'] ?? '',
            'unit_price': (data['unit_price'] as num?)?.toDouble() ?? 0,
            'payment_method': data['payment_method'] ?? 'efectivo',
            'status': data['status'] ?? 'finalizado',
            'notes': data['notes'] ?? '',
            'cash_session_id': data['cash_session_id'] ?? sessionId,
            'source_appointment_id': data['source_appointment_id'],
            'origin_type': data['origin_type'] ?? 'cash_manual',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in sales) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'sales',
          <String, Object?>{
            'id': data['sale_id'],
            'sale_at': data['sale_at'],
            'client_id': data['client_id'] ?? '',
            'worker_id': data['worker_id'] ?? '',
            'service_record_id': data['performed_id'] ?? '',
            'net_total': (data['net_total'] as num?)?.toDouble() ?? 0,
            'payment_method': data['payment_method'] ?? 'efectivo',
            'payment_status': data['payment_status'] ?? 'paid',
            'client_name': data['client_name'],
            'worker_name': data['worker_name'],
            'service_code': data['service_code'],
            'service_name': data['service_name'],
            'cash_session_id': data['cash_session_id'] ?? sessionId,
            'source_appointment_id': data['source_appointment_id'],
            'origin_type': data['origin_type'] ?? 'cash_manual',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final row in cashMovements) {
        final data = row.cast<String, dynamic>();
        batch.insert(
          'cash_movements',
          <String, Object?>{
            'id': data['movement_id'],
            'movement_at': data['movement_at'],
            'type': data['type'] ?? 'expense',
            'concept': data['concept'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0,
            'payment_method': data['payment_method'] ?? 'efectivo',
            'notes': data['notes'] ?? '',
            'sale_id': data['sale_id'],
            'client_id': data['client_id'],
            'client_name': data['client_name'],
            'worker_id': data['worker_id'],
            'worker_name': data['worker_name'],
            'service_code': data['service_code'],
            'service_name': data['service_name'],
            'cash_session_id': data['cash_session_id'] ?? sessionId,
            'source_appointment_id': data['source_appointment_id'],
            'origin_type': data['origin_type'] ?? 'manual',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      batch.insert(
        'daily_closings',
        <String, Object?>{
          'id': '${closeBatch['close_batch_id'] ?? 'REOPEN-$sessionId'}',
          'work_date': workDate,
          'opened_at': closeBatch['opened_at'] ?? DateTime.now().toIso8601String(),
          'closed_at': closeBatch['closed_at'] ?? DateTime.now().toIso8601String(),
          'opening_cash': (closeBatch['opening_cash'] as num?)?.toDouble() ?? 0,
          'sales_total': (dailySummary['sales_total'] as num?)?.toDouble() ?? 0,
          'expenses_total': (dailySummary['expenses_total'] as num?)?.toDouble() ?? 0,
          'expected_cash_closing': (dailySummary['expected_cash_closing'] as num?)?.toDouble() ?? 0,
          'export_file_name': (payload['export_meta'] as Map?)?['file_name'] ?? p.basename(path),
          'closed_by': closeBatch['closed_by'] ?? 'mobile_user',
          'notes': 'Reabierto desde historial',
        },
          conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}

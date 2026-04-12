import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/services/app_sync_bus.dart';
import '../../core/services/closing_export_service.dart';
import '../../core/services/daily_operation_validator.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/business_logo_avatar.dart';
import '../../shared/widgets/module_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClosingExportService _closingExportService = const ClosingExportService();
  final DailyOperationValidator _validator = const DailyOperationValidator();

  String _businessName = 'Studio Pro';
  String _businessType = 'barbershop';
  String _city = '';
  String _logoPath = '';
  bool _cashOpen = false;
  double _salesTotal = 0;
  int _servicesCount = 0;
  int _appointmentsCount = 0;
  int _clientsCount = 0;
  DailyValidationResult? _validation;

  @override
  void initState() {
    super.initState();
    AppSyncBus.changes.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    AppSyncBus.changes.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final business = await db.firstRow('business_profile');
    final summary = await _closingExportService.buildTodaySummary();
    final appointments = await db.queryRaw(
      'SELECT * FROM appointments WHERE substr(scheduled_at, 1, 10) = ?',
      <Object?>['${summary['workDate']}'],
    );
    final clients = await db.queryAll('clients');
    final validation = await _validator.validateForDate(DateTime.now());
    if (!mounted) return;
    setState(() {
      _businessName = '${business?['name'] ?? 'Studio Pro'}';
      _businessType = '${business?['business_type'] ?? 'barbershop'}';
      _city = '${business?['city'] ?? ''}';
      _logoPath = '${business?['logo_path'] ?? ''}';
      _cashOpen = summary['session'] != null;
      _salesTotal = (summary['salesTotal'] as num).toDouble();
      _servicesCount = (summary['servicesCount'] as num).toInt();
      _appointmentsCount = appointments.length;
      _clientsCount = clients.length;
      _validation = validation;
    });
  }

  String get _segmentLabel {
    switch (_businessType) {
      case 'beauty_salon':
        return 'Salón de belleza';
      case 'nails_studio':
        return 'Nails studio';
      case 'spa':
        return 'Spa';
      default:
        return 'Barbería';
    }
  }

  @override
  Widget build(BuildContext context) {
    final warnings = <String>[...?_validation?.blockingIssues, ...?_validation?.warnings];
    final moduleTiles = <Widget>[
      ModuleTile(
        title: 'Caja',
        subtitle: _cashOpen ? 'Registrar ventas y movimientos' : 'Abrir caja y empezar el día',
        icon: Icons.point_of_sale_rounded,
        tint: const Color(0xFF1AA06D),
        onTap: () => context.go('/cash'),
      ),
      ModuleTile(
        title: 'Agenda',
        subtitle: 'Citas del día y programación',
        icon: Icons.event_note_rounded,
        tint: const Color(0xFF3C82F6),
        onTap: () => context.go('/agenda'),
      ),
      ModuleTile(
        title: 'Servicios',
        subtitle: 'Catálogo con precio y duración',
        icon: Icons.design_services_rounded,
        tint: const Color(0xFF8B5CF6),
        onTap: () => context.go('/catalog'),
      ),
      ModuleTile(
        title: 'Clientes',
        subtitle: 'Base de clientes y seguimiento',
        icon: Icons.people_alt_rounded,
        tint: const Color(0xFFF97316),
        onTap: () => context.push('/clients'),
      ),
      ModuleTile(
        title: 'Profesionales',
        subtitle: 'Equipo, comisiones y control',
        icon: Icons.badge_rounded,
        tint: const Color(0xFF6366F1),
        onTap: () => context.push('/workers'),
      ),
      ModuleTile(
        title: 'Cierre',
        subtitle: 'Revisión diaria y exportación',
        icon: Icons.task_alt_rounded,
        tint: const Color(0xFFEF4444),
        onTap: () => context.go('/closing'),
      ),
      ModuleTile(
        title: 'Exportar',
        subtitle: 'Historial y envío al escritorio',
        icon: Icons.ios_share_rounded,
        tint: const Color(0xFF06B6D4),
        onTap: () => context.push('/exports'),
      ),
      ModuleTile(
        title: 'Configurar',
        subtitle: 'Logo, negocio y dispositivo',
        icon: Icons.settings_rounded,
        tint: const Color(0xFF64748B),
        onTap: () => context.push('/settings'),
      ),
    ];

    return AppShell(
      title: _businessName,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFD98FB3), Color(0xFFB14E8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x261B1026),
                    blurRadius: 30,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      BusinessLogoAvatar(
                        logoPath: _logoPath,
                        radius: 32,
                        iconSize: 28,
                        backgroundColor: Colors.white.withOpacity(0.88),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _businessName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_segmentLabel${_city.trim().isEmpty ? '' : ' • $_city'}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/settings'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _HeroMetricChip(
                        icon: _cashOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        label: _cashOpen ? 'Caja abierta' : 'Caja cerrada',
                      ),
                      _HeroMetricChip(icon: Icons.today_rounded, label: formatShortDate(DateTime.now())),
                      _HeroMetricChip(icon: Icons.sell_rounded, label: '${_servicesCount} servicios'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Módulos principales',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Todo lo importante del negocio a uno o dos toques.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D6677)),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moduleTiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.98,
              ),
              itemBuilder: (context, index) => moduleTiles[index],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickStatCard(
                    title: 'Ventas hoy',
                    value: copCurrency.format(_salesTotal),
                    icon: Icons.payments_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    title: 'Citas',
                    value: '$_appointmentsCount',
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickStatCard(
                    title: 'Clientes',
                    value: '$_clientsCount',
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickStatCard(
                    title: 'Servicios',
                    value: '$_servicesCount',
                    icon: Icons.content_cut_rounded,
                  ),
                ),
              ],
            ),
            if (warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF2D4A6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF9A5D00)),
                        const SizedBox(width: 8),
                        Text(
                          'Pendientes por revisar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...warnings.take(4).map(
                      (issue) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Text('• $issue'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x10140A2B),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Flujo recomendado',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Configura negocio y logo.\n2. Abre caja.\n3. Agenda o factura.\n4. Revisa cierre.\n5. Exporta JSON por WhatsApp.'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ActionChip(label: const Text('Abrir caja'), onPressed: () => context.go('/cash')),
                      ActionChip(label: const Text('Nueva cita'), onPressed: () => context.go('/agenda')),
                      ActionChip(label: const Text('Exportar cierre'), onPressed: () => context.go('/closing')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10140A2B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: const Color(0xFFB14E8A)),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6E6A7C))),
        ],
      ),
    );
  }
}

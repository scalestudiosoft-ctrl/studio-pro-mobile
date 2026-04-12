import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import 'business_logo_avatar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 16,
        title: Row(
          children: <Widget>[
            const _ShellLogo(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    'Studio Pro Mobile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7A7386),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          ...?actions,
          PopupMenuButton<String>(
            tooltip: 'Atajos',
            position: PopupMenuPosition.under,
            onSelected: (value) {
              switch (value) {
                case 'clients':
                  context.push('/clients');
                  break;
                case 'workers':
                  context.push('/workers');
                  break;
                case 'catalog':
                  context.push('/catalog');
                  break;
                case 'exports':
                  context.push('/exports');
                  break;
                case 'settings':
                  context.push('/settings');
                  break;
              }
            },
            itemBuilder: (context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'clients', child: Text('Clientes')),
              PopupMenuItem<String>(value: 'workers', child: Text('Profesionales')),
              PopupMenuItem<String>(value: 'catalog', child: Text('Catálogo')),
              PopupMenuDivider(),
              PopupMenuItem<String>(value: 'exports', child: Text('Historial de cierres')),
              PopupMenuItem<String>(value: 'settings', child: Text('Configuración')),
            ],
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onNavigate(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.event_note_rounded), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.design_services_rounded), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_rounded), label: 'Caja'),
          NavigationDestination(icon: Icon(Icons.task_alt_rounded), label: 'Cierre'),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/agenda')) return 1;
    if (location.startsWith('/new-service') || location.startsWith('/catalog')) return 2;
    if (location.startsWith('/cash')) return 3;
    if (location.startsWith('/closing') || location.startsWith('/exports')) return 4;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/agenda');
        return;
      case 2:
        context.go('/catalog');
        return;
      case 3:
        context.go('/cash');
        return;
      case 4:
        context.go('/closing');
        return;
    }
  }
}

class _ShellLogo extends StatelessWidget {
  const _ShellLogo();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Object?>?>(
      future: AppDatabase.instance.firstRow('business_profile'),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        return BusinessLogoAvatar(
          logoPath: profile == null ? null : '${profile['logo_path'] ?? ''}',
          radius: 21,
          iconSize: 20,
        );
      },
    );
  }
}

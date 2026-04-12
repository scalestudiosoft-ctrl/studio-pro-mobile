import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/services/app_sync_bus.dart';
import '../../shared/widgets/app_shell.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Map<String, String> _buttonPalette = <String, String>{
    'Rosa Studio': '#B14E8A',
    'Morado Premium': '#6D28D9',
    'Azul Profesional': '#2563EB',
    'Verde Spa': '#0F766E',
    'Negro Elegante': '#1F2937',
    'Coral Nails': '#E85D75',
  };

  final _businessIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ownerController = TextEditingController();
  final _deviceController = TextEditingController();
  final _openingCashController = TextEditingController();
  Map<String, Object?>? _profile;
  String _primaryColor = AppConstants.defaultPrimaryButtonColor;
  String _secondaryColor = AppConstants.defaultSecondaryButtonColor;

  @override
  void initState() {
    super.initState();
    AppSyncBus.changes.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    AppSyncBus.changes.removeListener(_onDataChanged);
    _businessIdController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _ownerController.dispose();
    _deviceController.dispose();
    _openingCashController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final profile = await AppDatabase.instance.firstRow('business_profile');
    if (!mounted || profile == null) return;
    _profile = profile;
    _businessIdController.text = '${profile['business_id'] ?? ''}';
    _nameController.text = '${profile['name'] ?? ''}';
    _cityController.text = '${profile['city'] ?? ''}';
    _ownerController.text = '${profile['owner_name'] ?? ''}';
    _deviceController.text = '${profile['device_name'] ?? ''}';
    _openingCashController.text = '${((profile['default_opening_cash'] as num?) ?? 0).toDouble().toInt()}';
    _primaryColor = '${profile['primary_button_color'] ?? AppConstants.defaultPrimaryButtonColor}';
    _secondaryColor = '${profile['secondary_button_color'] ?? AppConstants.defaultSecondaryButtonColor}';
    setState(() {});
  }

  Future<void> _save() async {
    if (_profile == null) return;
    if (_businessIdController.text.trim().isEmpty || _nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business ID, nombre y ciudad son obligatorios.')));
      return;
    }
    await AppDatabase.instance.update(
      'business_profile',
      <String, Object?>{
        'business_id': _businessIdController.text.trim(),
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'business_type': 'barbershop',
        'owner_name': _ownerController.text.trim(),
        'device_name': _deviceController.text.trim().isEmpty ? 'Android' : _deviceController.text.trim(),
        'default_opening_cash': double.tryParse(_openingCashController.text.trim()) ?? 0,
        'primary_button_color': _primaryColor,
        'secondary_button_color': _secondaryColor,
      },
      where: 'business_id = ?',
      whereArgs: <Object?>[_profile!['business_id']],
    );
    if (!mounted) return;
    AppSyncBus.bump();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada.')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Configuración',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  TextField(controller: _businessIdController, decoration: const InputDecoration(labelText: 'Business ID')),
                  const SizedBox(height: 12),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del negocio')),
                  const SizedBox(height: 12),
                  TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ciudad')),
                  const SizedBox(height: 12),
                  TextField(controller: _ownerController, decoration: const InputDecoration(labelText: 'Responsable')),
                  const SizedBox(height: 12),
                  TextField(controller: _deviceController, decoration: const InputDecoration(labelText: 'Nombre del dispositivo')),
                  const SizedBox(height: 12),
                  TextField(controller: _openingCashController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Apertura sugerida')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Colores de botones', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Personaliza el color principal de los botones y el color de apoyo para acciones secundarias.'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _primaryColor,
                    decoration: const InputDecoration(labelText: 'Botón principal'),
                    items: _buttonPalette.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.value,
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(radius: 8, backgroundColor: _hexToColor(entry.value)),
                                  const SizedBox(width: 10),
                                  Text(entry.key),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _primaryColor = value ?? AppConstants.defaultPrimaryButtonColor),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _secondaryColor,
                    decoration: const InputDecoration(labelText: 'Botón secundario'),
                    items: _buttonPalette.entries
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry.value,
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(radius: 8, backgroundColor: _hexToColor(entry.value)),
                                  const SizedBox(width: 10),
                                  Text(entry.key),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _secondaryColor = value ?? AppConstants.defaultSecondaryButtonColor),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: _hexToColor(_primaryColor)), child: const Text('Botón principal')),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hexToColor(_secondaryColor),
                          side: BorderSide(color: _hexToColor(_secondaryColor).withOpacity(0.35)),
                        ),
                        child: const Text('Botón secundario'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _save, child: const Text('Guardar cambios'))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Accesos', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Configura aquí los datos del negocio y los colores visuales. El JSON saldrá con el Business ID del estudio y con el dispositivo correcto para escritorio.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ActionChip(label: const Text('Profesionales'), onPressed: () => context.push('/workers')),
                      ActionChip(label: const Text('Clientes'), onPressed: () => context.push('/clients')),
                      ActionChip(label: const Text('Catálogo'), onPressed: () => context.push('/catalog')),
                      ActionChip(label: const Text('Historial de cierres'), onPressed: () => context.push('/exports')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String value) {
    final normalized = value.replaceAll('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}

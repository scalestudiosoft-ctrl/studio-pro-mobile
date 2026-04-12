import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/services/app_sync_bus.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/business_logo_avatar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _businessIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _ownerController = TextEditingController();
  final _deviceController = TextEditingController();
  final _openingCashController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, Object?>? _profile;
  String _businessType = 'barbershop';
  String _logoPath = '';
  bool _saving = false;

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
    _openingCashController.text = '${((profile['default_opening_cash'] as num?) ?? 0).toDouble().toStringAsFixed(0)}';
    setState(() {
      _businessType = '${profile['business_type'] ?? 'barbershop'}';
      _logoPath = '${profile['logo_path'] ?? ''}';
    });
  }

  Future<void> _pickLogo() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1200);
    if (image == null || !mounted) return;
    setState(() => _logoPath = image.path);
  }

  void _removeLogo() {
    setState(() => _logoPath = '');
  }

  Future<void> _save() async {
    if (_profile == null) return;
    if (_businessIdController.text.trim().isEmpty || _nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business ID, nombre y ciudad son obligatorios.')),
      );
      return;
    }

    setState(() => _saving = true);
    await AppDatabase.instance.update(
      'business_profile',
      <String, Object?>{
        'business_id': _businessIdController.text.trim(),
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'business_type': _businessType,
        'owner_name': _ownerController.text.trim(),
        'device_name': _deviceController.text.trim().isEmpty ? 'Android' : _deviceController.text.trim(),
        'default_opening_cash': double.tryParse(_openingCashController.text.trim()) ?? 0,
        'logo_path': _logoPath.trim(),
      },
      where: 'business_id = ?',
      whereArgs: <Object?>[_profile!['business_id']],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    AppSyncBus.bump();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada.')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCustomLogo = _logoPath.trim().isNotEmpty && File(_logoPath).existsSync();

    return AppShell(
      title: 'Configuración',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
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
              children: <Widget>[
                Row(
                  children: <Widget>[
                    BusinessLogoAvatar(
                      logoPath: _logoPath,
                      radius: 36,
                      iconSize: 28,
                      backgroundColor: const Color(0xFFF4E6EE),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Branding del negocio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            hasCustomLogo
                                ? 'Tu logo ya está listo para verse en la cabecera y en el inicio.'
                                : 'Carga el logo desde galería para que Studio Pro se vea más profesional.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6E6A7C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: Text(hasCustomLogo ? 'Cambiar logo' : 'Cargar logo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (hasCustomLogo)
                      OutlinedButton.icon(
                        onPressed: _removeLogo,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Quitar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  TextField(controller: _businessIdController, decoration: const InputDecoration(labelText: 'Business ID')),
                  const SizedBox(height: 12),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nombre del negocio')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _businessType,
                    items: AppConstants.businessTypes
                        .map((item) => DropdownMenuItem<String>(value: item['value'], child: Text(item['label']!)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _businessType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Tipo de negocio'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Ciudad')),
                  const SizedBox(height: 12),
                  TextField(controller: _ownerController, decoration: const InputDecoration(labelText: 'Responsable')),
                  const SizedBox(height: 12),
                  TextField(controller: _deviceController, decoration: const InputDecoration(labelText: 'Nombre del dispositivo')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _openingCashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Apertura sugerida'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Guardando...' : 'Guardar configuración'),
                    ),
                  ),
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
                  Text('Accesos rápidos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Configura la base operativa del negocio y mantén el branding listo para el equipo.'),
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
}

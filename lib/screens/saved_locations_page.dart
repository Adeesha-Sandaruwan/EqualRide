import 'package:flutter/material.dart';

import '../models/saved_location.dart';
import '../services/saved_location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';
import 'map_picker_page.dart';

class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({
    super.key,
    required this.userId,
    required this.onUseLocation,
  });

  final String userId;
  final ValueChanged<String> onUseLocation;

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  final SavedLocationService _locationService = SavedLocationService();

  Future<void> _showLocationDialog({
    SavedLocation? location,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _SavedLocationFormDialog(
        location: location,
        onSave: (name, address) async {
          if (location == null) {
            await _locationService.addLocation(
              userId: widget.userId,
              name: name,
              address: address,
            );
            return;
          }

          await _locationService.updateLocation(
            userId: widget.userId,
            location: location,
            name: name,
            address: address,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(SavedLocation location) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete saved location?'),
          content: Text(
            'Remove "${location.name}" from your saved locations?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _locationService.deleteLocation(
        userId: widget.userId,
        locationId: location.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${location.name} was deleted.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this location. Please try again.'),
          ),
        );
      }
    }
  }

  void _useLocation(SavedLocation location) {
    widget.onUseLocation(location.address);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add location'),
      ),
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Saved locations',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'Save frequent destinations and use them in route search.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<SavedLocation>>(
                  stream: _locationService.watchLocations(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _MessageState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load saved locations',
                        message: 'Check your connection and try again.',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final locations = snapshot.data!;

                    if (locations.isEmpty) {
                      return const _MessageState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No saved locations yet',
                        message:
                            'Add Home, Work, Hospital, or another frequent destination.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: locations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final location = locations[index];

                        return _SavedLocationCard(
                          location: location,
                          onUse: () => _useLocation(location),
                          onEdit: () => _showLocationDialog(location: location),
                          onDelete: () => _confirmDelete(location),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedLocationCard extends StatelessWidget {
  const _SavedLocationCard({
    required this.location,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedLocation location;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
          leading: Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppTheme.teal.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: AppTheme.teal,
            ),
          ),
          title: Text(
            location.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(location.address),
          ),
          onTap: onUse,
          trailing: PopupMenuButton<String>(
            tooltip: 'Location actions',
            onSelected: (value) {
              if (value == 'use') onUse();
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'use',
                child: ListTile(
                  leading: Icon(Icons.search_rounded),
                  title: Text('Use for route'),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_rounded),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedLocationFormDialog extends StatefulWidget {
  const _SavedLocationFormDialog({
    required this.onSave,
    this.location,
  });

  final SavedLocation? location;
  final Future<void> Function(String name, String address) onSave;

  @override
  State<_SavedLocationFormDialog> createState() =>
      _SavedLocationFormDialogState();
}

class _SavedLocationFormDialogState extends State<_SavedLocationFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _addressController = TextEditingController(
      text: widget.location?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _chooseOnMap() async {
    final picked = await pickLocationOnMap(context);
    if (!mounted || picked == null) return;

    setState(() {
      _addressController.text = picked.address;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name and a place, or choose it on the map.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(name, address);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this location. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewLocation = widget.location == null;

    return AlertDialog(
      title: Text(isNewLocation ? 'Save location' : 'Edit location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location name',
                hintText: 'Example: Home, Work, or Hospital',
                prefixIcon: Icon(Icons.bookmark_add_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Place',
                hintText: 'Choose on the map or type a place',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _chooseOnMap,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Choose on map'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: AppTheme.navy,
                    strokeWidth: 2,
                  ),
                )
              : Text(isNewLocation ? 'Save' : 'Update'),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppTheme.aqua),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
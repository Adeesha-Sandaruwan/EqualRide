import 'package:flutter/material.dart';

import '../models/saved_location.dart';
import '../services/saved_location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

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

  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveLocation() async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();

              if (name.isEmpty || address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter both a name and a destination.'),
                  ),
                );
                return;
              }

              setDialogState(() => isSaving = true);

              try {
                await _locationService.addLocation(
                  userId: widget.userId,
                  name: name,
                  address: address,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save this location. Please try again.',
                      ),
                    ),
                  );
                }
              } finally {
                if (context.mounted) {
                  setDialogState(() => isSaving = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Save location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Location name',
                        hintText: 'Example: Home or Hospital',
                        prefixIcon: Icon(Icons.bookmark_add_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        hintText: 'Example: Colombo Fort Railway Station',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      onSubmitted: (_) => saveLocation(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : saveLocation,
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: AppTheme.navy,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    addressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLocationDialog,
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
                  'Save frequent destinations and quickly use them in route search.',
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
                          onUse: () {
                            widget.onUseLocation(location.address);
                            Navigator.pop(context);
                          },
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
  });

  final SavedLocation location;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
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
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: onUse,
      ),
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
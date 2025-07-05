import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/core/services/user_service.dart';

class AddPlantDialog extends StatefulWidget {
  final String imagePath;

  const AddPlantDialog({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends State<AddPlantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _speciesController = TextEditingController();
  final _familyController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _speciesController.dispose();
    _familyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = GetIt.instance<UserService>();
    
    return AlertDialog(
      title: const Text('Add New Plant'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show current user info
              if (userService.isAuthenticated)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        userService.isGuestUser ? Icons.person_outline : Icons.person,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userService.isGuestUser 
                              ? 'Logged in as Guest User'
                              : 'Logged in as ${userService.currentUserType?.toUpperCase()} user',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Plant Name (Required)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name *',
                  hintText: 'Enter the name of the plant',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Plant name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the plant (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Species (Optional)
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  hintText: 'Scientific species name (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Family (Optional)
              TextFormField(
                controller: _familyController,
                decoration: const InputDecoration(
                  labelText: 'Family',
                  hintText: 'Plant family (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Tags (Optional)
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'Comma-separated tags (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _addPlant(context);
            }
          },
          child: const Text('Add Plant'),
        ),
      ],
    );
  }

  void _addPlant(BuildContext context) {
    final mapCubit = context.read<MapCubit>();
    final userService = GetIt.instance<UserService>();

    // Parse tags
    List<String> tags = [];
    if (_tagsController.text.trim().isNotEmpty) {
      tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    // Add plant with all fields
    mapCubit.addPlant(
      name: _nameController.text.trim(),
      imagePath: widget.imagePath,
      userId: userService.currentUserId,
      description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      species: _speciesController.text.trim().isNotEmpty 
          ? _speciesController.text.trim() 
          : null,
      family: _familyController.text.trim().isNotEmpty 
          ? _familyController.text.trim() 
          : null,
      tags: tags,
    );

    // Close dialog without showing a SnackBar
    // User will see the plant added to the map automatically
    Navigator.of(context).pop();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../providers/gym_providers.dart';

class GymFormScreen extends ConsumerStatefulWidget {
  const GymFormScreen({super.key, this.gym});

  final Gym? gym;

  @override
  ConsumerState<GymFormScreen> createState() => _GymFormScreenState();
}

class _GymFormScreenState extends ConsumerState<GymFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  var _isSaving = false;

  bool get _isEditing => widget.gym != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gym?.name);
    _locationController = TextEditingController(text: widget.gym?.location);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      final repository = ref.read(gymRepositoryProvider);
      if (widget.gym case final gym?) {
        await repository.update(
          id: gym.id,
          name: _nameController.text,
          location: _locationController.text,
        );
      } else {
        await repository.create(
          name: _nameController.text,
          location: _locationController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar academia' : 'Nova academia'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                key: const Key('gymNameField'),
                controller: _nameController,
                autofocus: true,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex.: Academia Central',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da academia.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('gymLocationField'),
                controller: _locationController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Localização (opcional)',
                  hintText: 'Ex.: Centro',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('saveGymButton'),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Salvar alterações' : 'Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

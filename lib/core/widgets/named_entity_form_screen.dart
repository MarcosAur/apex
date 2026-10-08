import 'package:flutter/material.dart';

class NamedEntityFormScreen extends StatefulWidget {
  const NamedEntityFormScreen({
    required this.title,
    required this.entityName,
    required this.fieldKey,
    required this.saveButtonKey,
    required this.onSave,
    super.key,
    this.initialName,
  });

  final String title;
  final String entityName;
  final String fieldKey;
  final String saveButtonKey;
  final String? initialName;
  final Future<void> Function(String name) onSave;

  @override
  State<NamedEntityFormScreen> createState() => _NamedEntityFormScreenState();
}

class _NamedEntityFormScreenState extends State<NamedEntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_controller.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final duplicate = error.toString().contains('UNIQUE constraint failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate
                ? 'Já existe ${widget.entityName} com esse nome.'
                : 'Não foi possível salvar: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                key: Key(widget.fieldKey),
                controller: _controller,
                autofocus: true,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um nome.'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: Key(widget.saveButtonKey),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

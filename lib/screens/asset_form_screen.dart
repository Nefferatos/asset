import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';

class AssetFormScreen extends StatefulWidget {
  final Asset? asset;

  const AssetFormScreen({super.key, this.asset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assetNumberCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _service = AssetService();
  final List<String> _validateOptions = const ['Not Found', 'Found', 'Defective'];
  String _validateValue = 'Not Found';

  bool get _isEdit => widget.asset != null;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    if (a != null) {
      _assetNumberCtrl.text = a.assetNumber;
      _descriptionCtrl.text = a.description;
      _locationCtrl.text = a.location;
      _remarksCtrl.text = a.remarks;
      _validateValue = a.validate;
    }
  }

  @override
  void dispose() {
    _assetNumberCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final asset = Asset(
        id: widget.asset?.id,
        assetNumber: _assetNumberCtrl.text,
        description: _descriptionCtrl.text,
        location: _locationCtrl.text,
        remarks: _remarksCtrl.text,
        validate: _validateValue,
        createdAt: widget.asset?.createdAt,
        updatedAt: widget.asset?.updatedAt,
      );

      if (_isEdit) {
        await _service.updateAsset(asset);
      } else {
        await _service.addAsset(asset);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Asset' : 'Add Asset')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _assetNumberCtrl,
              decoration: const InputDecoration(labelText: 'Asset Number'),
              validator: _required,
            ),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: _required,
            ),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: _required,
            ),
            TextFormField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(labelText: 'Remarks'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _validateOptions.contains(_validateValue)
                  ? _validateValue
                  : 'Not Found',
              items: _validateOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _validateValue = value);
              },
              decoration: const InputDecoration(labelText: 'Validate'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

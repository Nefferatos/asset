import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/asset_service.dart';
import 'login_screen.dart';

class SearchValidateScreen extends StatefulWidget {
  const SearchValidateScreen({super.key});

  @override
  State<SearchValidateScreen> createState() => _SearchValidateScreenState();
}

class _SearchValidateScreenState extends State<SearchValidateScreen> {
  final service = AssetService();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  bool found = false;
  String? inputError;
  String statusMessage = 'Item does not exist';
  String lastSearched = '';
  Asset? validatedAsset;
  List<Asset> allAssets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    allAssets = await service.getAssets();
    if (!mounted) return;
    setState(() {});
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> validate() async {
    final number = _searchCtrl.text.trim();
    if (number.isEmpty) {
      setState(() {
        inputError = 'Asset Number cannot be empty';
        found = false;
        statusMessage = 'Item does not exist';
        lastSearched = '';
        validatedAsset = null;
      });
      return;
    }

    setState(() => inputError = null);

    final res = await service.validateAsset(number);
    if (!mounted) return;
    setState(() {
      lastSearched = number;
      found = res != null;
      statusMessage = found ? 'Item exists' : 'Item does not exist';
      validatedAsset = res;
    });
    await _loadAssets();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validate Asset'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RawAutocomplete<Asset>(
              textEditingController: _searchCtrl,
              focusNode: _searchFocus,
              displayStringForOption: (a) => a.assetNumber,
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.trim().toLowerCase();
                if (query.isEmpty) return allAssets.take(5);
                return allAssets
                    .where(
                      (a) => a.assetNumber.toLowerCase().contains(query),
                    )
                    .take(8);
              },
              onSelected: (asset) {
                _searchCtrl.text = asset.assetNumber;
              },
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => validate(),
                  decoration: InputDecoration(
                    hintText: 'Search Asset Number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: validate,
                      icon: const Icon(Icons.search),
                    ),
                    errorText: inputError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final list = options.toList(growable: false);
                if (list.isEmpty) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 220,
                        minWidth: 320,
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final asset = list[index];
                          return ListTile(
                            dense: true,
                            title: Text(asset.assetNumber),
                            subtitle: Text(
                              '${asset.description} - ${asset.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => onSelected(asset),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              found ? 'FOUND' : 'NOT FOUND',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: found ? Colors.green : Colors.red,
              ),
            ),
            if (lastSearched.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Searched: $lastSearched',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: found ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            if (validatedAsset != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        validatedAsset!.assetNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Description: ${validatedAsset!.description}'),
                      Text('Location: ${validatedAsset!.location}'),
                      Text('Remarks: ${validatedAsset!.remarks}'),
                      Text('Validate: ${validatedAsset!.validate}'),
                      Text(
                        'Updated: ${_formatDateTime(validatedAsset!.updatedAt)}',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

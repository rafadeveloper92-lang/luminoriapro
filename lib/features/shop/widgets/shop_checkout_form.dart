import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/shop_product.dart';

class ShopCheckoutForm extends StatefulWidget {
  const ShopCheckoutForm({
    super.key,
    required this.product,
    required this.quantity,
    required this.userCoins,
    required this.onSubmit,
    required this.onCancel,
  });

  final ShopProduct product;
  final int quantity;
  final int userCoins;
  final Future<void> Function({
    required String deliveryName,
    required String deliveryAddress,
    required String deliveryPhone,
    required String deliveryPostalCode,
  }) onSubmit;
  final VoidCallback onCancel;

  @override
  State<ShopCheckoutForm> createState() => _ShopCheckoutFormState();
}

class _ShopCheckoutFormState extends State<ShopCheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  int get _totalCoins => widget.product.priceCoins * widget.quantity;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimaryColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dados de entrega',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.product.name} × ${widget.quantity} = $_totalCoins Luminárias',
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                hintText: 'Nome e sobrenome',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Endereço completo',
                hintText: 'Rua, número, bairro, cidade',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: 'Com DDD',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Código postal',
                hintText: 'CEP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: AppTheme.errorColor, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() {
                              _isSubmitting = true;
                              _error = null;
                            });
                            try {
                              await widget.onSubmit(
                                deliveryName: _nameController.text.trim(),
                                deliveryAddress: _addressController.text.trim(),
                                deliveryPhone: _phoneController.text.trim(),
                                deliveryPostalCode: _postalCodeController.text.trim(),
                              );
                              if (context.mounted) Navigator.of(context).pop(true);
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                  _error = e.toString().replaceFirst('Exception: ', '');
                                });
                              }
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Confirmar compra ($_totalCoins Luminárias)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

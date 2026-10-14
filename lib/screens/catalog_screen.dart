import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/product.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProductDialog([Product? existingProduct]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.read<POSProvider>();
    final isEditing = existingProduct != null;

    final nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
    final emojiCtrl = TextEditingController(text: existingProduct?.emoji ?? '🍎');
    final categoryCtrl = TextEditingController(text: existingProduct?.category ?? 'Gastronomía');
    final normalPriceCtrl = TextEditingController(
      text: existingProduct?.normalPrice.toStringAsFixed(0) ?? '',
    );
    final wholesalePriceCtrl = TextEditingController(
      text: existingProduct?.wholesalePrice?.toStringAsFixed(0) ?? '',
    );
    final discountPriceCtrl = TextEditingController(
      text: existingProduct?.discountPrice?.toStringAsFixed(0) ?? '',
    );
    UnitType unit = existingProduct?.unit ?? UnitType.u;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: emojiCtrl,
                            style: const TextStyle(fontSize: 26),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'Emoji',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del Producto *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: categoryCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<UnitType>(
                          value: unit,
                          items: const [
                            DropdownMenuItem(value: UnitType.u, child: Text('Unidad (u)')),
                            DropdownMenuItem(value: UnitType.lb, child: Text('Libra (lb)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => unit = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: normalPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio Normal (CUP) *',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: wholesalePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio Mayorista (Opcional)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio Oferta (Opcional)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              FilledButton(
                child: Text(isEditing ? 'Guardar Cambios' : 'Crear Producto'),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final normalPrice = double.tryParse(normalPriceCtrl.text) ?? 0.0;
                  if (name.isEmpty || normalPrice <= 0) return;

                  final wholesale = double.tryParse(wholesalePriceCtrl.text);
                  final discount = double.tryParse(discountPriceCtrl.text);

                  final prices = <PriceTier, double?>{
                    PriceTier.normal: normalPrice,
                    if (wholesale != null) PriceTier.mayorista: wholesale,
                    if (discount != null) PriceTier.oferta: discount,
                  };

                  if (isEditing) {
                    pos.updateProduct(existingProduct.copyWith(
                      name: name,
                      emoji: emojiCtrl.text.trim().isEmpty ? '📦' : emojiCtrl.text.trim(),
                      category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                      unit: unit,
                      prices: prices,
                    ));
                  } else {
                    pos.addProduct(Product(
                      id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      emoji: emojiCtrl.text.trim().isEmpty ? '📦' : emojiCtrl.text.trim(),
                      category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                      unit: unit,
                      prices: prices,
                      createdTime: DateTime.now().millisecondsSinceEpoch,
                    ));
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();

    final filtered = pos.products.where((p) {
      final matchesCat = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
        onPressed: () => _showProductDialog(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: pos.categories.length,
              itemBuilder: (context, idx) {
                final cat = pos.categories[idx];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      pos.products.isEmpty
                          ? 'Aún no hay productos en el catálogo.\nToca "+" para añadir el primero.'
                          : 'No se encontraron productos con ese filtro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final prod = filtered[index];
                      return Card.outlined(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            child: Text(prod.emoji, style: const TextStyle(fontSize: 22)),
                          ),
                          title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${prod.category} • ${prod.unit == UnitType.lb ? 'Por Libra (lb)' : 'Por Unidad (u)'}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${prod.normalPrice.toStringAsFixed(0)} CUP',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (prod.wholesalePrice != null)
                                    Text(
                                      'May: \$${prod.wholesalePrice!.toStringAsFixed(0)}',
                                      style: TextStyle(color: colorScheme.secondary, fontSize: 11),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showProductDialog(prod),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('¿Eliminar producto?'),
                                      content: Text('Se eliminará "${prod.name}" del catálogo.'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar'),
                                          onPressed: () => Navigator.of(ctx).pop(),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                          child: const Text('Eliminar'),
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            pos.deleteProduct(prod.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

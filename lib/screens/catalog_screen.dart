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
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEditing ? 'Editar Producto' : 'Nuevo Producto',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: emojiCtrl,
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(labelText: 'Emoji'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Nombre del Producto'),
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
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Categoría'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<UnitType>(
                          value: unit,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
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
                      style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Precio Normal (CUP) *',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: wholesalePriceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Precio Mayorista (Opcional)',
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: discountPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Precio Oferta (Opcional)',
                        prefixText: '\$ ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                child: Text(isEditing ? 'Guardar Cambios' : 'Crear Producto', style: const TextStyle(color: Colors.white)),
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
    final pos = context.watch<POSProvider>();

    final filtered = pos.products.where((p) {
      final matchesCat = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Catálogo de Productos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF34D399), size: 28),
            tooltip: 'Nuevo Producto',
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o categoría...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pos.categories.length,
                    itemBuilder: (context, idx) {
                      final cat = pos.categories[idx];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: const Color(0xFF0F172A),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      pos.products.isEmpty
                          ? 'Aún no hay productos en el catálogo.\nToca "+" para añadir el primero.'
                          : 'No se encontraron productos con ese filtro.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final prod = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: ListTile(
                          leading: Text(prod.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(
                            prod.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${prod.category} • ${prod.unit == UnitType.lb ? 'Por Libra (lb)' : 'Por Unidad (u)'}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
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
                                    style: const TextStyle(
                                      color: Color(0xFF34D399),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (prod.wholesalePrice != null)
                                    Text(
                                      'May: \$${prod.wholesalePrice!.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                                onPressed: () => _showProductDialog(prod),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171), size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E293B),
                                      title: const Text('¿Eliminar producto?', style: TextStyle(color: Colors.white)),
                                      content: Text('Se eliminará ${prod.name} del catálogo.', style: const TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                                          onPressed: () => Navigator.of(ctx).pop(),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
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

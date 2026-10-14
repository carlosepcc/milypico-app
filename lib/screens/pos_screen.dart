import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/product.dart';
import '../widgets/keypad_widget.dart';
import '../widgets/checkout_dialog.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double _keypadHeight = 290;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = context.watch<POSProvider>();
    final activeCarts = pos.activeCarts;
    final currentCart = pos.currentCart;
    final currentSession = pos.currentSession;

    final filteredProducts = pos.products.where((p) {
      final matchesCat = pos.selectedCategory == 'Todos' || p.category == pos.selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final cartTotal = currentCart?.calculateTotal(pos.productLookup) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caja POS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              currentSession != null ? 'Sesión: ${currentSession.name}' : 'Sin sesión abierta',
              style: TextStyle(
                fontSize: 12,
                color: currentSession != null ? colorScheme.primary : colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (currentCart != null && currentCart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: Text('\$${cartTotal.toStringAsFixed(0)}'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => CheckoutDialog(cart: currentCart),
                  );
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Carts Strip (Material 3 Horizontal Chips with Badges)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: colorScheme.surfaceContainerLowest,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeCarts.length,
                      itemBuilder: (context, idx) {
                        final cart = activeCarts[idx];
                        final isSelected = idx == pos.activeCartIndex;
                        final itemCount = cart.items.fold(0.0, (sum, i) => sum + i.quantity);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Badge(
                            isLabelVisible: itemCount > 0,
                            label: Text(
                              itemCount % 1 == 0 ? itemCount.toInt().toString() : itemCount.toStringAsFixed(1),
                            ),
                            backgroundColor: colorScheme.primary,
                            textColor: colorScheme.onPrimary,
                            child: FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              avatar: Icon(
                                Icons.shopping_cart_outlined,
                                size: 16,
                                color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                              ),
                              label: Text('Cliente #${cart.number}'),
                              onSelected: (_) => pos.setActiveCartIndex(idx),
                              onDeleted: activeCarts.length > 1 && isSelected
                                  ? () => pos.deleteCart(cart.id)
                                  : null,
                              deleteIcon: const Icon(Icons.close, size: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Nuevo Carrito',
                    onPressed: () => pos.createCart(),
                  ),
                ],
              ),
            ),

            // Search Bar & Category Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos por nombre o categoría...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            // Categories Filter Chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: pos.categories.length,
                itemBuilder: (context, idx) {
                  final cat = pos.categories[idx];
                  final isSelected = cat == pos.selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) => pos.setSelectedCategory(cat),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Products Grid View
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        pos.products.isEmpty
                            ? 'El catálogo está vacío'
                            : 'No hay productos que coincidan',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = (constraints.maxWidth / 160).clamp(2, 6).toInt();
                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final prod = filteredProducts[index];
                            final isSelected = prod.id == pos.selectedProductId;

                            final item = currentCart?.items.firstWhere(
                              (i) => i.productId == prod.id,
                              orElse: () => CartItem(id: '', productId: '', quantity: 0),
                            );
                            final double cartQty = item?.quantity ?? 0.0;
                            final bool isLocked = item?.isLocked ?? false;

                            return Card(
                              elevation: isSelected ? 3 : 0,
                              color: isSelected
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (isSelected && currentCart != null) {
                                    pos.addItemToCart(currentCart.id, prod.id);
                                  } else {
                                    pos.setSelectedProductId(prod.id);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(prod.emoji, style: const TextStyle(fontSize: 26)),
                                          if (cartQty > 0)
                                            Badge(
                                              label: Text(
                                                '${cartQty % 1 == 0 ? cartQty.toInt() : cartQty.toStringAsFixed(1)} ${prod.unit == UnitType.lb ? 'lb' : 'u'}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              backgroundColor: isLocked ? colorScheme.error : colorScheme.primary,
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prod.name,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '\$${prod.normalPrice.toStringAsFixed(0)} CUP',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Material 3 Tactile Keypad
            KeypadWidget(
              height: _keypadHeight,
              onHeightChanged: (newH) => setState(() => _keypadHeight = newH),
            ),
          ],
        ),
      ),
    );
  }
}

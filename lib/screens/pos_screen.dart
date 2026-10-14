import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';
import '../models/product.dart';
import '../widgets/keypad_widget.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double _keypadHeight = 280;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _getCartColor(String colorName) {
    switch (colorName) {
      case 'emerald':
        return const Color(0xFF10B981);
      case 'amber':
        return const Color(0xFFF59E0B);
      case 'rose':
        return const Color(0xFFF43F5E);
      case 'purple':
        return const Color(0xFFA855F7);
      case 'indigo':
        return const Color(0xFF6366F1);
      case 'sky':
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<POSProvider>();
    final activeCarts = pos.activeCarts;
    final currentCart = pos.currentCart;

    // Filter products
    final filteredProducts = pos.products.where((p) {
      final matchesCat = pos.selectedCategory == 'Todos' || p.category == pos.selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Carts Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeCarts.length,
                      itemBuilder: (context, idx) {
                        final cart = activeCarts[idx];
                        final isCurrent = idx == pos.activeCartIndex;
                        final color = _getCartColor(cart.color);
                        final itemCount = cart.items.fold(0.0, (sum, i) => sum + i.quantity);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => pos.setActiveCartIndex(idx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrent ? color.withValues(alpha: 0.25) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCurrent ? color : Colors.white24,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${cart.number}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (itemCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        itemCount % 1 == 0 ? itemCount.toInt().toString() : itemCount.toStringAsFixed(1),
                                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  if (isCurrent && activeCarts.length > 1) ...[
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => pos.deleteCart(cart.id),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white60),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF34D399), size: 20),
                    tooltip: 'Nuevo Carrito',
                    onPressed: () => pos.createCart(),
                  ),
                ],
              ),
            ),

            // Search & Categories Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: pos.categories.length,
                        itemBuilder: (context, idx) {
                          final cat = pos.categories[idx];
                          final isSelected = cat == pos.selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF10B981),
                              backgroundColor: const Color(0xFF0F172A),
                              onSelected: (_) => pos.setSelectedCategory(cat),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products Grid View
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        pos.products.isEmpty ? 'El catálogo está vacío' : 'No hay productos que coincidan',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = (constraints.maxWidth / 160).clamp(2, 6).toInt();
                        return GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final prod = filteredProducts[index];
                            final isSelected = prod.id == pos.selectedProductId;

                            // Quantity in current cart
                            final item = currentCart?.items.firstWhere(
                              (i) => i.productId == prod.id,
                              orElse: () => CartItem(id: '', productId: '', quantity: 0),
                            );
                            final double cartQty = item?.quantity ?? 0.0;
                            final bool isLocked = item?.isLocked ?? false;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (isSelected) {
                                  // Quick add if already selected
                                  if (currentCart != null) {
                                    pos.addItemToCart(currentCart.id, prod.id);
                                  }
                                } else {
                                  pos.setSelectedProductId(prod.id);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.08),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(prod.emoji, style: const TextStyle(fontSize: 26)),
                                            const Spacer(),
                                            if (cartQty > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isLocked ? Colors.amber : const Color(0xFF10B981),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '${cartQty % 1 == 0 ? cartQty.toInt() : cartQty.toStringAsFixed(1)} ${prod.unit == UnitType.lb ? 'lb' : 'u'}',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\$${prod.normalPrice.toStringAsFixed(0)} CUP',
                                              style: const TextStyle(
                                                color: Color(0xFF34D399),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (isLocked)
                                      const Positioned(
                                        top: 28,
                                        right: 0,
                                        child: Icon(Icons.lock, size: 14, color: Colors.amber),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Resizable Keypad
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

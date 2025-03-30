import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/products/bloc/product_bloc.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/products/widgets/barcode_scanner_button.dart';

class AddProductToOrder extends StatefulWidget {
  final Function(OrderItem) onProductAdded;

  const AddProductToOrder({
    Key? key,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  _AddProductToOrderState createState() => _AddProductToOrderState();
}

class _AddProductToOrderState extends State<AddProductToOrder> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  List<Product> _products = [];
  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    context.read<ProductBloc>().add(LoadProducts());
  }

  void _loadCategories() {
    context.read<ProductBloc>().add(LoadCategories());
  }

  void _searchProducts(String query) {
    if (query.isEmpty) {
      _loadProducts();
    } else {
      context.read<ProductBloc>().add(SearchProducts(query));
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    
    if (category == null) {
      _loadProducts();
    } else if (category == 'Low Stock') {
      context.read<ProductBloc>().add(LoadLowStockProducts());
    } else {
      context.read<ProductBloc>().add(LoadProductsByCategory(category));
    }
  }

  void _onBarcodeScanned(String barcode) {
    context.read<ProductBloc>().add(LoadProductByBarcode(barcode));
  }

  void _addProductToOrder(Product product) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }
    
    if (quantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough stock. Available: ${product.quantity}'),
        ),
      );
      return;
    }
    
    final orderItem = OrderItem(
      orderId: 0, // This will be set when the order is created
      productId: product.id!,
      quantity: quantity,
      pricePerUnit: product.price,
      subtotal: product.price * quantity,
      productName: product.name,
      productDescription: product.description,
      productCategory: product.category,
    );
    
    widget.onProductAdded(orderItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField.search(
                      controller: _searchController,
                      hint: 'Search products...',
                      onChanged: _searchProducts,
                      onClear: () {
                        _searchController.clear();
                        _loadProducts();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  BarcodeScannerButton(
                    onBarcodeScanned: _onBarcodeScanned,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              Expanded(
                child: BlocConsumer<ProductBloc, ProductState>(
                  listener: (context, state) {
                    if (state is ProductLoaded) {
                      // Product found by barcode, add it to the order
                      _showAddQuantityDialog(state.product);
                    } else if (state is CategoriesLoaded) {
                      setState(() {
                        _categories = state.categories;
                      });
                    } else if (state is ProductsLoaded) {
                      setState(() {
                        _products = state.products;
                      });
                    } else if (state is ProductError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ProductsLoading) {
                      return const LoadingWidget();
                    } else if (state is ProductsLoaded) {
                      return _buildProductList(state.products);
                    } else {
                      return const LoadingWidget();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is CategoriesLoaded) {
            _categories = state.categories;
          }
          
          final chips = [
            _buildCategoryChip(null, 'All'),
            ..._categories.map((category) => _buildCategoryChip(category, category)).toList(),
          ];
          
          return ListView(
            scrollDirection: Axis.horizontal,
            children: chips,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          _filterByCategory(category);
        },
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No products found'),
      );
    }
    
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => _buildProductListItem(products[index]),
    );
  }

  Widget _buildProductListItem(Product product) {
    final isLowStock = product.quantity <= product.minStockLevel;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: const Icon(Icons.inventory),
      ),
      title: Text(product.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.category),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Stock: ${product.quantity}',
                  style: TextStyle(
                    color: isLowStock ? Colors.red[700] : Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.add_circle_outline),
      enabled: product.quantity > 0,
      onTap: product.quantity > 0
          ? () => _showAddQuantityDialog(product)
          : null,
    );
  }

  void _showAddQuantityDialog(Product product) {
    _quantityController.text = '1';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available stock: ${product.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addProductToOrder(product);
            },
            child: const Text('Add to Order'),
          ),
        ],
      ),
    );
  }
}

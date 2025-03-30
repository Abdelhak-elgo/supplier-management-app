import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/features/products/bloc/product_bloc.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/products/widgets/product_card.dart';
import 'package:supplier_management/features/products/widgets/barcode_scanner_button.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
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
    super.dispose();
  }
  
  void _loadProducts() {
    context.read<ProductBloc>().add(LoadProducts());
  }
  
  void _loadCategories() {
    context.read<ProductBloc>().add(LoadCategories());
  }
  
  void _onSearchChanged(String query) {
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
  
  void _onProductScanned(String barcode) {
    if (barcode.isNotEmpty) {
      context.read<ProductBloc>().add(LoadProductByBarcode(barcode));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          BarcodeScannerButton(
            onBarcodeScanned: _onProductScanned,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryChips(),
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductLoaded) {
                  // Navigate to product detail when scanned
                  Navigator.pushNamed(
                    context, 
                    '/products/detail',
                    arguments: state.product.id,
                  );
                } else if (state is ProductError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is CategoriesLoaded) {
                  setState(() {
                    _categories = state.categories;
                  });
                }
              },
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const LoadingWidget();
                } else if (state is ProductsLoaded) {
                  return _buildProductList(state.products);
                } else if (state is ProductError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadProducts,
                  );
                }
                
                return const LoadingWidget();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/products/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomTextField.search(
        controller: _searchController,
        hint: 'Search products by name, description, or barcode...',
        onChanged: _onSearchChanged,
        onClear: () {
          _searchController.clear();
          _loadProducts();
        },
      ),
    );
  }
  
  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 40,
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is CategoriesLoaded) {
              _categories = state.categories;
            }
            
            final chips = [
              _buildCategoryChip(null, 'All'),
              _buildCategoryChip('Low Stock', 'Low Stock'),
              ..._categories.map((category) => _buildCategoryChip(category, category)).toList(),
            ];
            
            return ListView(
              scrollDirection: Axis.horizontal,
              children: chips,
            );
          },
        ),
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
      return EmptyStateWidget(
        message: 'No products found',
        subMessage: _searchController.text.isNotEmpty
            ? 'Try a different search term'
            : _selectedCategory != null
                ? 'No products in this category'
                : 'Add your first product',
        icon: Icons.inventory_2_outlined,
        onAction: () {
          Navigator.pushNamed(context, '/products/add');
        },
        actionLabel: 'Add Product',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadProducts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(
            product: products[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/products/detail',
                arguments: products[index].id,
              );
            },
          );
        },
      ),
    );
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('All'),
                    onPressed: () {
                      Navigator.pop(context);
                      _filterByCategory(null);
                    },
                  ),
                  ActionChip(
                    label: const Text('Low Stock'),
                    backgroundColor: Colors.red[100],
                    onPressed: () {
                      Navigator.pop(context);
                      _filterByCategory('Low Stock');
                    },
                  ),
                  ..._categories.map((category) {
                    return ActionChip(
                      label: Text(category),
                      onPressed: () {
                        Navigator.pop(context);
                        _filterByCategory(category);
                      },
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

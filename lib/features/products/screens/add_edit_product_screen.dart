import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/utils/validators.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/features/products/bloc/product_bloc.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AddEditProductScreen extends StatefulWidget {
  final bool isEditing;

  const AddEditProductScreen({
    Key? key,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockLevelController = TextEditingController();
  final _barcodeController = TextEditingController();

  bool _isLoading = false;
  Product? _product;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.isEditing) {
      // Wait for product to be populated from arguments
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_product != null) {
          _populateFields();
        }
      });
    } else {
      // Set default values for new product
      _minStockLevelController.text = '5';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isEditing && _product == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Product) {
        _product = args;
        _populateFields();
      }
    }
  }

  void _loadCategories() {
    context.read<ProductBloc>().add(LoadCategories());
  }

  void _populateFields() {
    final product = _product;
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _categoryController.text = product.category;
      _priceController.text = product.price.toString();
      _quantityController.text = product.quantity.toString();
      _minStockLevelController.text = product.minStockLevel.toString();
      _barcodeController.text = product.barcode ?? '';
    }
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        setState(() {
          _barcodeController.text = barcodeScanRes;
        });
      }
    } on PlatformException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to scan barcode')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final product = Product(
        id: widget.isEditing ? _product?.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        minStockLevel: int.parse(_minStockLevelController.text),
        barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text.trim(),
        createdAt: widget.isEditing ? _product!.createdAt : DateTime.now(),
        updatedAt: widget.isEditing ? DateTime.now() : null,
      );

      if (widget.isEditing) {
        context.read<ProductBloc>().add(UpdateProduct(product));
      } else {
        context.read<ProductBloc>().add(AddProduct(product));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minStockLevelController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            
            Navigator.pop(context);
          } else if (state is ProductError) {
            setState(() {
              _isLoading = false;
            });
            
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
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => Validators.validateRequired(value, 'Product name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField.multiline(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter product description',
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryField(),
                      const SizedBox(height: 16),
                      CustomTextField.price(
                        controller: _priceController,
                        validator: Validators.validatePrice,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField.quantity(
                        controller: _quantityController,
                        validator: Validators.validateQuantity,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField.number(
                        controller: _minStockLevelController,
                        label: 'Minimum Stock Level',
                        hint: 'Enter minimum stock level',
                        validator: Validators.validateMinStockLevel,
                        allowDecimal: false,
                      ),
                      const SizedBox(height: 16),
                      _buildBarcodeField(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.isEditing ? 'Update Product' : 'Add Product',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _categories.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _categoryController.text = selection;
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController controller,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        if (_categoryController.text.isNotEmpty && controller.text.isEmpty) {
          controller.text = _categoryController.text;
        }
        
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Category *',
            hintText: 'Enter product category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                _categoryController.clear();
              },
            ),
          ),
          validator: (value) => Validators.validateRequired(value, 'Category'),
          onChanged: (value) {
            _categoryController.text = value;
          },
          textCapitalization: TextCapitalization.words,
        );
      },
    );
  }

  Widget _buildBarcodeField() {
    return TextFormField(
      controller: _barcodeController,
      decoration: InputDecoration(
        labelText: 'Barcode',
        hintText: 'Scan or enter barcode',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _scanBarcode,
        ),
      ),
    );
  }
}

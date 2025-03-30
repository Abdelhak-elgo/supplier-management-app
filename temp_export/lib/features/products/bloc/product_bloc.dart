import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/products/repository/product_repository.dart';

// Events
abstract class ProductEvent {}

class LoadProducts extends ProductEvent {}

class LoadProductsByCategory extends ProductEvent {
  final String category;

  LoadProductsByCategory(this.category);
}

class SearchProducts extends ProductEvent {
  final String query;

  SearchProducts(this.query);
}

class LoadProductById extends ProductEvent {
  final int id;

  LoadProductById(this.id);
}

class AddProduct extends ProductEvent {
  final Product product;

  AddProduct(this.product);
}

class UpdateProduct extends ProductEvent {
  final Product product;

  UpdateProduct(this.product);
}

class DeleteProduct extends ProductEvent {
  final int id;

  DeleteProduct(this.id);
}

class LoadLowStockProducts extends ProductEvent {}

class ScanBarcode extends ProductEvent {}

class LoadProductByBarcode extends ProductEvent {
  final String barcode;

  LoadProductByBarcode(this.barcode);
}

class LoadCategories extends ProductEvent {}

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductsLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final String? filterCategory;

  ProductsLoaded(this.products, {this.filterCategory});
}

class ProductLoaded extends ProductState {
  final Product product;

  ProductLoaded(this.product);
}

class ProductOperationSuccess extends ProductState {
  final String message;

  ProductOperationSuccess(this.message);
}

class CategoriesLoaded extends ProductState {
  final List<String> categories;

  CategoriesLoaded(this.categories);
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductBloc(this._productRepository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<SearchProducts>(_onSearchProducts);
    on<LoadProductById>(_onLoadProductById);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<LoadLowStockProducts>(_onLoadLowStockProducts);
    on<LoadProductByBarcode>(_onLoadProductByBarcode);
    on<LoadCategories>(_onLoadCategories);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _productRepository.getAllProducts();
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductError('Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _productRepository.getProductsByCategory(event.category);
      emit(ProductsLoaded(products, filterCategory: event.category));
    } catch (e) {
      emit(ProductError('Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _productRepository.searchProducts(event.query);
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductError('Failed to search products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProductById(
    LoadProductById event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final product = await _productRepository.getProductById(event.id);
      if (product != null) {
        emit(ProductLoaded(product));
      } else {
        emit(ProductError('Product not found'));
      }
    } catch (e) {
      emit(ProductError('Failed to load product: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      // Check if barcode exists (if provided)
      if (event.product.barcode != null && event.product.barcode!.isNotEmpty) {
        final barcodeExists = await _productRepository.checkIfBarcodeExists(event.product.barcode!);
        if (barcodeExists) {
          emit(ProductError('A product with this barcode already exists'));
          return;
        }
      }
      
      await _productRepository.insertProduct(event.product);
      emit(ProductOperationSuccess('Product added successfully'));
      
      // Reload products after add
      add(LoadProducts());
    } catch (e) {
      emit(ProductError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      // Check if barcode exists (if provided) excluding current product
      if (event.product.barcode != null && event.product.barcode!.isNotEmpty) {
        final barcodeExists = await _productRepository.checkIfBarcodeExists(
          event.product.barcode!,
          excludeProductId: event.product.id,
        );
        if (barcodeExists) {
          emit(ProductError('A product with this barcode already exists'));
          return;
        }
      }
      
      await _productRepository.updateProduct(event.product);
      emit(ProductOperationSuccess('Product updated successfully'));
      
      // Reload the product after update
      if (event.product.id != null) {
        add(LoadProductById(event.product.id!));
      }
    } catch (e) {
      emit(ProductError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      await _productRepository.deleteProduct(event.id);
      emit(ProductOperationSuccess('Product deleted successfully'));
      
      // Reload products after delete
      add(LoadProducts());
    } catch (e) {
      emit(ProductError('Failed to delete product: ${e.toString()}'));
    }
  }

  Future<void> _onLoadLowStockProducts(
    LoadLowStockProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final products = await _productRepository.getLowStockProducts();
      emit(ProductsLoaded(products, filterCategory: 'Low Stock'));
    } catch (e) {
      emit(ProductError('Failed to load low stock products: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProductByBarcode(
    LoadProductByBarcode event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final product = await _productRepository.getProductByBarcode(event.barcode);
      if (product != null) {
        emit(ProductLoaded(product));
      } else {
        emit(ProductError('No product found with this barcode'));
      }
    } catch (e) {
      emit(ProductError('Failed to load product by barcode: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<ProductState> emit,
  ) async {
    try {
      final categories = await _productRepository.getAllCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(ProductError('Failed to load categories: ${e.toString()}'));
    }
  }
}

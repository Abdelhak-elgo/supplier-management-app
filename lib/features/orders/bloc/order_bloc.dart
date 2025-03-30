import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/clients/repository/client_repository.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/orders/repository/order_repository.dart';
import 'package:supplier_management/features/products/models/product.dart';
import 'package:supplier_management/features/products/repository/product_repository.dart';

// Events
abstract class OrderEvent {}

class LoadOrders extends OrderEvent {}

class LoadOrdersByStatus extends OrderEvent {
  final String status;

  LoadOrdersByStatus(this.status);
}

class LoadOrdersByClientId extends OrderEvent {
  final int clientId;

  LoadOrdersByClientId(this.clientId);
}

class LoadOrderById extends OrderEvent {
  final int id;

  LoadOrderById(this.id);
}

class CreateOrder extends OrderEvent {
  final Order order;
  final List<OrderItem> items;

  CreateOrder(this.order, this.items);
}

class UpdateOrder extends OrderEvent {
  final Order order;
  final List<OrderItem> items;

  UpdateOrder(this.order, this.items);
}

class UpdateOrderStatus extends OrderEvent {
  final int id;
  final String status;

  UpdateOrderStatus(this.id, this.status);
}

class DeleteOrder extends OrderEvent {
  final int id;

  DeleteOrder(this.id);
}

class CheckProductAvailability extends OrderEvent {
  final int productId;
  final int quantity;

  CheckProductAvailability(this.productId, this.quantity);
}

// States
abstract class OrderState {}

class OrderInitial extends OrderState {}

class OrdersLoading extends OrderState {}

class OrdersLoaded extends OrderState {
  final List<Order> orders;
  final String? filterStatus;

  OrdersLoaded(this.orders, {this.filterStatus});
}

class OrderDetails extends OrderState {
  final Order order;
  final List<OrderItem> items;
  final Client? client;

  OrderDetails(this.order, this.items, this.client);
}

class OrderOperationSuccess extends OrderState {
  final String message;
  final int? orderId;

  OrderOperationSuccess(this.message, {this.orderId});
}

class ProductAvailability extends OrderState {
  final Product product;
  final bool isAvailable;
  final int requestedQuantity;

  ProductAvailability(this.product, this.isAvailable, this.requestedQuantity);
}

class OrderError extends OrderState {
  final String message;

  OrderError(this.message);
}

// BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  final ClientRepository _clientRepository;

  OrderBloc(
    this._orderRepository,
    this._productRepository,
    this._clientRepository,
  ) : super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadOrdersByStatus>(_onLoadOrdersByStatus);
    on<LoadOrdersByClientId>(_onLoadOrdersByClientId);
    on<LoadOrderById>(_onLoadOrderById);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<DeleteOrder>(_onDeleteOrder);
    on<CheckProductAvailability>(_onCheckProductAvailability);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await _orderRepository.getAllOrders();
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrdersByStatus(
    LoadOrdersByStatus event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await _orderRepository.getOrdersByStatus(event.status);
      emit(OrdersLoaded(orders, filterStatus: event.status));
    } catch (e) {
      emit(OrderError('Failed to load orders: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrdersByClientId(
    LoadOrdersByClientId event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final orders = await _orderRepository.getOrdersByClientId(event.clientId);
      emit(OrdersLoaded(orders));
    } catch (e) {
      emit(OrderError('Failed to load client orders: ${e.toString()}'));
    }
  }

  Future<void> _onLoadOrderById(
    LoadOrderById event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      final order = await _orderRepository.getOrderById(event.id);
      if (order != null) {
        final items = await _orderRepository.getOrderItems(event.id);
        final client = await _clientRepository.getClientById(order.clientId);
        emit(OrderDetails(order, items, client));
      } else {
        emit(OrderError('Order not found'));
      }
    } catch (e) {
      emit(OrderError('Failed to load order details: ${e.toString()}'));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      // Validate product quantities
      for (var item in event.items) {
        final product = await _productRepository.getProductById(item.productId);
        if (product == null) {
          emit(OrderError('Product not found'));
          return;
        }
        if (product.quantity < item.quantity) {
          emit(OrderError('Not enough stock for ${product.name}. Available: ${product.quantity}'));
          return;
        }
      }
      
      final orderId = await _orderRepository.createOrder(event.order, event.items);
      emit(OrderOperationSuccess('Order created successfully', orderId: orderId));
      
      // Reload order details
      add(LoadOrderById(orderId));
    } catch (e) {
      emit(OrderError('Failed to create order: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _orderRepository.updateOrder(event.order, event.items);
      emit(OrderOperationSuccess('Order updated successfully'));
      
      // Reload order details
      if (event.order.id != null) {
        add(LoadOrderById(event.order.id!));
      }
    } catch (e) {
      emit(OrderError('Failed to update order: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _orderRepository.updateOrderStatus(event.id, event.status);
      emit(OrderOperationSuccess('Order status updated to ${event.status}'));
      
      // Reload order details
      add(LoadOrderById(event.id));
    } catch (e) {
      emit(OrderError('Failed to update order status: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());
    try {
      await _orderRepository.deleteOrder(event.id);
      emit(OrderOperationSuccess('Order deleted successfully'));
      
      // Reload orders after delete
      add(LoadOrders());
    } catch (e) {
      emit(OrderError('Failed to delete order: ${e.toString()}'));
    }
  }

  Future<void> _onCheckProductAvailability(
    CheckProductAvailability event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final product = await _productRepository.getProductById(event.productId);
      if (product != null) {
        final isAvailable = product.quantity >= event.quantity;
        emit(ProductAvailability(product, isAvailable, event.quantity));
      } else {
        emit(OrderError('Product not found'));
      }
    } catch (e) {
      emit(OrderError('Failed to check product availability: ${e.toString()}'));
    }
  }
}

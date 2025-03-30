import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/utils/date_formatter.dart';
import 'package:supplier_management/core/utils/validators.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/features/clients/bloc/client_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/orders/bloc/order_bloc.dart';
import 'package:supplier_management/features/orders/models/order.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';
import 'package:supplier_management/features/orders/widgets/add_product_to_order.dart';
import 'package:supplier_management/features/orders/widgets/order_item_card.dart';

class AddEditOrderScreen extends StatefulWidget {
  final bool isEditing;

  const AddEditOrderScreen({
    Key? key,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddEditOrderScreenState createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _orderDateController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = AppConstants.orderStatusNew;
  Client? _selectedClient;
  int? _clientId;
  int? _orderId;
  List<OrderItem> _orderItems = [];
  bool _isLoading = false;
  double _subtotal = 0.0;
  double _total = 0.0;
  Order? _existingOrder;

  @override
  void initState() {
    super.initState();
    _orderDateController.text = DateFormatter.formatDate(_selectedDate);
    
    // Wait for client to be populated from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      if (args != null) {
        if (args is int) {
          setState(() {
            _clientId = args;
          });
          _loadClient(args);
        } else if (widget.isEditing && args is Order) {
          _existingOrder = args;
          _loadOrderDetails(args.id!);
        }
      }
      
      // Load all clients if no client is selected
      if (_selectedClient == null && _clientId == null) {
        context.read<ClientBloc>().add(LoadClients());
      }
    });
  }

  void _loadClient(int clientId) {
    context.read<ClientBloc>().add(LoadClientById(clientId));
  }

  void _loadOrderDetails(int orderId) {
    setState(() {
      _orderId = orderId;
    });
    context.read<OrderBloc>().add(LoadOrderById(orderId));
  }

  void _populateOrderDetails(Order order, List<OrderItem> items) {
    setState(() {
      _selectedDate = order.orderDate;
      _orderDateController.text = DateFormatter.formatDate(_selectedDate);
      _selectedStatus = order.status;
      _notesController.text = order.notes;
      _clientId = order.clientId;
      _orderItems = List.from(items);
      _calculateTotals();
    });
    
    // Load the client
    _loadClient(order.clientId);
  }

  void _addOrderItem(OrderItem item) {
    setState(() {
      // Check if the item is already in the order (same product)
      final existingItemIndex = _orderItems.indexWhere(
        (element) => element.productId == item.productId,
      );
      
      if (existingItemIndex >= 0) {
        // Update existing item quantity
        final existingItem = _orderItems[existingItemIndex];
        final newQuantity = existingItem.quantity + item.quantity;
        final newSubtotal = newQuantity * existingItem.pricePerUnit;
        
        _orderItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity,
          subtotal: newSubtotal,
        );
      } else {
        // Add new item
        _orderItems.add(item);
      }
      
      _calculateTotals();
    });
  }

  void _updateOrderItem(int index, OrderItem updatedItem) {
    setState(() {
      _orderItems[index] = updatedItem;
      _calculateTotals();
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    for (var item in _orderItems) {
      subtotal += item.subtotal;
    }
    
    setState(() {
      _subtotal = subtotal;
      _total = subtotal; // For simplicity, total equals subtotal
    });
  }

  void _submitOrder() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedClient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')),
        );
        return;
      }
      
      if (_orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one product')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      final order = Order(
        id: widget.isEditing ? _orderId : null,
        clientId: _selectedClient!.id!,
        orderDate: _selectedDate,
        status: _selectedStatus,
        subtotal: _subtotal,
        total: _total,
        notes: _notesController.text.trim(),
        createdAt: widget.isEditing ? _existingOrder!.createdAt : DateTime.now(),
        updatedAt: widget.isEditing ? DateTime.now() : null,
        clientName: _selectedClient!.name,
      );
      
      if (widget.isEditing) {
        context.read<OrderBloc>().add(UpdateOrder(order, _orderItems));
      } else {
        context.read<OrderBloc>().add(CreateOrder(order, _orderItems));
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _orderDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Order' : 'Create Order'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ClientBloc, ClientState>(
            listener: (context, state) {
              if (state is ClientLoaded && _clientId != null) {
                setState(() {
                  _selectedClient = state.client;
                });
              }
            },
          ),
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderDetails && widget.isEditing) {
                _populateOrderDetails(state.order, state.items);
              } else if (state is OrderOperationSuccess) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                
                // Navigate to the order details screen
                if (state.orderId != null) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/orders/detail',
                    arguments: state.orderId,
                  );
                } else {
                  Navigator.pop(context);
                }
              } else if (state is OrderError) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildClientSelection(),
                          const SizedBox(height: 16),
                          _buildOrderDetails(),
                          const SizedBox(height: 16),
                          _buildOrderItemsSection(),
                          const SizedBox(height: 16),
                          CustomTextField.multiline(
                            controller: _notesController,
                            label: 'Notes',
                            hint: 'Enter any additional notes',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildOrderSummary(),
                ],
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
        ),
      ),
    );
  }

  Widget _buildClientSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedClient != null)
              ListTile(
                leading: CircleAvatar(
                  child: Text(_selectedClient!.name[0]),
                ),
                title: Text(_selectedClient!.name),
                subtitle: Text(_selectedClient!.phone),
                trailing: widget.isEditing
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedClient = null;
                            _clientId = null;
                          });
                        },
                      ),
              )
            else
              BlocBuilder<ClientBloc, ClientState>(
                builder: (context, state) {
                  if (state is ClientsLoaded) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Client',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select a client'),
                      isExpanded: true,
                      items: state.clients.map((Client client) {
                        return DropdownMenuItem<int>(
                          value: client.id,
                          child: Text(client.name),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        if (value != null) {
                          _loadClient(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a client';
                        }
                        return null;
                      },
                    );
                  } else if (state is ClientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/clients/add');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Client'),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField.datePicker(
                    controller: _orderDateController,
                    label: 'Order Date',
                    hint: 'Select date',
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    isRequired: true,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStatus,
                    items: AppConstants.orderStatusList.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddProductToOrder(
                        onProductAdded: _addOrderItem,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_orderItems.isEmpty)
              const Center(
                heightFactor: 3,
                child: Text('No products added yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orderItems.length,
                itemBuilder: (context, index) {
                  return OrderItemCard(
                    orderItem: _orderItems[index],
                    onUpdate: (item) => _updateOrderItem(index, item),
                    onDelete: () => _removeOrderItem(index),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  '\$${_subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.isEditing ? 'Update Order' : 'Create Order',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

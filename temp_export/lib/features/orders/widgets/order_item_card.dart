import 'package:flutter/material.dart';
import 'package:supplier_management/features/orders/models/order_item.dart';

class OrderItemCard extends StatefulWidget {
  final OrderItem orderItem;
  final Function(OrderItem)? onUpdate;
  final VoidCallback? onDelete;
  final bool isReadOnly;

  const OrderItemCard({
    Key? key,
    required this.orderItem,
    this.onUpdate,
    this.onDelete,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  _OrderItemCardState createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  late TextEditingController _quantityController;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.orderItem.quantity;
    _quantityController = TextEditingController(text: _quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity <= 0) {
      newQuantity = 1;
    }
    
    setState(() {
      _quantity = newQuantity;
      _quantityController.text = newQuantity.toString();
    });
    
    final updatedItem = widget.orderItem.copyWith(
      quantity: newQuantity,
      subtotal: newQuantity * widget.orderItem.pricePerUnit,
    );
    
    if (widget.onUpdate != null) {
      widget.onUpdate!(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.orderItem.productName ?? 'Product #${widget.orderItem.productId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.orderItem.productCategory != null) ...[
                  Text(
                    widget.orderItem.productCategory!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '\$${widget.orderItem.pricePerUnit.toStringAsFixed(2)} per unit',
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isReadOnly) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Qty: ${widget.orderItem.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${widget.orderItem.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: _quantity > 1
                            ? () => _updateQuantity(_quantity - 1)
                            : null,
                      ),
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            final newQuantity = int.tryParse(value) ?? 1;
                            _updateQuantity(newQuantity);
                          },
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _updateQuantity(_quantity + 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: widget.onDelete,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.orderItem.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

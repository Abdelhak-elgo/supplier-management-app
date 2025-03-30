import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/widgets/app_drawer.dart';
import 'package:supplier_management/core/widgets/empty_state_widget.dart';
import 'package:supplier_management/core/widgets/error_widget.dart';
import 'package:supplier_management/core/widgets/loading_widget.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/features/clients/bloc/client_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/clients/widgets/client_card.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({Key? key}) : super(key: key);

  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  
  @override
  void initState() {
    super.initState();
    _loadClients();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadClients() {
    context.read<ClientBloc>().add(LoadClients());
  }
  
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _loadClients();
    } else {
      context.read<ClientBloc>().add(SearchClients(query));
    }
  }
  
  void _filterByType(String? type) {
    setState(() {
      _selectedType = type;
    });
    
    if (type == null) {
      _loadClients();
    } else {
      context.read<ClientBloc>().add(LoadClientsByType(type));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
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
          _buildTypeChips(),
          Expanded(
            child: BlocConsumer<ClientBloc, ClientState>(
              listener: (context, state) {
                if (state is ClientError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is ClientsLoading) {
                  return const LoadingWidget();
                } else if (state is ClientsLoaded) {
                  return _buildClientList(state.clients);
                } else if (state is ClientError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadClients,
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
          Navigator.pushNamed(context, '/clients/add');
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
        hint: 'Search clients by name, phone, or city...',
        onChanged: _onSearchChanged,
        onClear: () {
          _searchController.clear();
          _loadClients();
        },
      ),
    );
  }
  
  Widget _buildTypeChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildTypeChip(null, 'All'),
            ...AppConstants.clientTypeList.map((type) {
              return _buildTypeChip(type, type);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeChip(String? type, String label) {
    final isSelected = _selectedType == type;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          _filterByType(type);
        },
      ),
    );
  }
  
  Widget _buildClientList(List<Client> clients) {
    if (clients.isEmpty) {
      return EmptyStateWidget(
        message: 'No clients found',
        subMessage: _searchController.text.isNotEmpty
            ? 'Try a different search term'
            : _selectedType != null
                ? 'No clients in this category'
                : 'Add your first client',
        icon: Icons.people_outline,
        onAction: () {
          Navigator.pushNamed(context, '/clients/add');
        },
        actionLabel: 'Add Client',
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _loadClients();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          return ClientCard(
            client: clients[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/clients/detail',
                arguments: clients[index].id,
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
                'Filter Clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Client Type',
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
                      _filterByType(null);
                    },
                  ),
                  ...AppConstants.clientTypeList.map((type) {
                    Color chipColor;
                    switch (type) {
                      case 'VIP':
                        chipColor = Colors.amber[100]!;
                        break;
                      case 'New':
                        chipColor = Colors.blue[100]!;
                        break;
                      default:
                        chipColor = Colors.grey[100]!;
                    }
                    
                    return ActionChip(
                      label: Text(type),
                      backgroundColor: chipColor,
                      onPressed: () {
                        Navigator.pop(context);
                        _filterByType(type);
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

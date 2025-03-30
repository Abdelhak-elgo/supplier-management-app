import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/core/constants/app_constants.dart';
import 'package:supplier_management/core/utils/validators.dart';
import 'package:supplier_management/core/widgets/custom_text_field.dart';
import 'package:supplier_management/features/clients/bloc/client_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';

class AddEditClientScreen extends StatefulWidget {
  final bool isEditing;

  const AddEditClientScreen({
    Key? key,
    this.isEditing = false,
  }) : super(key: key);

  @override
  _AddEditClientScreenState createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'Regular';
  bool _isLoading = false;
  Client? _client;

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing) {
      // Wait for client to be populated from arguments
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_client != null) {
          _populateFields();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isEditing && _client == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Client) {
        _client = args;
        _populateFields();
      }
    }
  }

  void _populateFields() {
    final client = _client;
    if (client != null) {
      _nameController.text = client.name;
      _phoneController.text = client.phone;
      _cityController.text = client.city;
      _notesController.text = client.notes;
      setState(() {
        _selectedType = client.type;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final client = Client(
        id: widget.isEditing ? _client?.id : null,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        notes: _notesController.text.trim(),
        type: _selectedType,
        createdAt: widget.isEditing ? _client!.createdAt : DateTime.now(),
      );

      if (widget.isEditing) {
        context.read<ClientBloc>().add(UpdateClient(client));
      } else {
        context.read<ClientBloc>().add(AddClient(client));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Client' : 'Add Client'),
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listener: (context, state) {
          if (state is ClientOperationSuccess) {
            setState(() {
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            
            Navigator.pop(context);
          } else if (state is ClientError) {
            setState(() {
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                        label: 'Client Name',
                        hint: 'Enter client name',
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => Validators.validateRequired(value, 'Client name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField.phone(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Enter city',
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _buildClientTypeDropdown(),
                      const SizedBox(height: 16),
                      CustomTextField.multiline(
                        controller: _notesController,
                        label: 'Notes',
                        hint: 'Enter additional notes',
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.isEditing ? 'Update Client' : 'Add Client',
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

  Widget _buildClientTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Client Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      value: _selectedType,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedType = newValue;
          });
        }
      },
      items: AppConstants.clientTypeList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

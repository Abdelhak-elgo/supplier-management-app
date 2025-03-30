import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supplier_management/features/clients/models/client.dart';
import 'package:supplier_management/features/clients/repository/client_repository.dart';

// Events
abstract class ClientEvent {}

class LoadClients extends ClientEvent {}

class LoadClientsByType extends ClientEvent {
  final String type;

  LoadClientsByType(this.type);
}

class SearchClients extends ClientEvent {
  final String query;

  SearchClients(this.query);
}

class LoadClientById extends ClientEvent {
  final int id;

  LoadClientById(this.id);
}

class AddClient extends ClientEvent {
  final Client client;

  AddClient(this.client);
}

class UpdateClient extends ClientEvent {
  final Client client;

  UpdateClient(this.client);
}

class DeleteClient extends ClientEvent {
  final int id;

  DeleteClient(this.id);
}

class LoadClientStats extends ClientEvent {
  final int id;

  LoadClientStats(this.id);
}

// States
abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientsLoading extends ClientState {}

class ClientsLoaded extends ClientState {
  final List<Client> clients;
  final String? filterType;

  ClientsLoaded(this.clients, {this.filterType});
}

class ClientLoaded extends ClientState {
  final Client client;

  ClientLoaded(this.client);
}

class ClientWithStats extends ClientState {
  final Client client;
  final Map<String, dynamic> stats;

  ClientWithStats(this.client, this.stats);
}

class ClientOperationSuccess extends ClientState {
  final String message;

  ClientOperationSuccess(this.message);
}

class ClientError extends ClientState {
  final String message;

  ClientError(this.message);
}

// BLoC
class ClientBloc extends Bloc<ClientEvent, ClientState> {
  final ClientRepository _clientRepository;

  ClientBloc(this._clientRepository) : super(ClientInitial()) {
    on<LoadClients>(_onLoadClients);
    on<LoadClientsByType>(_onLoadClientsByType);
    on<SearchClients>(_onSearchClients);
    on<LoadClientById>(_onLoadClientById);
    on<AddClient>(_onAddClient);
    on<UpdateClient>(_onUpdateClient);
    on<DeleteClient>(_onDeleteClient);
    on<LoadClientStats>(_onLoadClientStats);
  }

  Future<void> _onLoadClients(
    LoadClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final clients = await _clientRepository.getAllClients();
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientError('Failed to load clients: ${e.toString()}'));
    }
  }

  Future<void> _onLoadClientsByType(
    LoadClientsByType event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final clients = await _clientRepository.getClientsByType(event.type);
      emit(ClientsLoaded(clients, filterType: event.type));
    } catch (e) {
      emit(ClientError('Failed to load clients: ${e.toString()}'));
    }
  }

  Future<void> _onSearchClients(
    SearchClients event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final clients = await _clientRepository.searchClients(event.query);
      emit(ClientsLoaded(clients));
    } catch (e) {
      emit(ClientError('Failed to search clients: ${e.toString()}'));
    }
  }

  Future<void> _onLoadClientById(
    LoadClientById event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final client = await _clientRepository.getClientById(event.id);
      if (client != null) {
        emit(ClientLoaded(client));
      } else {
        emit(ClientError('Client not found'));
      }
    } catch (e) {
      emit(ClientError('Failed to load client: ${e.toString()}'));
    }
  }

  Future<void> _onAddClient(
    AddClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await _clientRepository.insertClient(event.client);
      emit(ClientOperationSuccess('Client added successfully'));
      
      // Reload clients after add
      add(LoadClients());
    } catch (e) {
      emit(ClientError('Failed to add client: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateClient(
    UpdateClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await _clientRepository.updateClient(event.client);
      emit(ClientOperationSuccess('Client updated successfully'));
      
      // Reload the client after update
      if (event.client.id != null) {
        add(LoadClientById(event.client.id!));
      }
    } catch (e) {
      emit(ClientError('Failed to update client: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteClient(
    DeleteClient event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      await _clientRepository.deleteClient(event.id);
      emit(ClientOperationSuccess('Client deleted successfully'));
      
      // Reload clients after delete
      add(LoadClients());
    } catch (e) {
      emit(ClientError('Failed to delete client: ${e.toString()}'));
    }
  }

  Future<void> _onLoadClientStats(
    LoadClientStats event,
    Emitter<ClientState> emit,
  ) async {
    emit(ClientsLoading());
    try {
      final client = await _clientRepository.getClientById(event.id);
      if (client != null) {
        final stats = await _clientRepository.getClientStats(event.id);
        emit(ClientWithStats(client, stats));
      } else {
        emit(ClientError('Client not found'));
      }
    } catch (e) {
      emit(ClientError('Failed to load client stats: ${e.toString()}'));
    }
  }
}

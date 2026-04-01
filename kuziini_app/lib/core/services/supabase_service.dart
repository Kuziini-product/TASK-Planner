import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  SupabaseStorageClient get storage => client.storage;

  User? get currentUser => auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  Session? get currentSession => auth.currentSession;

  Stream<AuthState> get onAuthStateChange => auth.onAuthStateChange;

  // ── Query Helpers ──
  SupabaseQueryBuilder from(String table) => client.from(table);

  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    PostgrestFilterBuilder filterQuery = client.from(table).select(columns);

    if (filters != null) {
      for (final entry in filters.entries) {
        filterQuery = filterQuery.eq(entry.key, entry.value);
      }
    }

    PostgrestTransformBuilder transformQuery = filterQuery;

    if (orderBy != null) {
      transformQuery = transformQuery.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      transformQuery = transformQuery.limit(limit);
    }

    if (offset != null) {
      transformQuery = transformQuery.range(offset, offset + (limit ?? 20) - 1);
    }

    final response = await transformQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> selectSingle(
    String table, {
    String columns = '*',
    required Map<String, dynamic> filters,
  }) async {
    var query = client.from(table).select(columns);
    for (final entry in filters.entries) {
      query = query.eq(entry.key, entry.value);
    }
    final response = await query.single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await client.from(table).insert(data).select().single();
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required String id,
    String idColumn = 'id',
  }) async {
    final response = await client
        .from(table)
        .update(data)
        .eq(idColumn, id)
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> delete(
    String table, {
    required String id,
    String idColumn = 'id',
  }) async {
    await client.from(table).delete().eq(idColumn, id);
  }

  // ── Real-time ──
  RealtimeChannel subscribe(
    String table, {
    required void Function(PostgresChangePayload payload) onInsert,
    void Function(PostgresChangePayload payload)? onUpdate,
    void Function(PostgresChangePayload payload)? onDelete,
    String? filter,
  }) {
    var channel = client.channel('public:$table');

    channel = channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      filter: filter != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: filter.split('=').first, value: filter.split('=').last) : null,
      callback: onInsert,
    );

    if (onUpdate != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        filter: filter != null ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: filter.split('=').first, value: filter.split('=').last) : null,
        callback: onUpdate,
      );
    }

    if (onDelete != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      );
    }

    channel.subscribe();
    return channel;
  }

  void unsubscribe(RealtimeChannel channel) {
    client.removeChannel(channel);
  }

  // ── Storage ──
  Future<String> uploadFile(
    String bucket,
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    await storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return storage.from(bucket).getPublicUrl(path);
  }

  Future<String> uploadBytes(
    String bucket,
    String path,
    Uint8List bytes, {
    String? contentType,
  }) async {
    await storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteFile(String bucket, String path) async {
    await storage.from(bucket).remove([path]);
  }

  String getPublicUrl(String bucket, String path) {
    return storage.from(bucket).getPublicUrl(path);
  }

  // ── RPC ──
  Future<dynamic> rpc(String functionName, {Map<String, dynamic>? params}) async {
    return await client.rpc(functionName, params: params);
  }
}

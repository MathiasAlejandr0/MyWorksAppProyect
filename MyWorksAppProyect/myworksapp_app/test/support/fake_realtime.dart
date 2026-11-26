// Simula un INSERT de Realtime en un canal ya creado por la app, sin socket:
// RealtimeChannel.trigger entrega el evento a los bindings postgres_changes
// (sin id de servidor se filtran por el nombre del evento).
import 'package:supabase_flutter/supabase_flutter.dart';

/// Envía [record] como INSERT de [table] a los canales cuyo topic contiene
/// [topicContains]. Devuelve cuántos canales recibieron el evento.
int emitRealtimeInsert(
  String topicContains,
  String table,
  Map<String, dynamic> record,
) {
  var hits = 0;
  for (final channel in Supabase.instance.client.getChannels()) {
    if (!channel.topic.contains(topicContains)) continue;
    channel.trigger('postgres_changes', {
      'event': 'INSERT',
      'eventType': 'INSERT',
      'schema': 'public',
      'table': table,
      'commit_timestamp': DateTime.now().toUtc().toIso8601String(),
      'new': record,
      'old': <String, dynamic>{},
      'errors': null,
    });
    hits++;
  }
  return hits;
}

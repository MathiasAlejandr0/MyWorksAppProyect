import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso centralizado al cliente Supabase (Postgrest + Auth + Storage).
SupabaseClient get supabase => Supabase.instance.client;

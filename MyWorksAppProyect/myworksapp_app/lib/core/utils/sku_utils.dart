/// Mapeo variante de formulario → código SKU de precio fijo.
String? variantToSkuCode(String? variantId) {
  if (variantId == null || variantId.isEmpty) return null;
  const map = {
    'lock_cylinder': 'LOCK_CYLINDER_REPLACE',
    'cerradura': 'LOCK_CYLINDER_REPLACE',
    'water_heater': 'WATER_HEATER_INSTALL',
    'calefont': 'WATER_HEATER_INSTALL',
    'faucet': 'FAUCET_REPLACE',
    'grifo': 'FAUCET_REPLACE',
  };
  final key = variantId.toLowerCase();
  if (map.containsKey(key)) return map[key];
  final upper = variantId.toUpperCase().replaceAll('-', '_');
  if (upper.contains('LOCK')) return 'LOCK_CYLINDER_REPLACE';
  if (upper.contains('WATER') || upper.contains('CALEFON')) {
    return 'WATER_HEATER_INSTALL';
  }
  if (upper.contains('FAUCET') || upper.contains('GRIFO')) {
    return 'FAUCET_REPLACE';
  }
  return null;
}

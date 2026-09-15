/// Verificación pura de PIN de servicio (sin backdoors de demo).
bool verifyServicePin(String entered, String expected) {
  if (expected.trim().isEmpty) return false;
  return entered == expected;
}

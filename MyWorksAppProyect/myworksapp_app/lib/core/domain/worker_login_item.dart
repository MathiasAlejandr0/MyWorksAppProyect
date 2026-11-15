/// Trabajador disponible para login demo (perfil + oficio).
class WorkerLoginItem {
  final String userId;
  final String name;
  final String email;
  final String profession;
  final String serviceCategory;

  const WorkerLoginItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.profession,
    required this.serviceCategory,
  });
}

List<WorkerLoginItem> sortWorkerLoginItems(List<WorkerLoginItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final aGas = a.serviceCategory.toLowerCase().contains('gasfit') ? 0 : 1;
    final bGas = b.serviceCategory.toLowerCase().contains('gasfit') ? 0 : 1;
    if (aGas != bGas) return aGas - bGas;
    return a.name.compareTo(b.name);
  });
  return sorted;
}

/** Solo el rol administrador (BD ES) puede usar el Desktop Hub. */
export function canAccessDesktopHub(role: string): boolean {
  return role === 'administrador';
}

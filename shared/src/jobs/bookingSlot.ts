/** Próximo viernes a las 10, 14 o 18, en la zona horaria del navegador. */
export function visitSlotIso(hour: '10' | '14' | '18', now = new Date()): string {
  const friday = new Date(now.getTime());
  const daysAhead = (5 - friday.getDay() + 7) % 7 || 7;
  friday.setDate(friday.getDate() + daysAhead);
  const clock = hour === '14' ? 14 : hour === '18' ? 18 : 10;
  friday.setHours(clock, 0, 0, 0);
  return friday.toISOString();
}

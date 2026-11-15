export type DayWindow = {
  weekday: number;
  startMinute: number;
  endMinute: number;
  enabled: boolean;
};

export type WeeklyHours = {
  enabled: boolean;
  days: DayWindow[];
};

type Civil = { weekday: number; minute: number };

function santiagoCivil(instant: Date): Civil {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/Santiago',
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);
  const weekdayName = parts.find((part) => part.type === 'weekday')?.value ?? 'Mon';
  const hour = Number(parts.find((part) => part.type === 'hour')?.value ?? '0');
  const minute = Number(parts.find((part) => part.type === 'minute')?.value ?? '0');
  const map: Record<string, number> = {
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  };
  return { weekday: map[weekdayName] ?? 1, minute: hour * 60 + minute };
}

export function isOpenAt(schedule: WeeklyHours | null | undefined, instant: Date): boolean {
  if (!schedule || !schedule.enabled || schedule.days.length === 0) return true;
  const civil = santiagoCivil(instant);
  const window = schedule.days.find((day) => day.weekday === civil.weekday);
  if (!window || !window.enabled) return false;
  return civil.minute >= window.startMinute && civil.minute < window.endMinute;
}

export function visitFitsSchedule(schedule: WeeklyHours | null | undefined, instant: Date): boolean {
  if (!schedule || !schedule.enabled || schedule.days.length === 0) return true;
  return isOpenAt(schedule, instant);
}

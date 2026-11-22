const KEY = 'mwa-equipo-compartido';

export function sharedDeviceEnabled(): boolean {
  return localStorage.getItem(KEY) === '1';
}

export function setSharedDevice(enabled: boolean): void {
  localStorage.setItem(KEY, enabled ? '1' : '0');
}

const THEME = 'mwa-tema';

export type ThemeName = 'dark' | 'light';

export function savedTheme(): ThemeName {
  return localStorage.getItem(THEME) === 'light' ? 'light' : 'dark';
}

export function applyTheme(theme: ThemeName): void {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem(THEME, theme);
}

export type DensityName = 'comoda' | 'compacta';

const DENSITY = 'mwa-densidad';

export function savedDensity(): DensityName {
  return localStorage.getItem(DENSITY) === 'compacta' ? 'compacta' : 'comoda';
}

export function setDensity(density: DensityName): void {
  document.documentElement.dataset.density = density;
  localStorage.setItem(DENSITY, density);
}

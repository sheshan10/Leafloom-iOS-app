export type DeviceId = 'iphone-se' | 'iphone-16' | 'iphone-16-pro-max';

export interface DeviceSpec {
  id: DeviceId;
  label: string;
  width: number;
  height: number;
  safeTop: number;
  safeBottom: number;
  radius: number;
  island: boolean;
}

/** Logical point sizes and safe-area insets of current iPhone classes (portrait). */
export const devices: Record<DeviceId, DeviceSpec> = {
  'iphone-se': { id: 'iphone-se', label: 'iPhone SE (375×667)', width: 375, height: 667, safeTop: 20, safeBottom: 0, radius: 36, island: false },
  'iphone-16': { id: 'iphone-16', label: 'iPhone 16 (393×852)', width: 393, height: 852, safeTop: 59, safeBottom: 34, radius: 54, island: true },
  'iphone-16-pro-max': { id: 'iphone-16-pro-max', label: 'iPhone 16 Pro Max (440×956)', width: 440, height: 956, safeTop: 62, safeBottom: 34, radius: 60, island: true },
};

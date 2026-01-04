export type Theme = 'light' | 'dark' | 'auto';
export type DefaultView = 'dashboard' | 'books' | 'journal';

export interface UserSettings {
  id: string;
  visitorId?: string;
  userId?: string;
  kindleCookies?: string;
  kindleDeviceToken?: string;
  lastKindleSync?: Date;
  theme?: Theme;
  defaultView?: DefaultView;
  lastExportedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface UpdateSettingsInput {
  kindleCookies?: string;
  kindleDeviceToken?: string;
  lastKindleSync?: Date;
  theme?: Theme;
  defaultView?: DefaultView;
  lastExportedAt?: Date;
}

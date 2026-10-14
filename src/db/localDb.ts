/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { Product, Session, Currency, Settings, POSDataBackup } from '../types/pos';

// Seeding standard initial products for Cuba gastronomy/retail
const SEEDED_PRODUCTS: Product[] = [];

const SEEDED_CURRENCIES: Currency[] = [
  { code: 'CUP', name: 'Peso Cubano', symbol: '$', rateToBase: 1 },
  { code: 'USD', name: 'Dólar Americano', symbol: 'US$', rateToBase: 350 },
  { code: 'EUR', name: 'Euro', symbol: '€', rateToBase: 360 },
  { code: 'MLC', name: 'Moneda Libremente Convertible', symbol: 'MLC', rateToBase: 310 },
];

const DEFAULT_SETTINGS: Settings = {
  defaultCurrency: 'CUP',
  longPressAction: 'lock',
  hapticFeedbackEnabled: true,
  googleClientId: '',
  backupIntervalMinutes: 30,
  theme: 'light',
};

// Storage Keys
const STORAGE_KEYS = {
  PRODUCTS: 'milypico_products',
  SESSIONS: 'milypico_sessions',
  CURRENCIES: 'milypico_currencies',
  SETTINGS: 'milypico_settings',
};

export const localDb = {
  getProducts(): Product[] {
    const data = localStorage.getItem(STORAGE_KEYS.PRODUCTS);
    if (!data) {
      this.saveProducts(SEEDED_PRODUCTS);
      return SEEDED_PRODUCTS;
    }
    try {
      return JSON.parse(data);
    } catch {
      return SEEDED_PRODUCTS;
    }
  },

  saveProducts(products: Product[]): void {
    localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(products));
  },

  getSessions(): Session[] {
    const data = localStorage.getItem(STORAGE_KEYS.SESSIONS);
    if (!data) {
      return [];
    }
    try {
      return JSON.parse(data);
    } catch {
      return [];
    }
  },

  saveSessions(sessions: Session[]): void {
    localStorage.setItem(STORAGE_KEYS.SESSIONS, JSON.stringify(sessions));
  },

  getCurrencies(): Currency[] {
    const data = localStorage.getItem(STORAGE_KEYS.CURRENCIES);
    if (!data) {
      this.saveCurrencies(SEEDED_CURRENCIES);
      return SEEDED_CURRENCIES;
    }
    try {
      return JSON.parse(data);
    } catch {
      return SEEDED_CURRENCIES;
    }
  },

  saveCurrencies(currencies: Currency[]): void {
    localStorage.setItem(STORAGE_KEYS.CURRENCIES, JSON.stringify(currencies));
  },

  getSettings(): Settings {
    const data = localStorage.getItem(STORAGE_KEYS.SETTINGS);
    if (!data) {
      this.saveSettings(DEFAULT_SETTINGS);
      return DEFAULT_SETTINGS;
    }
    try {
      return { ...DEFAULT_SETTINGS, ...JSON.parse(data) };
    } catch {
      return DEFAULT_SETTINGS;
    }
  },

  saveSettings(settings: Settings): void {
    localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
  },

  // Auto-generate session name in spanish like "16 Sep" or "16 Sep (2)"
  generateSessionName(existingSessions: Session[]): string {
    const date = new Date();
    const formatter = new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short' });
    let formatted = formatter.format(date).replace('.', ''); // e.g. "16 sep"
    
    // Capitalize words
    let name = formatted
      .split(' ')
      .map(w => w.charAt(0).toUpperCase() + w.slice(1))
      .join(' ');

    let baseName = name;
    let suffix = 2;
    
    // Check if duplicate name exists in active or historic sessions
    while (existingSessions.some(s => s.name.toLowerCase() === name.toLowerCase() && s.status === 'open')) {
      name = `${baseName} (${suffix})`;
      suffix++;
    }
    // Also check closed sessions to prevent overlap in indexing
    while (existingSessions.some(s => s.name.toLowerCase() === name.toLowerCase())) {
      name = `${baseName} (${suffix})`;
      suffix++;
    }

    return name;
  },

  // Export fully serialized state for backup
  exportBackup(): POSDataBackup {
    return {
      version: '1.0.0',
      timestamp: Date.now(),
      products: this.getProducts(),
      sessions: this.getSessions(),
      currencies: this.getCurrencies(),
      settings: this.getSettings(),
    };
  },

  // Safely import and overwrite backup
  importBackup(backup: POSDataBackup): boolean {
    if (!backup || backup.version !== '1.0.0') {
      console.error('Invalid backup version or format');
      return false;
    }

    try {
      if (Array.isArray(backup.products)) {
        this.saveProducts(backup.products);
      }
      if (Array.isArray(backup.sessions)) {
        this.saveSessions(backup.sessions);
      }
      if (Array.isArray(backup.currencies)) {
        this.saveCurrencies(backup.currencies);
      }
      if (backup.settings) {
        this.saveSettings(backup.settings);
      }
      return true;
    } catch (e) {
      console.error('Failed to parse backup', e);
      return false;
    }
  },
};

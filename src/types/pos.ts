/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export type UnitType = 'u' | 'lb';

export type PriceTier = 'normal' | 'mayorista' | 'oferta' | 'personalizado';

export interface Product {
  id: string;
  name: string;
  emoji: string;
  unit: UnitType;
  prices: {
    normal: number;
    mayorista?: number;
    oferta?: number;
    personalizado?: number; // fallback custom price
  };
  category?: string;
  createdTime: number;
}

export interface CartItem {
  id: string; // unique cart line ID
  productId: string;
  quantity: number;
  selectedTier: PriceTier;
  customPrice?: number; // used if tier is 'personalizado'
  isLocked: boolean; // long-press/double-tap toggle
}

export interface Cart {
  id: string;
  number: number; // sequential bold #1, #2
  color: string; // CSS color theme class (e.g. bg-rose-600)
  items: CartItem[];
  createdTime: number;
}

export interface TransactionItem {
  name: string;
  emoji: string;
  quantity: number;
  unit: UnitType;
  price: number;
  subtotal: number;
}

export interface Transaction {
  id: string;
  sessionName: string;
  cartNumber: number;
  items: TransactionItem[];
  totalCUP: number;
  paymentCurrency: string; // e.g. "CUP" or "USD"
  paymentAmount: number; // calculated according to rate
  exchangeRateUsed: number; // conversion rate relative to CUP
  timestamp: number;
}

export interface Session {
  id: string;
  name: string; // "16 Sep", "16 Sep (2)"
  createdTime: number;
  closedTime?: number;
  status: 'open' | 'closed';
  transactions: Transaction[];
}

export interface Currency {
  code: string; // "CUP", "USD", "EUR", "MLC", etc.
  name: string;
  symbol: string;
  rateToBase: number; // how many CUPs per 1 Unit of this currency (e.g. 1 USD = 350 CUP)
  isCustom?: boolean;
}

export interface Settings {
  defaultCurrency: string;
  longPressAction: 'lock' | 'delete' | 'discount';
  hapticFeedbackEnabled: boolean;
  googleClientId: string; // client can enter their own Google OAuth Client ID at runtime!
  backupIntervalMinutes: number;
  theme: 'light' | 'dark';
}

export interface POSDataBackup {
  version: string;
  timestamp: number;
  products: Product[];
  sessions: Session[];
  currencies: Currency[];
  settings: Settings;
}

/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { createContext, useContext, useState, useEffect } from 'react';
import { Product, Session, Currency, Settings, Cart, CartItem, PriceTier, Transaction, TransactionItem, POSDataBackup } from '../types/pos';
import { localDb } from '../db/localDb';
import { useOnlineStatus } from '../hooks/usePWAInstall';

interface POSContextType {
  products: Product[];
  sessions: Session[];
  currencies: Currency[];
  settings: Settings;
  activeCarts: Cart[];
  activeCartIndex: number;
  currentSession: Session | null;
  isOnline: boolean;
  
  // Session Actions
  openSession: () => void;
  closeSession: () => void;
  
  // Catalog Actions
  addProduct: (product: Omit<Product, 'id' | 'createdTime'>) => void;
  updateProduct: (id: string, product: Partial<Product>) => void;
  deleteProduct: (id: string) => void;
  
  // Currency Actions
  updateCurrencyRate: (code: string, rate: number) => void;
  addCustomCurrency: (currency: Omit<Currency, 'isCustom'>) => void;
  deleteCustomCurrency: (code: string) => void;
  
  // Settings Actions
  updateSettings: (settings: Partial<Settings>) => void;
  
  // Cart Actions
  createCart: () => void;
  deleteCart: (id: string) => void;
  addItemToCart: (cartId: string, productId: string) => void;
  updateCartItemQuantity: (cartId: string, itemId: string, qty: number) => void;
  setProductQuantity: (cartId: string, productId: string, qty: number) => void;
  updateCartItemTier: (cartId: string, itemId: string, tier: PriceTier, customPrice?: number) => void;
  toggleCartItemLock: (cartId: string, itemId: string) => void;
  setActiveCartIndex: (idx: number) => void;
  checkoutCart: (cartId: string, currencyCode: string) => Transaction | null;
  
  // Import/Export
  restoreBackup: (backup: POSDataBackup) => boolean;
}

const POSContext = createContext<POSContextType | undefined>(undefined);

export const POSProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isOnline = useOnlineStatus();
  
  // Load state from db on mount
  const [products, setProducts] = useState<Product[]>([]);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [currencies, setCurrencies] = useState<Currency[]>([]);
  const [settings, setSettings] = useState<Settings>(localDb.getSettings());
  
  // Active in-memory carts
  const [activeCarts, setActiveCarts] = useState<Cart[]>([]);
  const [activeCartIndex, setActiveCartIndex] = useState<number>(0);
  
  // Currently active open session
  const [currentSession, setCurrentSession] = useState<Session | null>(null);

  useEffect(() => {
    // Sync initial state
    const loadedProducts = localDb.getProducts();
    const loadedSessions = localDb.getSessions();
    const loadedCurrencies = localDb.getCurrencies();
    const loadedSettings = localDb.getSettings();
    
    setProducts(loadedProducts);
    setSessions(loadedSessions);
    setCurrencies(loadedCurrencies);
    setSettings(loadedSettings);
    
    // Find active open session
    const openSess = loadedSessions.find(s => s.status === 'open');
    if (openSess) {
      setCurrentSession(openSess);
    }
    
    // Create initial cart if none exists
    const storedCarts = localStorage.getItem('milypico_active_carts');
    if (storedCarts) {
      try {
        const parsed = JSON.parse(storedCarts);
        if (parsed.length > 0) {
          setActiveCarts(parsed);
          return;
        }
      } catch (e) {
        console.error('Failed to parse stored active carts', e);
      }
    }
    
    // Fallback: Default cart #1
    const defaultCart: Cart = {
      id: 'cart-' + Date.now(),
      number: 1,
      color: 'sky',
      items: [],
      createdTime: Date.now(),
    };
    setActiveCarts([defaultCart]);
  }, []);

  // Save active carts to localStorage on change
  useEffect(() => {
    if (activeCarts.length > 0) {
      localStorage.setItem('milypico_active_carts', JSON.stringify(activeCarts));
    } else {
      localStorage.removeItem('milypico_active_carts');
    }
  }, [activeCarts]);

  // Haptic feedback helper
  const triggerHaptic = () => {
    if (settings.hapticFeedbackEnabled && typeof navigator !== 'undefined' && navigator.vibrate) {
      navigator.vibrate(15);
    }
  };

  // -------------------------------------------------------------
  // Session Actions
  // -------------------------------------------------------------
  const openSession = () => {
    triggerHaptic();
    const name = localDb.generateSessionName(sessions);
    const newSession: Session = {
      id: 'session-' + Date.now(),
      name,
      createdTime: Date.now(),
      status: 'open',
      transactions: [],
    };
    const updatedSessions = [newSession, ...sessions];
    setSessions(updatedSessions);
    setCurrentSession(newSession);
    localDb.saveSessions(updatedSessions);
  };

  const closeSession = () => {
    triggerHaptic();
    if (!currentSession) return;
    
    const updatedSessions = sessions.map(s => {
      if (s.id === currentSession.id) {
        return {
          ...s,
          status: 'closed' as const,
          closedTime: Date.now(),
        };
      }
      return s;
    });
    
    setSessions(updatedSessions);
    setCurrentSession(null);
    localDb.saveSessions(updatedSessions);
  };

  // -------------------------------------------------------------
  // Catalog Actions
  // -------------------------------------------------------------
  const addProduct = (p: Omit<Product, 'id' | 'createdTime'>) => {
    const newProd: Product = {
      ...p,
      id: 'prod-' + Date.now(),
      createdTime: Date.now(),
    };
    const updated = [newProd, ...products];
    setProducts(updated);
    localDb.saveProducts(updated);
  };

  const updateProduct = (id: string, partial: Partial<Product>) => {
    const updated = products.map(p => (p.id === id ? { ...p, ...partial } : p));
    setProducts(updated);
    localDb.saveProducts(updated);
  };

  const deleteProduct = (id: string) => {
    const updated = products.filter(p => p.id !== id);
    setProducts(updated);
    localDb.saveProducts(updated);
  };

  // -------------------------------------------------------------
  // Currency Actions
  // -------------------------------------------------------------
  const updateCurrencyRate = (code: string, rate: number) => {
    const updated = currencies.map(c => (c.code === code ? { ...c, rateToBase: rate } : c));
    setCurrencies(updated);
    localDb.saveCurrencies(updated);
  };

  const addCustomCurrency = (c: Omit<Currency, 'isCustom'>) => {
    const newCurr: Currency = {
      ...c,
      isCustom: true,
    };
    const updated = [...currencies, newCurr];
    setCurrencies(updated);
    localDb.saveCurrencies(updated);
  };

  const deleteCustomCurrency = (code: string) => {
    const updated = currencies.filter(c => c.code !== code);
    setCurrencies(updated);
    localDb.saveCurrencies(updated);
  };

  // -------------------------------------------------------------
  // Settings Actions
  // -------------------------------------------------------------
  const updateSettings = (updated: Partial<Settings>) => {
    const newSettings = { ...settings, ...updated };
    setSettings(newSettings);
    localDb.saveSettings(newSettings);
  };

  // -------------------------------------------------------------
  // Cart Actions
  // -------------------------------------------------------------
  const createCart = () => {
    triggerHaptic();
    const nextNum = activeCarts.length > 0 ? Math.max(...activeCarts.map(c => c.number)) + 1 : 1;
    const colorPool = ['sky', 'rose', 'emerald', 'amber', 'purple', 'violet', 'fuchsia', 'orange', 'cyan', 'lime', 'indigo'];
    const color = colorPool[(nextNum - 1) % colorPool.length];
    
    const newCart: Cart = {
      id: 'cart-' + Date.now(),
      number: nextNum,
      color,
      items: [],
      createdTime: Date.now(),
    };
    
    const updated = [...activeCarts, newCart];
    setActiveCarts(updated);
    setActiveCartIndex(updated.length - 1);
  };

  const deleteCart = (id: string) => {
    triggerHaptic();
    // Protect so there is always at least 1 cart
    if (activeCarts.length <= 1) {
      const resetCart: Cart = {
        id: 'cart-' + Date.now(),
        number: 1,
        color: 'sky',
        items: [],
        createdTime: Date.now(),
      };
      setActiveCarts([resetCart]);
      setActiveCartIndex(0);
      return;
    }

    const updated = activeCarts.filter(c => c.id !== id);
    setActiveCarts(updated);
    
    // Recalculate index
    if (activeCartIndex >= updated.length) {
      setActiveCartIndex(updated.length - 1);
    }
  };

  const addItemToCart = (cartId: string, productId: string) => {
    triggerHaptic();
    const product = products.find(p => p.id === productId);
    if (!product) return;

    setActiveCarts(prev =>
      prev.map(cart => {
        if (cart.id !== cartId) return cart;

        // Check if item already exists in this cart
        const existingIdx = cart.items.findIndex(item => item.productId === productId);
        if (existingIdx > -1) {
          const item = cart.items[existingIdx];
          // Do not increment if locked
          if (item.isLocked) return cart;
          
          const updatedItems = [...cart.items];
          updatedItems[existingIdx] = {
            ...item,
            quantity: item.quantity + 1,
          };
          return { ...cart, items: updatedItems };
        } else {
          // Add new item
          const newItem: CartItem = {
            id: 'item-' + Date.now() + '-' + Math.random().toString(36).substr(2, 4),
            productId,
            quantity: 1,
            selectedTier: 'normal',
            isLocked: false,
          };
          return { ...cart, items: [...cart.items, newItem] };
        }
      })
    );
  };

  const updateCartItemQuantity = (cartId: string, itemId: string, qty: number) => {
    if (qty < 0) return;
    triggerHaptic();

    setActiveCarts(prev =>
      prev.map(cart => {
        if (cart.id !== cartId) return cart;

        // Find and check if locked
        const target = cart.items.find(i => i.id === itemId);
        if (target?.isLocked) return cart;

        if (qty === 0) {
          // Remove item
          return {
            ...cart,
            items: cart.items.filter(i => i.id !== itemId),
          };
        }

        return {
          ...cart,
          items: cart.items.map(item => (item.id === itemId ? { ...item, quantity: qty } : item)),
        };
      })
    );
  };

  const setProductQuantity = (cartId: string, productId: string, qty: number) => {
    if (qty < 0) return;
    triggerHaptic();

    setActiveCarts(prev =>
      prev.map(cart => {
        if (cart.id !== cartId) return cart;

        const existingIdx = cart.items.findIndex(item => item.productId === productId);
        if (existingIdx > -1) {
          const item = cart.items[existingIdx];
          if (item.isLocked) return cart;

          if (qty === 0) {
            return {
              ...cart,
              items: cart.items.filter(i => i.productId !== productId),
            };
          }

          const updatedItems = [...cart.items];
          updatedItems[existingIdx] = {
            ...item,
            quantity: qty,
          };
          return { ...cart, items: updatedItems };
        } else {
          if (qty === 0) return cart;

          const newItem: CartItem = {
            id: 'item-' + Date.now() + '-' + Math.random().toString(36).substring(2, 6),
            productId,
            quantity: qty,
            selectedTier: 'normal',
            isLocked: false,
          };
          return { ...cart, items: [...cart.items, newItem] };
        }
      })
    );
  };

  const updateCartItemTier = (cartId: string, itemId: string, tier: PriceTier, customPrice?: number) => {
    triggerHaptic();
    setActiveCarts(prev =>
      prev.map(cart => {
        if (cart.id !== cartId) return cart;

        const target = cart.items.find(i => i.id === itemId);
        if (target?.isLocked) return cart;

        return {
          ...cart,
          items: cart.items.map(item =>
            item.id === itemId
              ? { ...item, selectedTier: tier, customPrice: customPrice !== undefined ? customPrice : item.customPrice }
              : item
          ),
        };
      })
    );
  };

  const toggleCartItemLock = (cartId: string, itemId: string) => {
    triggerHaptic();
    setActiveCarts(prev =>
      prev.map(cart => {
        if (cart.id !== cartId) return cart;
        return {
          ...cart,
          items: cart.items.map(item => (item.id === itemId ? { ...item, isLocked: !item.isLocked } : item)),
        };
      })
    );
  };

  // Checkout process - stores inside the current session transactions
  const checkoutCart = (cartId: string, currencyCode: string): Transaction | null => {
    triggerHaptic();
    if (!currentSession) {
      alert('Error: Debes abrir una Sesión de Venta para procesar el cobro.');
      return null;
    }

    const cart = activeCarts.find(c => c.id === cartId);
    if (!cart || cart.items.length === 0) return null;

    const currency = currencies.find(c => c.code === currencyCode) || currencies[0];
    
    // Build Transaction details
    let totalCUP = 0;
    const transactionItems: TransactionItem[] = [];

    for (const item of cart.items) {
      const product = products.find(p => p.id === item.productId);
      if (!product) continue;

      let itemPrice = product.prices.normal;
      if (item.selectedTier === 'mayorista' && product.prices.mayorista !== undefined) {
        itemPrice = product.prices.mayorista;
      } else if (item.selectedTier === 'oferta' && product.prices.oferta !== undefined) {
        itemPrice = product.prices.oferta;
      } else if (item.selectedTier === 'personalizado' && item.customPrice !== undefined) {
        itemPrice = item.customPrice;
      }

      const subtotal = itemPrice * item.quantity;
      totalCUP += subtotal;

      transactionItems.push({
        name: product.name,
        emoji: product.emoji,
        quantity: item.quantity,
        unit: product.unit,
        price: itemPrice,
        subtotal,
      });
    }

    const paymentAmount = totalCUP / currency.rateToBase;
    const newTransaction: Transaction = {
      id: 'tx-' + Date.now(),
      sessionName: currentSession.name,
      cartNumber: cart.number,
      items: transactionItems,
      totalCUP,
      paymentCurrency: currency.code,
      paymentAmount,
      exchangeRateUsed: currency.rateToBase,
      timestamp: Date.now(),
    };

    // Store transaction inside the session
    const updatedSession: Session = {
      ...currentSession,
      transactions: [...currentSession.transactions, newTransaction],
    };

    const updatedSessions = sessions.map(s => (s.id === currentSession.id ? updatedSession : s));
    setSessions(updatedSessions);
    setCurrentSession(updatedSession);
    localDb.saveSessions(updatedSessions);

    // Remove cart, create new empty one if empty, reset index
    const remainingCarts = activeCarts.filter(c => c.id !== cartId);
    if (remainingCarts.length === 0) {
      const resetCart: Cart = {
        id: 'cart-' + Date.now(),
        number: 1,
        color: 'sky',
        items: [],
        createdTime: Date.now(),
      };
      setActiveCarts([resetCart]);
      setActiveCartIndex(0);
    } else {
      setActiveCarts(remainingCarts);
      setActiveCartIndex(0);
    }

    return newTransaction;
  };

  // Backup restore Action
  const restoreBackup = (backup: POSDataBackup): boolean => {
    const success = localDb.importBackup(backup);
    if (success) {
      setProducts(localDb.getProducts());
      const loadedSessions = localDb.getSessions();
      setSessions(loadedSessions);
      setCurrencies(localDb.getCurrencies());
      setSettings(localDb.getSettings());
      
      const openSess = loadedSessions.find(s => s.status === 'open');
      setCurrentSession(openSess || null);
      
      // Empty current active carts on reset to avoid stale IDs
      const defaultCart: Cart = {
        id: 'cart-' + Date.now(),
        number: 1,
        color: 'sky',
        items: [],
        createdTime: Date.now(),
      };
      setActiveCarts([defaultCart]);
      setActiveCartIndex(0);
      return true;
    }
    return false;
  };

  return (
    <POSContext.Provider
      value={{
        products,
        sessions,
        currencies,
        settings,
        activeCarts,
        activeCartIndex,
        currentSession,
        isOnline,
        openSession,
        closeSession,
        addProduct,
        updateProduct,
        deleteProduct,
        updateCurrencyRate,
        addCustomCurrency,
        deleteCustomCurrency,
        updateSettings,
        createCart,
        deleteCart,
        addItemToCart,
        updateCartItemQuantity,
        setProductQuantity,
        updateCartItemTier,
        toggleCartItemLock,
        setActiveCartIndex,
        checkoutCart,
        restoreBackup,
      }}
    >
      {children}
    </POSContext.Provider>
  );
};

export const usePOS = () => {
  const context = useContext(POSContext);
  if (!context) {
    throw new Error('usePOS must be used within a POSProvider');
  }
  return context;
};

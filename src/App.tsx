/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useRef, useEffect } from 'react';
import { POSProvider, usePOS } from './context/POSContext';
import { GoogleDriveBackup } from './components/GoogleDriveBackup';
import { OfflineIndicator } from './components/OfflineIndicator';
import { PWAInstallButton } from './components/PWAInstallButton';
import { 
  ShoppingBag, 
  Layers, 
  Coins, 
  Settings as SettingsIcon, 
  Plus, 
  Trash2, 
  Lock, 
  ChevronRight, 
  PlusCircle, 
  MinusCircle, 
  X, 
  DollarSign, 
  Calendar, 
  Check, 
  ArrowLeft, 
  MoreVertical, 
  BarChart3, 
  History, 
  LogOut,
  FolderOpen
} from 'lucide-react';
import { PriceTier, Product, Cart } from './types/pos';

function MainAppContent() {
  const {
    products,
    sessions,
    currencies,
    settings,
    activeCarts,
    activeCartIndex,
    currentSession,
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
  } = usePOS();

  // Navigation tabs (defaults to 'sessions' overview)
  const [activeTab, setActiveTab] = useState<'pos' | 'catalog' | 'sessions' | 'settings'>('sessions');

  // Keypad & Resizable Layout states
  const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
  const [keypadInput, setKeypadInput] = useState<string>('');
  const [isFirstKey, setIsFirstKey] = useState<boolean>(true);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [keyboardHeight, setKeyboardHeight] = useState<number>(() => {
    return Number(localStorage.getItem('milypico_keyboard_height') || '280');
  });

  // Save keyboard height to localStorage
  useEffect(() => {
    localStorage.setItem('milypico_keyboard_height', keyboardHeight.toString());
  }, [keyboardHeight]);

  // Synchronize keypad state when the selected product or active cart changes
  useEffect(() => {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    if (selectedProductId && currentCart) {
      const existingItem = currentCart.items.find(item => item.productId === selectedProductId);
      const currentQty = existingItem ? existingItem.quantity : 0;
      setKeypadInput(currentQty > 0 ? currentQty.toString() : '');
      setIsFirstKey(true);
    } else {
      setKeypadInput('');
      setIsFirstKey(true);
    }
  }, [selectedProductId, activeCartIndex]);

  // Automatically select the first product on entering the POS screen if none selected
  useEffect(() => {
    if (activeTab === 'pos' && !selectedProductId && products.length > 0) {
      setSelectedProductId(products[0].id);
    }
  }, [activeTab, products, selectedProductId]);

  // Simple, elegant, non-blocking toast state
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'info' | 'error' } | null>(null);

  // Helper to show non-blocking toast
  const showToast = (message: string, type: 'success' | 'info' | 'error' = 'success') => {
    setToast({ message, type });
  };

  // Auto-dismiss toast
  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => setToast(null), 1800);
      return () => clearTimeout(timer);
    }
  }, [toast]);

  // Contextual menu dropdown and modals for session options
  const [showSessionMenu, setShowSessionMenu] = useState(false);
  const [showMetricsModal, setShowMetricsModal] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);

  // Transition to sales screen when a session is active and empty
  useEffect(() => {
    if (currentSession && activeTab === 'sessions' && currentSession.transactions.length === 0) {
      setActiveTab('pos');
    }
  }, [currentSession]);

  // Keypad actions & adjustments helpers
  const handleKeypadPress = (key: string) => {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    if (!selectedProductId || !currentCart) return;

    // Find if the item is locked
    const existingItem = currentCart.items.find(item => item.productId === selectedProductId);
    if (existingItem?.isLocked) {
      showToast('Este producto está bloqueado y no se puede editar', 'error');
      return;
    }

    let nextInput = keypadInput;

    if (key === 'C') {
      nextInput = '';
      setKeypadInput('');
      setIsFirstKey(true);
      setProductQuantity(currentCart.id, selectedProductId, 0);
      return;
    }

    if (key === '⌫') {
      if (keypadInput.length > 0) {
        nextInput = keypadInput.slice(0, -1);
        setKeypadInput(nextInput);
        const parsed = parseFloat(nextInput);
        setProductQuantity(currentCart.id, selectedProductId, isNaN(parsed) ? 0 : parsed);
      } else {
        setProductQuantity(currentCart.id, selectedProductId, 0);
      }
      return;
    }

    if (isFirstKey) {
      if (key === '.') {
        nextInput = '0.';
      } else {
        nextInput = key;
      }
      setIsFirstKey(false);
    } else {
      if (key === '.' && keypadInput.includes('.')) {
        return; // Prevent multiple decimals
      }
      nextInput = keypadInput + key;
    }

    setKeypadInput(nextInput);
    const parsedValue = parseFloat(nextInput);
    if (!isNaN(parsedValue)) {
      setProductQuantity(currentCart.id, selectedProductId, parsedValue);
    }
  };

  const handleQuickIncrement = (step: number) => {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    if (!selectedProductId || !currentCart) return;

    const existingItem = currentCart.items.find(item => item.productId === selectedProductId);
    if (existingItem?.isLocked) {
      showToast('Este producto está bloqueado y no se puede editar', 'error');
      return;
    }

    const currentQty = existingItem ? existingItem.quantity : 0;
    const nextQty = Math.max(0, currentQty + step);

    setProductQuantity(currentCart.id, selectedProductId, nextQty);
    setKeypadInput(nextQty > 0 ? nextQty.toString() : '');
    setIsFirstKey(true);
  };

  const handleToggleSelectedLock = () => {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    if (!selectedProductId || !currentCart) return;
    const existingItem = currentCart.items.find(item => item.productId === selectedProductId);
    if (existingItem) {
      toggleCartItemLock(currentCart.id, existingItem.id);
      showToast(existingItem.isLocked ? 'Línea desbloqueada' : 'Línea bloqueada', 'info');
    } else {
      showToast('El producto no está en el carrito para bloquearlo', 'error');
    }
  };

  const handleOpenSelectedPricingModal = () => {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    if (!selectedProductId || !currentCart) return;
    const existingItem = currentCart.items.find(item => item.productId === selectedProductId);
    if (existingItem) {
      setPricingModalItem({ cartId: currentCart.id, itemId: existingItem.id });
    } else {
      showToast('El producto no está en el carrito para cambiar su precio', 'error');
    }
  };

  // Checkout modal state
  const [checkoutCartItem, setCheckoutCartItem] = useState<Cart | null>(null);
  const [paymentCurrency, setPaymentCurrency] = useState<string>('CUP');
  const [receivedAmount, setReceivedAmount] = useState<string>('');

  // Contextual pricing modal state (Replaces inline selects)
  const [pricingModalItem, setPricingModalItem] = useState<{ cartId: string; itemId: string } | null>(null);

  // Forms / Catalog addition state
  const [newProdName, setNewProdName] = useState('');
  const [newProdEmoji, setNewProdEmoji] = useState('🍎');
  const [newProdUnit, setNewProdUnit] = useState<'u' | 'lb'>('u');
  const [newProdNormalPrice, setNewProdNormalPrice] = useState('');
  const [newProdWholesalePrice, setNewProdWholesalePrice] = useState('');
  const [newProdDiscountPrice, setNewProdDiscountPrice] = useState('');
  const [newProdCategory, setNewProdCategory] = useState('Gastronomía');

  // Custom Currency state
  const [newCurrCode, setNewCurrCode] = useState('');
  const [newCurrName, setNewCurrName] = useState('');
  const [newCurrSymbol, setNewCurrSymbol] = useState('');
  const [newCurrRate, setNewCurrRate] = useState('');

  // Active Category filter for POS product list
  const [posCategoryFilter, setPosCategoryFilter] = useState<string>('All');

  // CSS snap scrolling reference for multiple carts
  const carouselRef = useRef<HTMLDivElement>(null);

  const isLight = settings.theme === 'light';

  // Synchronize document dark class with settings theme
  useEffect(() => {
    if (settings.theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [settings.theme]);

  // Consistent High-Contrast Aesthetic: Mirroring Light & Inverted Dark Style (Borders, corners, shape are identical)
  const s = {
    bg: isLight ? 'bg-white text-black' : 'bg-neutral-950 text-neutral-100',
    header: isLight ? 'bg-white border-b-2 border-black text-black' : 'bg-neutral-950 border-b-2 border-neutral-100 text-neutral-100',
    footer: isLight ? 'bg-white border-t-2 border-black text-black' : 'bg-neutral-950 border-t-2 border-neutral-100 text-neutral-100',
    card: isLight 
      ? 'bg-white border-2 border-black rounded-lg text-black shadow-none' 
      : 'bg-neutral-950 border-2 border-neutral-100 rounded-lg text-neutral-100 shadow-none',
    cardInner: isLight 
      ? 'bg-white border border-black rounded-md text-black' 
      : 'bg-neutral-950 border border-neutral-100 rounded-md text-neutral-100',
    input: isLight 
      ? 'bg-white border-2 border-black text-black placeholder-zinc-500 rounded-lg focus:outline-none focus:ring-1 focus:ring-black font-extrabold' 
      : 'bg-neutral-950 border-2 border-neutral-100 text-neutral-100 placeholder-neutral-500 rounded-lg focus:outline-none focus:ring-1 focus:ring-neutral-100 font-extrabold',
    select: isLight 
      ? 'bg-white border-2 border-black text-black focus:outline-none focus:ring-1 focus:ring-black rounded-lg font-extrabold' 
      : 'bg-neutral-950 border-2 border-neutral-100 text-neutral-100 focus:outline-none focus:ring-1 focus:ring-neutral-100 rounded-lg font-extrabold',
    
    // Rounded pill / card shape buttons
    btnPrimary: isLight 
      ? 'bg-black hover:bg-neutral-900 text-white font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-black' 
      : 'bg-white hover:bg-neutral-100 text-black font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-neutral-100',
    btnSecondary: isLight 
      ? 'bg-white hover:bg-neutral-100 text-black font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-black' 
      : 'bg-neutral-950 hover:bg-neutral-900 text-white font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-neutral-100',
    btnSuccess: isLight 
      ? 'bg-black hover:bg-neutral-900 text-white font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-black' 
      : 'bg-white hover:bg-neutral-100 text-black font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-neutral-100',
    btnDanger: isLight 
      ? 'bg-white hover:bg-red-50 text-red-600 font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-red-600' 
      : 'bg-neutral-950 hover:bg-neutral-900 text-red-500 font-black rounded-lg active:scale-95 transition-all cursor-pointer border-2 border-red-500',
    
    // Badges
    badgeOpen: isLight 
      ? 'bg-black text-white font-black rounded-md border-2 border-black px-3 py-1 text-xs' 
      : 'bg-white text-black font-black rounded-md border-2 border-neutral-100 px-3 py-1 text-xs',
    badgeClosed: isLight 
      ? 'bg-white text-black font-black rounded-md border-2 border-black px-3 py-1 text-xs' 
      : 'bg-neutral-950 text-neutral-100 font-black rounded-md border-2 border-neutral-100 px-3 py-1 text-xs',
    badgeCaja: isLight 
      ? 'bg-white border-2 border-black text-black font-black rounded-lg px-3 py-1 text-xs' 
      : 'bg-neutral-950 border-2 border-neutral-100 text-neutral-100 font-black rounded-lg px-3 py-1 text-xs',
    
    // Text styles
    textTitle: isLight ? 'text-black font-black' : 'text-white font-black',
    textMuted: isLight ? 'text-zinc-600 font-bold' : 'text-neutral-400 font-bold',
    textSub: isLight ? 'text-zinc-800 font-black text-[10px]' : 'text-neutral-400 font-black text-[10px]',
    textPrice: isLight ? 'text-black font-black' : 'text-white font-black',
    divider: isLight ? 'border-black' : 'border-neutral-100',
    modal: isLight ? 'bg-white border-2 border-black rounded-lg text-black shadow-none' : 'bg-neutral-950 border-2 border-neutral-100 rounded-lg text-white shadow-none',
  };

  // Synchronize carousel slide index with state
  const handleCarouselScroll = () => {
    if (!carouselRef.current) return;
    const scrollLeft = carouselRef.current.scrollLeft;
    const width = carouselRef.current.offsetWidth;
    const newIdx = Math.round(scrollLeft / (width || 1));
    if (newIdx >= 0 && newIdx < activeCarts.length && newIdx !== activeCartIndex) {
      setActiveCartIndex(newIdx);
    }
  };

  // Scroll to selected cart when index changes externally
  useEffect(() => {
    if (carouselRef.current && activeCarts.length > 0) {
      const container = carouselRef.current;
      const targetElement = container.children[activeCartIndex] as HTMLElement;
      if (targetElement) {
        container.scrollTo({
          left: targetElement.offsetLeft - container.offsetLeft,
          behavior: 'smooth',
        });
      }
    }
  }, [activeCartIndex]);

  // Automatically pre-fill received amount in checkout dialog with the exact total
  useEffect(() => {
    if (checkoutCartItem) {
      const totalCUP = calculateCartTotal(checkoutCartItem);
      const activeCurr = currencies.find(c => c.code === paymentCurrency) || currencies[0];
      const convertedTotal = totalCUP / activeCurr.rateToBase;
      setReceivedAmount(convertedTotal.toFixed(2));
    } else {
      setReceivedAmount('');
    }
  }, [checkoutCartItem, paymentCurrency]);

  // Total calculation for a specific cart
  const calculateCartTotal = (cart: Cart) => {
    let total = 0;
    cart.items.forEach(item => {
      const p = products.find(prod => prod.id === item.productId);
      if (!p) return;
      
      let price = p.prices.normal;
      if (item.selectedTier === 'mayorista' && p.prices.mayorista !== undefined) {
        price = p.prices.mayorista;
      } else if (item.selectedTier === 'oferta' && p.prices.oferta !== undefined) {
        price = p.prices.oferta;
      } else if (item.selectedTier === 'personalizado' && item.customPrice !== undefined) {
        price = item.customPrice;
      }
      
      total += price * item.quantity;
    });
    return total;
  };

  const categories = ['All', ...Array.from(new Set(products.map(p => p.category || 'Otros')))];
  const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
  const totalSessionSales = currentSession ? currentSession.transactions.reduce((acc, tx) => acc + tx.totalCUP, 0) : 0;

  const handleItemGesture = (cartId: string, itemId: string) => {
    toggleCartItemLock(cartId, itemId);
    showToast('Línea bloqueada/desbloqueada', 'info');
  };

  const executeCheckout = () => {
    if (!checkoutCartItem) return;
    const tx = checkoutCart(checkoutCartItem.id, paymentCurrency);
    if (tx) {
      setCheckoutCartItem(null);
      setReceivedAmount('');
      setPaymentCurrency('CUP');
      showToast(`Cobro registrado: $${tx.totalCUP.toLocaleString()} CUP`, 'success');
    }
  };

  const getThemeColors = (color: string) => {
    if (isLight) {
      return { 
        border: 'border-black', 
        bg: 'bg-white', 
        text: 'text-black', 
        banner: 'bg-black text-white border-b-2 border-black', 
        ring: 'ring-black' 
      };
    } else {
      return { 
        border: 'border-neutral-100', 
        bg: 'bg-neutral-950', 
        text: 'text-neutral-100', 
        banner: 'bg-white text-black border-b-2 border-neutral-100', 
        ring: 'ring-neutral-100' 
      };
    }
  };

  const handleToggleTheme = () => {
    updateSettings({ theme: isLight ? 'dark' : 'light' });
  };

  const isFullscreenPOS = activeTab === 'pos' && currentSession;

  // Renderers for modals to keep code DRY & easily mountable in the standalone screen layout
  const renderCheckoutModal = (cartToCheckout: Cart) => {
    const totalCUP = calculateCartTotal(cartToCheckout);
    const activeCurr = currencies.find(c => c.code === paymentCurrency) || currencies[0];
    const convertedTotal = totalCUP / activeCurr.rateToBase;
    const parsedReceived = Number(receivedAmount) || 0;
    
    let changeCUP = 0;
    let changeForeign = 0;
    if (parsedReceived > 0) {
      const diffCUP = (parsedReceived * activeCurr.rateToBase) - totalCUP;
      changeCUP = Math.max(0, diffCUP);
      changeForeign = Math.max(0, parsedReceived - convertedTotal);
    }

    return (
      <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-xs p-4">
        <div className={`w-full max-w-md p-6 space-y-4 pb-8 relative animate-slide-up ${s.modal}`}>
          
          <button
            onClick={() => {
              setCheckoutCartItem(null);
              setReceivedAmount('');
            }}
            className={`absolute top-4 right-4 p-1.5 rounded-lg border focus:outline-none ${
              isLight ? 'bg-white border-black text-black' : 'bg-neutral-950 border-neutral-100 text-white'
            }`}
          >
            <X className="h-4.5 w-4.5" />
          </button>

          <div>
            <span className="block text-[10px] font-black uppercase tracking-wider opacity-60">Cliente #{cartToCheckout.number}</span>
            <h3 className="text-lg font-black flex items-center gap-1.5 uppercase mt-0.5">
              <DollarSign className="h-5.5 w-5.5 text-emerald-500" />
              <span>Cobrar Cuenta</span>
            </h3>
          </div>

          <div className={`p-4 rounded-lg border flex items-center justify-between text-center ${s.cardInner}`}>
            <div className="text-left">
              <span className="block text-[10px] font-black uppercase leading-none opacity-60">Total Cuenta (CUP):</span>
              <span className="block font-black text-xl mt-1.5 font-mono">${totalCUP.toLocaleString()} CUP</span>
            </div>
            {paymentCurrency !== 'CUP' && (
              <div className={`text-right border-l pl-4 flex-1 ${isLight ? 'border-black' : 'border-neutral-100'}`}>
                <span className="block text-[10px] font-black uppercase leading-none opacity-60">Cobrar {paymentCurrency}:</span>
                <span className="block font-black text-xl mt-1.5 font-mono">
                  {activeCurr.symbol} {convertedTotal.toFixed(2)}
                </span>
              </div>
            )}
          </div>

          <div className="space-y-1.5">
            <label className="block text-[10px] font-black uppercase">Divisa de cobro elegida:</label>
            <div className="grid grid-cols-4 gap-2">
              {currencies.map(curr => (
                <button
                  key={curr.code}
                  onClick={() => setPaymentCurrency(curr.code)}
                  className={`py-2 px-3 rounded-md font-black text-xs border text-center transition-all ${
                    paymentCurrency === curr.code
                      ? (isLight ? 'bg-black text-white border-black ring-1 ring-black' : 'bg-white text-black border-neutral-100 ring-1 ring-neutral-100')
                      : `${isLight ? 'bg-white border-black text-black' : 'bg-neutral-950 border-neutral-100 text-neutral-100'}`
                  }`}
                >
                  {curr.code}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="block text-[10px] font-black uppercase">Importe recibido ({paymentCurrency}):</label>
            <div className="relative">
              <input
                type="number"
                placeholder="Monto entregado por el cliente"
                value={receivedAmount}
                onChange={(e) => setReceivedAmount(e.target.value)}
                className={`w-full py-3.5 px-4 text-xl pl-10 focus:outline-none focus:ring-1 ${s.input}`}
                autoFocus
              />
              <div className="absolute left-4 top-1/2 -translate-y-1/2 text-neutral-400 font-extrabold text-lg">
                {activeCurr.symbol}
              </div>
            </div>
          </div>

          {parsedReceived > 0 && (
            <div className={`p-3.5 rounded-lg border grid grid-cols-2 gap-4 text-xs ${s.cardInner}`}>
              <div>
                <span className="block text-[9px] font-black uppercase opacity-65">Cambio ({paymentCurrency}):</span>
                <span className="font-black text-emerald-600 dark:text-emerald-400 text-sm mt-1 block font-mono">
                  {activeCurr.symbol} {changeForeign.toFixed(2)} {paymentCurrency}
                </span>
              </div>
              <div>
                <span className="block text-[9px] font-black uppercase opacity-65">Cambio equiv (CUP):</span>
                <span className="font-black text-sm mt-1 block font-mono">
                  ${changeCUP.toLocaleString()} CUP
                </span>
              </div>
            </div>
          )}

          <button
            onClick={executeCheckout}
            disabled={parsedReceived < convertedTotal && parsedReceived !== 0}
            className={`w-full py-4 text-sm font-black uppercase tracking-wider flex items-center justify-center gap-1 cursor-pointer ${s.btnSuccess} disabled:opacity-35`}
          >
            <Check className="h-5 w-5 shrink-0" />
            <span>Cobro Confirmado</span>
          </button>
        </div>
      </div>
    );
  };

  const renderPricingModal = () => {
    if (!pricingModalItem) return null;
    const cart = activeCarts.find(c => c.id === pricingModalItem.cartId);
    const item = cart?.items.find(i => i.id === pricingModalItem.itemId);
    const product = products.find(p => p.id === item?.productId);
    if (!cart || !item || !product) return null;

    const handleSelectTier = (tier: PriceTier, customPrice?: number) => {
      updateCartItemTier(cart.id, item.id, tier, customPrice);
      setPricingModalItem(null);
      showToast(`Precio cambiado a: ${tier}`, 'info');
    };

    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
        <div className={`w-full max-w-sm p-6 space-y-4 relative ${s.modal}`}>
          
          <button
            onClick={() => setPricingModalItem(null)}
            className={`absolute top-4 right-4 p-1.5 rounded-lg border focus:outline-none ${
              isLight ? 'bg-white border-black text-black' : 'bg-neutral-950 border-neutral-100 text-white'
            }`}
          >
            <X className="h-4 w-4" />
          </button>

          <div className="flex items-center gap-3">
            <span className="text-4xl" role="img">{product.emoji}</span>
            <div>
              <h4 className="text-base font-black leading-tight">{product.name}</h4>
              <span className="text-[10px] text-neutral-450 font-bold uppercase tracking-wider">Nivel de Precio</span>
            </div>
          </div>

          <div className="space-y-2 pt-2">
            <button
              onClick={() => handleSelectTier('normal')}
              className={`w-full p-3 rounded-lg border text-xs font-black flex items-center justify-between active:scale-[0.98] transition-all ${
                item.selectedTier === 'normal'
                  ? (isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-neutral-100')
                  : `${isLight ? 'bg-white hover:bg-zinc-100 text-black border-black' : 'bg-neutral-950 hover:bg-neutral-900 border-neutral-100 text-neutral-100'}`
              }`}
            >
              <span>Precio Normal</span>
              <span className="font-mono font-black">${product.prices.normal} CUP</span>
            </button>

            {product.prices.mayorista !== undefined && (
              <button
                onClick={() => handleSelectTier('mayorista')}
                className={`w-full p-3 rounded-lg border text-xs font-black flex items-center justify-between active:scale-[0.98] transition-all ${
                  item.selectedTier === 'mayorista'
                    ? (isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-neutral-100')
                    : `${isLight ? 'bg-white hover:bg-zinc-100 text-black border-black' : 'bg-neutral-950 hover:bg-neutral-900 border-neutral-100 text-neutral-100'}`
                }`}
              >
                <span>Precio Mayorista</span>
                <span className="font-mono font-black">${product.prices.mayorista} CUP</span>
              </button>
            )}

            {product.prices.oferta !== undefined && (
              <button
                onClick={() => handleSelectTier('oferta')}
                className={`w-full p-3 rounded-lg border text-xs font-black flex items-center justify-between active:scale-[0.98] transition-all ${
                  item.selectedTier === 'oferta'
                    ? (isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-neutral-100')
                    : `${isLight ? 'bg-white hover:bg-zinc-100 text-black border-black' : 'bg-neutral-950 hover:bg-neutral-900 border-neutral-100 text-neutral-100'}`
                }`}
              >
                <span>Precio Oferta</span>
                <span className="font-mono font-black">${product.prices.oferta} CUP</span>
              </button>
            )}

            <button
              onClick={() => {
                let currentVal = product.prices.normal;
                if (item.selectedTier === 'personalizado' && item.customPrice !== undefined) {
                  currentVal = item.customPrice;
                }
                const customVal = window.prompt('Ingresa el precio personalizado en CUP:', currentVal.toString());
                if (customVal && !isNaN(Number(customVal))) {
                  handleSelectTier('personalizado', Number(customVal));
                }
              }}
              className={`w-full p-3 rounded-lg border text-xs font-black flex items-center justify-between active:scale-[0.98] transition-all ${
                item.selectedTier === 'personalizado'
                  ? (isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-neutral-100')
                  : `${isLight ? 'bg-white hover:bg-zinc-100 text-black border-black' : 'bg-neutral-950 hover:bg-neutral-900 border-neutral-100 text-neutral-100'}`
              }`}
            >
              <span>Precio Personalizado</span>
              <span className="font-mono font-black">
                {item.selectedTier === 'personalizado' && item.customPrice !== undefined ? `$${item.customPrice} CUP` : 'Definir...'}
              </span>
            </button>
          </div>

          <div className="pt-2">
            <button
              onClick={() => setPricingModalItem(null)}
              className={`w-full py-3 text-xs font-black uppercase ${s.btnSecondary}`}
            >
              Cerrar
            </button>
          </div>
        </div>
      </div>
    );
  };

  // Standalone screen overlay for turn customer carts (prevents global margins, scrollbars, etc.)
  if (isFullscreenPOS) {
    const currentCart = activeCarts[activeCartIndex] || activeCarts[0];
    const selectedProduct = products.find(p => p.id === selectedProductId);
    const selectedItemInCart = currentCart?.items.find(i => i.productId === selectedProductId);

    // Pointer events for dragging splitter
    const handlePointerDown = (e: React.PointerEvent) => {
      setIsDragging(true);
      e.currentTarget.setPointerCapture(e.pointerId);
    };

    const handlePointerMove = (e: React.PointerEvent) => {
      if (!isDragging) return;
      const viewportHeight = window.innerHeight;
      const clientY = e.clientY;
      const newHeight = viewportHeight - clientY;
      // Constrain height (e.g., between 150px and 450px or 60% of viewport)
      if (newHeight >= 160 && newHeight <= viewportHeight * 0.65) {
        setKeyboardHeight(newHeight);
      }
    };

    const handlePointerUp = (e: React.PointerEvent) => {
      setIsDragging(false);
      e.currentTarget.releasePointerCapture(e.pointerId);
    };

    return (
      <div className={`fixed inset-0 w-full h-[100dvh] flex flex-col overflow-hidden px-3 py-2 z-50 ${s.bg}`}>
        
        {/* ROW 1: Transparent height-free top row header */}
        <div className="h-12 flex items-center justify-between shrink-0 bg-transparent select-none z-40">
          <button 
            onClick={() => setActiveTab('sessions')}
            className={`p-2 rounded-full border-2 flex items-center justify-center shadow-none active:scale-95 transition-all pointer-events-auto ${
              isLight ? 'bg-white border-black text-black hover:bg-zinc-100' : 'bg-neutral-950 border-neutral-100 text-white hover:bg-neutral-900'
            }`}
            title="Volver"
          >
            <ArrowLeft className="h-4.5 w-4.5" />
          </button>

          {/* Elegant category chips */}
          <div className="flex-1 px-3 overflow-x-auto scrollbar-none flex items-center justify-center">
            {products.length > 0 && (
              <div className="flex items-center gap-1">
                {categories.map(cat => (
                  <button
                    key={cat}
                    onClick={() => setPosCategoryFilter(cat)}
                    className={`px-2 py-0.5 rounded-md font-black border transition-all text-[9px] uppercase tracking-wider shrink-0 leading-none ${
                      posCategoryFilter === cat
                        ? 'bg-black text-white border-black'
                        : `${isLight ? 'bg-white border-black text-black' : 'bg-neutral-950 border-neutral-100 text-neutral-100 hover:bg-neutral-900'}`
                    }`}
                  >
                    {cat}
                  </button>
                ))}
              </div>
            )}
          </div>

          <button
            onClick={createCart}
            className={`p-2 rounded-full border-2 flex items-center justify-center pointer-events-auto ${
              isLight ? 'bg-white border-black text-black hover:bg-zinc-100' : 'bg-neutral-950 text-neutral-100 border-neutral-100 hover:bg-neutral-900'
            }`}
            title="Añadir Cliente"
          >
            <Plus className="h-4.5 w-4.5" />
          </button>
        </div>

        {/* UPPER PANEL: Flex column containing carts list + product grid */}
        <div className="flex-1 min-h-0 flex flex-col pt-1" style={{ height: `calc(100% - ${keyboardHeight + 8}px)` }}>
          
          {/* HORIZONTAL CARTS LIST */}
          <div className="shrink-0 flex items-center gap-1.5 overflow-x-auto py-1 scrollbar-none">
            {activeCarts.map((cart, idx) => {
              const isSelected = idx === activeCartIndex;
              const totalCUP = calculateCartTotal(cart);
              return (
                <div
                  key={cart.id}
                  onClick={() => setActiveCartIndex(idx)}
                  className={`p-2 shrink-0 rounded-lg border-2 flex items-center justify-between gap-3 cursor-pointer min-w-[120px] transition-all ${
                    isSelected
                      ? (isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-neutral-100')
                      : (isLight ? 'bg-white border-zinc-350 hover:bg-zinc-50 text-black' : 'bg-neutral-950 border-neutral-850 hover:bg-neutral-900 text-neutral-100')
                  }`}
                >
                  <div className="space-y-0.5 select-none">
                    <span className="block font-black text-[10px] uppercase tracking-wider">Cliente #{cart.number}</span>
                    <span className="block font-mono font-black text-xs">${totalCUP.toLocaleString()} CUP</span>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      deleteCart(cart.id);
                    }}
                    className={`p-1 rounded transition-colors ${
                      isSelected
                        ? 'hover:bg-white/10 text-current'
                        : 'hover:bg-black/5 dark:hover:bg-white/5 text-current'
                    }`}
                    title="Cerrar Carrito"
                  >
                    <Trash2 className="h-3 w-3" />
                  </button>
                </div>
              );
            })}
          </div>

          {/* PRODUCT GRID */}
          <div className="flex-1 min-h-0 overflow-y-auto mt-2 pb-2">
            {products.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-6 text-neutral-400 space-y-2">
                <span className="text-4xl">🍎</span>
                <p className="text-sm font-black leading-tight text-current">No hay productos en el catálogo</p>
                <p className="text-xs max-w-[200px] leading-relaxed">Agrega productos en la pestaña de catálogo para comenzar.</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 select-none">
                {products
                  .filter(p => posCategoryFilter === 'All' || p.category === posCategoryFilter)
                  .map(p => {
                    const itemInCart = currentCart?.items.find(i => i.productId === p.id);
                    const isAdded = itemInCart && itemInCart.quantity > 0;
                    const isSelected = selectedProductId === p.id;

                    let activePrice = p.prices.normal;
                    if (itemInCart) {
                      if (itemInCart.selectedTier === 'mayorista' && p.prices.mayorista !== undefined) {
                        activePrice = p.prices.mayorista;
                      } else if (itemInCart.selectedTier === 'oferta' && p.prices.oferta !== undefined) {
                        activePrice = p.prices.oferta;
                      } else if (itemInCart.selectedTier === 'personalizado' && itemInCart.customPrice !== undefined) {
                        activePrice = itemInCart.customPrice;
                      }
                    }

                    return (
                      <div
                        key={p.id}
                        onClick={() => setSelectedProductId(p.id)}
                        onDoubleClick={() => {
                          if (itemInCart) {
                            toggleCartItemLock(currentCart.id, itemInCart.id);
                            showToast(itemInCart.isLocked ? 'Línea desbloqueada' : 'Línea bloqueada', 'info');
                          } else {
                            showToast('El producto no está en el carrito para bloquearlo', 'error');
                          }
                        }}
                        className={`p-2.5 rounded-lg border-2 transition-all cursor-pointer flex flex-col relative select-none ${
                          isAdded
                            ? (isLight 
                                ? 'bg-emerald-50/50 border-black text-black' 
                                : 'bg-neutral-900 border-neutral-100 text-white')
                            : (isLight 
                                ? 'bg-white border-zinc-250 hover:bg-zinc-50 text-black' 
                                : 'bg-neutral-950 border-neutral-850 hover:bg-neutral-900 text-neutral-350')
                        } ${
                          isSelected
                            ? 'ring-2 ring-blue-500 ring-offset-2 dark:ring-offset-neutral-950 scale-[0.99]'
                            : ''
                        }`}
                      >
                        {/* Upper row of product card: Emoji & pricing gear/tier indicator */}
                        <div className="flex items-center justify-between">
                          <span className="text-3xl" role="img">{p.emoji}</span>
                          <div className="flex items-center gap-1">
                            {isAdded && (
                              <>
                                {itemInCart.isLocked && <Lock className="h-3 w-3 text-red-550 shrink-0" />}
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    setPricingModalItem({ cartId: currentCart.id, itemId: itemInCart.id });
                                  }}
                                  className={`p-1 rounded border text-[9px] font-black uppercase flex items-center justify-center leading-none ${
                                    isLight ? 'bg-white border-black text-black hover:bg-zinc-100' : 'bg-neutral-950 border-neutral-100 text-white hover:bg-neutral-800'
                                  }`}
                                  title="Editar precio/nivel"
                                >
                                  $
                                </button>
                              </>
                            )}
                          </div>
                        </div>

                        {/* Middle: Title and pricing */}
                        <div className="mt-2 truncate flex-1">
                          <span className="block font-black text-xs leading-tight truncate">{p.name}</span>
                          <span className="text-[10px] font-black text-emerald-600 dark:text-emerald-400 block leading-none font-mono mt-0.5">
                            ${activePrice} CUP
                          </span>
                        </div>

                        {/* Lower: Quantity badges */}
                        {isAdded && (
                          <div className="mt-1.5 flex items-center justify-between">
                            <span className="text-[8px] font-bold uppercase text-slate-500">
                              {itemInCart.selectedTier}
                            </span>
                            <span className={`px-1.5 py-0.5 rounded text-[10px] font-black font-mono leading-none ${
                              isLight ? 'bg-black text-white' : 'bg-white text-black'
                            }`}>
                              x{itemInCart.quantity} {p.unit}
                            </span>
                          </div>
                        )}
                      </div>
                    );
                  })}
              </div>
            )}
          </div>
        </div>

        {/* RESIZABLE DIVIDER BAR */}
        <div
          onPointerDown={handlePointerDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          className="h-2 shrink-0 bg-neutral-200 dark:bg-neutral-800 hover:bg-neutral-350 dark:hover:bg-neutral-700 cursor-row-resize flex items-center justify-center transition-colors touch-none select-none z-30"
        >
          <div className="w-12 h-1 bg-neutral-400 dark:bg-neutral-600 rounded-full" />
        </div>

        {/* PERSISTENT NUMERIC KEYBOARD */}
        <div 
          className="shrink-0 flex flex-col select-none" 
          style={{ height: `${keyboardHeight}px` }}
        >
          {/* Keyboard Header: Display what is being typed */}
          <div className={`p-1.5 border border-dashed rounded-lg flex items-center justify-between shrink-0 mb-1.5 text-xs font-black ${
            isLight ? 'bg-neutral-50 border-neutral-300 text-black' : 'bg-neutral-900 border-neutral-800 text-white'
          }`}>
            <span className="truncate flex items-center gap-1 uppercase tracking-wider select-none text-[10px]">
              {selectedProduct ? (
                <>
                  <span className="text-base leading-none shrink-0">{selectedProduct.emoji}</span>
                  <span>{selectedProduct.name}</span>
                </>
              ) : (
                <span className="text-neutral-500">Seleccione un producto</span>
              )}
            </span>
            <div className="flex items-center gap-1">
              <span className="text-[10px] text-neutral-500 uppercase">CANTIDAD:</span>
              <span className="font-mono text-sm px-2 py-0.5 rounded bg-black text-white dark:bg-white dark:text-black">
                {keypadInput || '0'} {selectedProduct?.unit}
              </span>
            </div>
          </div>

          {/* Core Keypad grid */}
          <div className="flex-1 grid grid-cols-5 gap-1 select-none">
            {/* Digits 7, 8, 9, 4, 5, 6, 1, 2, 3, C, 0, . (Columns 1-3) */}
            <div className="col-span-3 grid grid-cols-3 gap-1 h-full">
              {['7', '8', '9', '4', '5', '6', '1', '2', '3', 'C', '0', '.'].map(key => {
                const isClear = key === 'C';
                const buttonStyles = isClear 
                  ? (isLight ? 'bg-red-50 text-red-600 hover:bg-red-100 border-red-300' : 'bg-red-950/40 text-red-400 hover:bg-red-950/60 border-red-900')
                  : (isLight ? 'bg-white text-black hover:bg-zinc-100 border-black' : 'bg-neutral-950 text-white hover:bg-neutral-900 border-neutral-800');
                
                return (
                  <button
                    key={key}
                    onClick={() => handleKeypadPress(key)}
                    className={`rounded-lg border-2 font-black text-base flex items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none ${buttonStyles}`}
                  >
                    {key}
                  </button>
                );
              })}
            </div>

            {/* Quick Increment Column (Column 4) */}
            <div className="col-span-1 grid grid-rows-4 gap-1 h-full">
              {[
                { label: '+1.0', step: 1.0 },
                { label: '+0.5', step: 0.5 },
                { label: '-1.0', step: -1.0 },
                { label: '-0.5', step: -0.5 }
              ].map(inc => (
                <button
                  key={inc.label}
                  onClick={() => handleQuickIncrement(inc.step)}
                  className={`rounded-lg border-2 font-black text-xs flex items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none ${
                    isLight 
                      ? 'bg-neutral-50 text-neutral-800 border-black hover:bg-zinc-150' 
                      : 'bg-neutral-900 text-neutral-200 border-neutral-800 hover:bg-neutral-800'
                  }`}
                >
                  {inc.label}
                </button>
              ))}
            </div>

            {/* Operations Column (Column 5) */}
            <div className="col-span-1 grid grid-rows-4 gap-1 h-full">
              <button
                onClick={() => handleKeypadPress('⌫')}
                className={`rounded-lg border-2 font-black text-xs flex items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none ${
                  isLight ? 'bg-white text-black border-black hover:bg-zinc-100' : 'bg-neutral-950 text-white border-neutral-800 hover:bg-neutral-900'
                }`}
                title="Backspace"
              >
                ⌫
              </button>
              <button
                onClick={handleOpenSelectedPricingModal}
                className={`rounded-lg border-2 font-black text-[10px] flex items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none uppercase ${
                  isLight ? 'bg-white text-black border-black hover:bg-zinc-100' : 'bg-neutral-950 text-white border-neutral-800 hover:bg-neutral-900'
                }`}
              >
                Precio
              </button>
              <button
                onClick={handleToggleSelectedLock}
                className={`rounded-lg border-2 font-black text-[10px] flex items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none uppercase ${
                  isLight ? 'bg-white text-black border-black hover:bg-zinc-100' : 'bg-neutral-950 text-white border-neutral-800 hover:bg-neutral-900'
                }`}
              >
                {selectedItemInCart?.isLocked ? 'Abri' : 'Bloq'}
              </button>
              <button
                onClick={() => {
                  if (currentCart && currentCart.items.length > 0) {
                    setCheckoutCartItem(currentCart);
                    setPaymentCurrency('CUP');
                  } else {
                    showToast('El carrito está vacío para cobrar', 'error');
                  }
                }}
                disabled={!currentCart || currentCart.items.length === 0}
                className={`rounded-lg border-2 font-black text-[10px] flex flex-col items-center justify-center cursor-pointer transition-all active:scale-[0.96] shadow-none uppercase disabled:opacity-35 ${
                  isLight 
                    ? 'bg-emerald-500 hover:bg-emerald-600 text-white border-black' 
                    : 'bg-emerald-650 hover:bg-emerald-600 text-white border-emerald-550'
                }`}
              >
                <DollarSign className="h-4 w-4 shrink-0" />
                <span className="mt-0.5 leading-none">Cobrar</span>
              </button>
            </div>
          </div>
        </div>

        {/* MODAL MOUNT POINTS IN STANDALONE CONTAINER */}
        {checkoutCartItem && renderCheckoutModal(checkoutCartItem)}
        {pricingModalItem && renderPricingModal()}

      </div>
    );
  }

  return (
    <div className={`h-[100dvh] flex flex-col font-sans select-none overflow-hidden antialiased transition-colors duration-200 ${s.bg}`}>
      
      {/* FLOATING TOAST NOTIFIER */}
      {toast && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-55 pointer-events-none animate-bounce">
          <div className={`px-5 py-2.5 rounded-md text-xs font-black shadow-none border-2 border-black flex items-center gap-2 ${
            isLight ? 'bg-black text-white' : 'bg-neutral-950 text-white border-neutral-100'
          }`}>
            <span>✨</span>
            <span>{toast.message}</span>
          </div>
        </div>
      )}

      {/* HEADER SECTION (NO THEME TOGGLE, BADGE ONLY) */}
      <header className={`px-4 py-3 flex items-center justify-between shrink-0 ${s.header}`}>
        <div className="flex items-center gap-2">
          <span className="text-2xl" role="img" aria-label="Logo Milypico">⚡</span>
          <div>
            <h1 className="font-black text-lg tracking-tight leading-none uppercase">Milypico</h1>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {currentSession ? (
            <div className={s.badgeOpen}>
              <span>Turno: {currentSession.name}</span>
            </div>
          ) : (
            <div className={s.badgeClosed}>
              <span>Turno Cerrado</span>
            </div>
          )}
        </div>
      </header>

      {/* OFFLINE INDICATOR */}
      <OfflineIndicator />

      {/* MAIN CONTENT PORTAL (SCROLLS ENTIRELY INTERNALLY) */}
      <main className="flex-1 min-h-0 overflow-y-auto pb-20">
        {!currentSession ? (
          /* UNOPENED SESSION CONTAINER */
          <div className="flex-1 flex flex-col items-center justify-center px-6 py-12 max-w-md mx-auto text-center space-y-6">
            <div className={`${s.card} p-8 space-y-5 w-full`}>
              <div className={`mx-auto p-4 rounded-lg border-2 border-black w-16 h-16 flex items-center justify-center text-3xl ${
                isLight ? 'bg-white' : 'bg-neutral-950 border-neutral-100'
              }`}>
                💼
              </div>
              <div className="space-y-1">
                <h3 className="text-xl font-black uppercase">Comenzar Jornada</h3>
                <p className={`text-xs ${s.textMuted}`}>
                  Abre un Turno o Sesión de Venta para comenzar a despachar. El sistema generará el nombre automáticamente según la fecha del dispositivo en formato corto en español.
                </p>
              </div>

              <button
                onClick={openSession}
                className={`w-full py-4 text-sm font-black tracking-wider uppercase ${s.btnPrimary}`}
              >
                <Plus className="h-5 w-5 inline shrink-0 mr-1.5" />
                <span>ABRIR NUEVA SESIÓN</span>
              </button>
            </div>

            {sessions.length > 0 && (
              <div className="w-full space-y-2 text-left">
                <span className="block text-[10px] font-black uppercase tracking-wider text-neutral-450">Historial de Sesiones</span>
                <div className="space-y-2">
                  {sessions.slice(0, 3).map((sess) => {
                    const totalSales = sess.transactions.reduce((acc, t) => acc + t.totalCUP, 0);
                    return (
                      <div key={sess.id} className={`${s.cardInner} p-3 flex items-center justify-between text-xs`}>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-neutral-400" />
                          <div>
                            <span className="font-extrabold">{sess.name}</span>
                            <span className="block text-[9px] opacity-75">
                              {new Date(sess.createdTime).toLocaleDateString()}
                            </span>
                          </div>
                        </div>
                        <div className="text-right font-mono">
                          <span className="font-black text-xs block">${totalSales.toLocaleString()} CUP</span>
                          <span className="block text-[9px] opacity-75">{sess.transactions.length} ventas</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        ) : (
          /* ACTIVE TABS SWITCHER */
          <div className="flex-1 flex flex-col h-full">
            
            {/* CATALOG MODULE */}
            {activeTab === 'catalog' && (
              <div className="px-4 py-4 space-y-6 max-w-xl mx-auto w-full">
                
                <div className={`${s.card} p-6 space-y-4`}>
                  <h2 className="text-base font-black flex items-center gap-2 uppercase">
                    <span>Añadir Producto</span>
                  </h2>

                  <div className="grid grid-cols-2 gap-3 text-xs">
                    <div className="col-span-2 space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Nombre del Producto:</label>
                      <input
                        type="text"
                        placeholder="Ej. Hamburguesa Doble"
                        value={newProdName}
                        onChange={(e) => setNewProdName(e.target.value)}
                        className={`w-full px-3 py-2.5 ${s.input}`}
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Emoji:</label>
                      <input
                        type="text"
                        placeholder="Ej. 🍔"
                        maxLength={4}
                        value={newProdEmoji}
                        onChange={(e) => setNewProdEmoji(e.target.value)}
                        className={`w-full px-3 py-2.5 text-center text-lg ${s.input}`}
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Unidad de Venta:</label>
                      <select
                        value={newProdUnit}
                        onChange={(e) => setNewProdUnit(e.target.value as 'u' | 'lb')}
                        className={`w-full px-3 py-2.5 ${s.select}`}
                      >
                        <option value="u">Unidades (u)</option>
                        <option value="lb">Libras (lb)</option>
                      </select>
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Precio Normal (CUP):</label>
                      <input
                        type="number"
                        placeholder="Ej. 250"
                        value={newProdNormalPrice}
                        onChange={(e) => setNewProdNormalPrice(e.target.value)}
                        className={`w-full px-3 py-2.5 ${s.input}`}
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Precio Mayorista (Opcional):</label>
                      <input
                        type="number"
                        placeholder="Ej. 200"
                        value={newProdWholesalePrice}
                        onChange={(e) => setNewProdWholesalePrice(e.target.value)}
                        className={`w-full px-3 py-2.5 ${s.input}`}
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Precio Oferta (Opcional):</label>
                      <input
                        type="number"
                        placeholder="Ej. 220"
                        value={newProdDiscountPrice}
                        onChange={(e) => setNewProdDiscountPrice(e.target.value)}
                        className={`w-full px-3 py-2.5 ${s.input}`}
                      />
                    </div>

                    <div className="space-y-1">
                      <label className="block text-[10px] uppercase font-black text-slate-500">Categoría:</label>
                      <select
                        value={newProdCategory}
                        onChange={(e) => setNewProdCategory(e.target.value)}
                        className={`w-full px-3 py-2.5 ${s.select}`}
                      >
                        <option value="Gastronomía">Gastronomía</option>
                        <option value="Bebidas">Bebidas</option>
                        <option value="Cigarros">Cigarros</option>
                        <option value="Carnicería">Carnicería</option>
                        <option value="Víveres">Víveres</option>
                        <option value="Otros">Otros</option>
                      </select>
                    </div>
                  </div>

                  <button
                    onClick={() => {
                      if (!newProdName || !newProdNormalPrice) {
                        showToast('El nombre y el precio normal son obligatorios.', 'error');
                        return;
                      }
                      addProduct({
                        name: newProdName,
                        emoji: newProdEmoji || '🍎',
                        unit: newProdUnit,
                        prices: {
                          normal: Number(newProdNormalPrice),
                          ...(newProdWholesalePrice ? { mayorista: Number(newProdWholesalePrice) } : {}),
                          ...(newProdDiscountPrice ? { oferta: Number(newProdDiscountPrice) } : {}),
                        },
                        category: newProdCategory,
                      });
                      setNewProdName('');
                      setNewProdNormalPrice('');
                      setNewProdWholesalePrice('');
                      setNewProdDiscountPrice('');
                      showToast('¡Producto agregado!', 'success');
                    }}
                    className={`w-full py-3.5 text-xs font-black tracking-wider uppercase flex items-center justify-center gap-1.5 ${s.btnPrimary}`}
                  >
                    <Plus className="h-4.5 w-4.5" />
                    <span>GUARDAR PRODUCTO</span>
                  </button>
                </div>

                <div className="space-y-3">
                  <span className="block text-[10px] font-black uppercase text-neutral-400 tracking-wider">Productos en Catálogo ({products.length})</span>
                  
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {products.map(p => (
                      <div key={p.id} className={`${s.card} p-4 flex items-center justify-between`}>
                        <div className="flex items-center gap-3">
                          <span className="text-3xl shrink-0" role="img">{p.emoji}</span>
                          <div>
                            <span className="font-extrabold text-sm block leading-tight">{p.name}</span>
                            <span className="block text-[9px] text-neutral-450 font-bold uppercase mt-1 leading-none">{p.category || 'Otros'} • Medida: {p.unit}</span>
                            
                            <div className="flex flex-wrap gap-1 mt-2 text-[8px] font-black font-mono">
                              <span className={`px-1.5 py-0.5 rounded border ${isLight ? 'border-black bg-white text-black' : 'border-neutral-100 bg-neutral-950'}`}>
                                REGULAR: ${p.prices.normal}
                              </span>
                              {p.prices.mayorista !== undefined && (
                                <span className={`px-1.5 py-0.5 rounded border ${isLight ? 'border-black bg-white text-black' : 'border-neutral-100 bg-neutral-950 text-emerald-400'}`}>
                                  MAYOR: ${p.prices.mayorista}
                                </span>
                              )}
                              {p.prices.oferta !== undefined && (
                                <span className={`px-1.5 py-0.5 rounded border ${isLight ? 'border-black bg-white text-black' : 'border-neutral-100 bg-neutral-950 text-amber-400'}`}>
                                  OFERTA: ${p.prices.oferta}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        <button
                          onClick={() => {
                            if (confirm(`¿Eliminar "${p.name}"?`)) {
                              deleteProduct(p.id);
                              showToast('Producto eliminado', 'info');
                            }
                          }}
                          className="p-2 text-red-500 hover:bg-red-50 dark:hover:bg-neutral-900 rounded-full transition-colors"
                          title="Eliminar"
                        >
                          <Trash2 className="h-4.5 w-4.5" />
                        </button>
                      </div>
                    ))}
                    {products.length === 0 && (
                      <div className="col-span-full py-8 text-center text-xs text-neutral-400 italic">No hay productos guardados. Utiliza el formulario arriba para registrar tu inventario.</div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* SESSIONS TAB */}
            {activeTab === 'sessions' && (
              <div className="px-4 py-4 space-y-6 max-w-md mx-auto w-full">
                
                {currentSession ? (
                  <div className="relative">
                    {/* Modern Flutter Minimalist Card */}
                    <div className={`${s.card} p-8 text-center space-y-6 relative overflow-hidden`}>
                      
                      {/* Context Menu Button */}
                      <div className="absolute top-4 right-4">
                        <button
                          onClick={() => setShowSessionMenu(!showSessionMenu)}
                          className={`p-2 rounded-md border-2 transition-all ${
                            isLight ? 'bg-white border-black text-black hover:bg-zinc-100' : 'bg-neutral-950 border-neutral-100 hover:bg-neutral-900 text-neutral-100'
                          }`}
                          title="Opciones de Turno"
                        >
                          <MoreVertical className="h-5 w-5" />
                        </button>
                        
                        {showSessionMenu && (
                          <div className={`absolute right-0 mt-1.5 w-48 rounded-lg border-2 shadow-none z-50 text-left overflow-hidden ${
                            isLight ? 'bg-white border-black text-black' : 'bg-neutral-950 border-neutral-100 text-white'
                          }`}>
                            <button
                              onClick={() => {
                                setShowMetricsModal(true);
                                setShowSessionMenu(false);
                              }}
                              className={`w-full px-4 py-3 text-xs font-black flex items-center gap-2 ${
                                isLight ? 'hover:bg-zinc-100' : 'hover:bg-neutral-900'
                              }`}
                            >
                              <BarChart3 className="h-4 w-4 text-emerald-500 shrink-0" />
                              <span>Métricas de Caja</span>
                            </button>
                            <button
                              onClick={() => {
                                setShowHistoryModal(true);
                                setShowSessionMenu(false);
                              }}
                              className={`w-full px-4 py-3 text-xs font-black flex items-center gap-2 border-t ${s.divider} ${
                                isLight ? 'hover:bg-zinc-100' : 'hover:bg-neutral-900'
                              }`}
                            >
                              <History className="h-4 w-4 text-current shrink-0" />
                              <span>Historial de Ventas</span>
                            </button>
                            <button
                              onClick={() => {
                                setShowSessionMenu(false);
                                const conf = confirm('¿Cerrar sesión contable de hoy?');
                                if (conf) {
                                  closeSession();
                                  showToast('Turno de venta cerrado', 'info');
                                }
                              }}
                              className={`w-full px-4 py-3 text-xs font-black flex items-center gap-2 border-t text-red-650 ${s.divider} ${
                                isLight ? 'hover:bg-zinc-100 text-red-600' : 'hover:bg-neutral-900 text-red-500'
                              }`}
                            >
                              <LogOut className="h-4 w-4 text-red-500 shrink-0" />
                              <span>Cerrar Turno</span>
                            </button>
                          </div>
                        )}
                      </div>

                      {/* Icon */}
                      <div className={`mx-auto p-4 rounded-lg border-2 border-black w-20 h-20 flex items-center justify-center text-4xl ${
                        isLight ? 'bg-white' : 'bg-neutral-950 border-neutral-100'
                      }`}>
                        ⚡
                      </div>

                      <div className="space-y-1">
                        <span className="block text-[10px] font-black uppercase tracking-wider text-neutral-400">Sesión Activa</span>
                        <h2 className="text-3xl font-black text-current">{currentSession.name}</h2>
                        <span className="text-[10px] text-neutral-500 dark:text-neutral-400 block font-bold">Abierto hoy • Total Ventas: ${totalSessionSales.toLocaleString()} CUP</span>
                      </div>

                      {/* Primary FAB */}
                      <button
                        onClick={() => setActiveTab('pos')}
                        className={`w-full py-4 text-sm font-black uppercase tracking-wider flex items-center justify-center gap-2 ${s.btnPrimary}`}
                      >
                        <ShoppingBag className="h-5 w-5" />
                        <span>ATENDER CAJA</span>
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className={`${s.card} p-8 text-center space-y-5`}>
                    <div className="mx-auto p-4 rounded-lg border-2 border-black w-16 h-16 flex items-center justify-center text-3xl bg-white dark:bg-neutral-950 dark:border-neutral-100">
                      💼
                    </div>
                    <div className="space-y-1">
                      <p className="font-black uppercase text-sm">No hay un turno activo</p>
                      <p className="text-xs text-neutral-400 mt-1">Inicia la jornada de trabajo abriendo un turno para ver métricas de caja.</p>
                    </div>
                    <button
                      onClick={openSession}
                      className={`w-full py-3.5 text-xs font-black uppercase ${s.btnPrimary}`}
                    >
                      Abrir Nueva Sesión
                    </button>
                  </div>
                )}

                {/* Closed Sessions */}
                <div className="space-y-3">
                  <span className="block text-[10px] font-black uppercase text-neutral-400 tracking-wider">Turnos Archivados ({sessions.filter(s => s.status === 'closed').length})</span>
                  <div className="space-y-2.5">
                    {sessions
                      .filter(s => s.status === 'closed')
                      .map(sess => {
                        const sessTotal = sess.transactions.reduce((acc, t) => acc + t.totalCUP, 0);
                        return (
                          <div key={sess.id} className={`${s.card} p-4 flex items-center justify-between`}>
                            <div className="space-y-1">
                              <span className="font-extrabold text-sm block leading-none">{sess.name}</span>
                              <span className="block text-[10px] text-neutral-400">
                                Abierto: {new Date(sess.createdTime).toLocaleDateString()} {sess.closedTime && `• Cerrado: ${new Date(sess.closedTime).toLocaleDateString()}`}
                              </span>
                              <span className="block text-[10px] text-emerald-500 font-extrabold uppercase">{sess.transactions.length} transacciones</span>
                            </div>
                            <div className="text-right">
                              <span className="font-black text-emerald-600 dark:text-emerald-400 text-sm block font-mono">${sessTotal.toLocaleString()}</span>
                              <span className="block text-[8px] text-neutral-450 font-bold uppercase">CUP</span>
                            </div>
                          </div>
                        );
                      })}
                  </div>
                </div>
              </div>
            )}

            {/* ADJUSTMENTS & SYSTEM PREFERENCES */}
            {activeTab === 'settings' && (
              <div className="px-5 py-6 space-y-8 max-w-xl mx-auto w-full">
                
                <GoogleDriveBackup showToast={showToast} />

                {/* SECTION: CURRENCIES */}
                <div className="space-y-4">
                  <div className={`flex items-center gap-1.5 pb-2 border-b-2 ${isLight ? 'border-black' : 'border-neutral-100'}`}>
                    <Coins className="h-5 w-5 text-current" />
                    <span className="text-base font-black uppercase">Divisas y Tasas de Cambio</span>
                  </div>

                  <div className="divide-y divide-black/10 dark:divide-neutral-100/10">
                    {currencies.map(curr => (
                      <div key={curr.code} className="py-3.5 flex items-center justify-between text-xs font-bold">
                        <div>
                          <span className="font-black text-sm">{curr.name} ({curr.code})</span>
                          {curr.code !== 'CUP' && (
                            <span className="block text-[10px] text-neutral-450 font-bold mt-0.5 leading-none">
                              Símbolo: {curr.symbol} • Tasa: {curr.rateToBase} CUP
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-2">
                          {curr.code === 'CUP' ? (
                            <span className="bg-zinc-100 border border-black/15 dark:bg-neutral-900 dark:border-neutral-100/15 px-3 py-1.5 rounded text-current font-mono font-black text-[10px]">
                              Base (1.00)
                            </span>
                          ) : (
                            <div className="flex items-center gap-1.5">
                              <input
                                type="number"
                                value={curr.rateToBase}
                                onChange={(e) => updateCurrencyRate(curr.code, Number(e.target.value))}
                                className={`px-2 py-1.5 text-right font-mono font-black text-xs w-[80px] focus:outline-none ${s.input}`}
                              />
                              <span className="text-[9px] text-neutral-400 font-bold uppercase">CUP</span>
                              {curr.isCustom && (
                                <button
                                  onClick={() => deleteCustomCurrency(curr.code)}
                                  className="p-1 text-red-500 hover:text-red-400 ml-1 shrink-0"
                                >
                                  <X className="h-3.5 w-3.5" />
                                </button>
                              )}
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="pt-2 space-y-3">
                    <span className="block text-[10px] font-black uppercase text-neutral-400">Añadir Divisa</span>
                    <div className="grid grid-cols-4 gap-2 text-xs">
                      <input
                        type="text"
                        placeholder="CÓD"
                        value={newCurrCode}
                        onChange={(e) => setNewCurrCode(e.target.value.toUpperCase())}
                        className={`py-1.5 px-2 font-mono ${s.input}`}
                      />
                      <input
                        type="text"
                        placeholder="Nombre"
                        value={newCurrName}
                        onChange={(e) => setNewCurrName(e.target.value)}
                        className={`col-span-2 py-1.5 px-2 ${s.input}`}
                      />
                      <input
                        type="text"
                        placeholder="Símbolo"
                        value={newCurrSymbol}
                        onChange={(e) => setNewCurrSymbol(e.target.value)}
                        className={`py-1.5 px-2 ${s.input}`}
                      />
                      <input
                        type="number"
                        placeholder="Tasa en CUP"
                        value={newCurrRate}
                        onChange={(e) => setNewCurrRate(e.target.value)}
                        className={`col-span-3 py-1.5 px-2 ${s.input}`}
                      />
                      <button
                        onClick={() => {
                          if (!newCurrCode || !newCurrName || !newCurrRate) {
                            showToast('Todos los campos son obligatorios.', 'error');
                            return;
                          }
                          addCustomCurrency({
                            code: newCurrCode,
                            name: newCurrName,
                            symbol: newCurrSymbol || newCurrCode,
                            rateToBase: Number(newCurrRate),
                          });
                          setNewCurrCode('');
                          setNewCurrName('');
                          setNewCurrSymbol('');
                          setNewCurrRate('');
                          showToast('Divisa de cobro creada', 'success');
                        }}
                        className={`py-1.5 text-xs font-black uppercase ${s.btnPrimary}`}
                      >
                        Crear
                      </button>
                    </div>
                  </div>
                </div>

                {/* SECTION: SYSTEM PREFERENCES */}
                <div className="space-y-4">
                  <div className={`flex items-center gap-1.5 pb-2 border-b-2 ${isLight ? 'border-black' : 'border-neutral-100'}`}>
                    <SettingsIcon className="h-5 w-5 text-current" />
                    <span className="text-base font-black uppercase">Preferencias del Sistema</span>
                  </div>

                  <div className="divide-y divide-black/10 dark:divide-neutral-100/10 text-xs font-bold">
                    <div className="py-3.5 flex items-center justify-between">
                      <span className="text-sm font-black">Modo Visual</span>
                      <button
                        onClick={handleToggleTheme}
                        className={`px-3 py-1.5 text-xs font-black uppercase ${s.btnPrimary}`}
                      >
                        {isLight ? 'Modo Oscuro' : 'Modo Claro'}
                      </button>
                    </div>

                    <div className="py-3.5 flex items-center justify-between">
                      <span className="text-sm font-black">Feedback Háptico</span>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={settings.hapticFeedbackEnabled}
                          onChange={(e) => updateSettings({ hapticFeedbackEnabled: e.target.checked })}
                          className="sr-only peer"
                        />
                        <div className={`w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all ${
                          isLight ? 'peer-checked:bg-black' : 'peer-checked:bg-white bg-neutral-900 border border-neutral-100'
                        }`} />
                      </label>
                    </div>

                    <div className="py-3.5 flex items-center justify-between">
                      <span className="text-sm font-black">Acción Doble Toque</span>
                      <select
                        value={settings.longPressAction}
                        onChange={(e) => updateSettings({ longPressAction: e.target.value as 'lock' | 'delete' | 'discount' })}
                        className={`px-2.5 py-1.5 text-xs font-black ${s.select}`}
                      >
                        <option value="lock">Bloquear Línea</option>
                        <option value="delete">Eliminar Línea</option>
                        <option value="discount">Descuento Rápido</option>
                      </select>
                    </div>

                    <div className="py-3.5 flex items-center justify-between">
                      <span className="text-sm font-black">Divisa Principal Sugerida</span>
                      <select
                        value={settings.defaultCurrency}
                        onChange={(e) => updateSettings({ defaultCurrency: e.target.value })}
                        className={`px-2.5 py-1.5 text-xs font-black ${s.select}`}
                      >
                        {currencies.map(c => (
                          <option key={c.code} value={c.code}>{c.code} - {c.symbol}</option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>

                {/* SECTION: APP INSTALLATION */}
                <div className="space-y-4">
                  <div className={`flex items-center gap-1.5 pb-2 border-b-2 ${isLight ? 'border-black' : 'border-neutral-100'}`}>
                    <FolderOpen className="h-5 w-5 text-current" />
                    <span className="text-base font-black uppercase">Instalación de Aplicación</span>
                  </div>
                  <div className="flex items-center justify-start pt-1">
                    <PWAInstallButton />
                  </div>
                </div>

              </div>
            )}
          </div>
        )}
      </main>

      {/* METRICS MODAL */}
      {showMetricsModal && currentSession && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-sm p-6 relative ${s.modal}`}>
            <button
              onClick={() => setShowMetricsModal(false)}
              className="absolute top-4 right-4 p-1 rounded-lg border border-neutral-100 text-slate-400 hover:text-current focus:outline-none"
            >
              <X className="h-4.5 w-4.5" />
            </button>
            
            <div className="flex items-center gap-2 border-b pb-3 mb-4">
              <BarChart3 className="h-5 w-5 text-emerald-500" />
              <h3 className="text-base font-black uppercase">Métricas de Turno</h3>
            </div>

            <div className="space-y-3.5">
              <div className={`${s.cardInner} p-4 flex items-center justify-between`}>
                <span className={`text-xs font-bold ${isLight ? 'text-zinc-600' : 'text-neutral-400'}`}>Monto Neto Facturado:</span>
                <span className="text-lg font-black font-mono text-emerald-600 dark:text-emerald-400">${totalSessionSales.toLocaleString()} CUP</span>
              </div>
              <div className={`${s.cardInner} p-4 flex items-center justify-between`}>
                <span className={`text-xs font-bold ${isLight ? 'text-zinc-600' : 'text-neutral-400'}`}>Total Despachos:</span>
                <span className="text-lg font-black font-mono">{currentSession.transactions.length}</span>
              </div>
              <div className={`${s.cardInner} p-4 flex items-center justify-between`}>
                <span className={`text-xs font-bold ${isLight ? 'text-zinc-600' : 'text-neutral-400'}`}>Promedio por Cuenta:</span>
                <span className="text-lg font-black font-mono text-emerald-600 dark:text-emerald-400">
                  ${currentSession.transactions.length > 0 
                    ? Math.round(totalSessionSales / currentSession.transactions.length).toLocaleString()
                    : 0} CUP
                </span>
              </div>
            </div>

            <button
              onClick={() => setShowMetricsModal(false)}
              className={`w-full py-3 mt-4 text-xs font-black uppercase ${s.btnPrimary}`}
            >
              Cerrar
            </button>
          </div>
        </div>
      )}

      {/* SALES HISTORY MODAL */}
      {showHistoryModal && currentSession && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md p-6 relative ${s.modal}`}>
            <button
              onClick={() => setShowHistoryModal(false)}
              className="absolute top-4 right-4 p-1 rounded-lg border border-neutral-100 text-slate-400 hover:text-current focus:outline-none"
            >
              <X className="h-4.5 w-4.5" />
            </button>
            
            <div className="flex items-center gap-2 border-b pb-3 mb-4">
              <History className="h-5 w-5 text-sky-500" />
              <h3 className="text-base font-black uppercase">Historial de Turno</h3>
            </div>

            <div className="space-y-2 max-h-[300px] overflow-y-auto pr-1">
              {currentSession.transactions.map((tx, idx) => (
                <div key={tx.id} className={`${s.cardInner} p-3 text-xs flex justify-between items-start gap-4`}>
                  <div className="space-y-1 flex-1">
                    <span className="font-black text-xs block leading-none">Venta #{idx + 1} (Cliente #{tx.cartNumber})</span>
                    <div className="text-[11px] text-neutral-400 leading-tight mt-1">
                      {tx.items.map(item => `${item.emoji} ${item.name} (${item.quantity}${item.unit})`).join(', ')}
                    </div>
                    <span className="block text-[9px] text-neutral-450 leading-none">
                      {new Date(tx.timestamp).toLocaleTimeString()}
                    </span>
                  </div>
                  <div className="text-right shrink-0">
                    <span className="font-black text-emerald-600 dark:text-emerald-400 text-xs block leading-none">${tx.totalCUP.toLocaleString()} CUP</span>
                    {tx.paymentCurrency !== 'CUP' && (
                      <span className="block text-[10px] text-neutral-450 mt-1 font-mono leading-none">
                        {tx.paymentAmount.toFixed(2)} {tx.paymentCurrency}
                      </span>
                    )}
                  </div>
                </div>
              ))}
              {currentSession.transactions.length === 0 && (
                <span className="text-xs text-neutral-450 italic block py-8 text-center">No se han registrado ventas en este turno de caja.</span>
              )}
            </div>

            <button
              onClick={() => setShowHistoryModal(false)}
              className={`w-full py-3 mt-4 text-xs font-black uppercase ${s.btnPrimary}`}
            >
              Cerrar Historial
            </button>
          </div>
        </div>
      )}

      {/* FIXED SCAFFOLD BOTTOM NAVIGATION TAB BAR */}
      <footer className={`fixed bottom-0 left-0 right-0 h-16 flex items-center justify-around z-45 ${s.footer}`}>
        <button
          onClick={() => {
            if (currentSession) {
              setActiveTab('pos');
            } else {
              showToast('Abre un turno para acceder a la caja', 'error');
            }
          }}
          className={`flex flex-col items-center gap-1 py-1 px-3.5 rounded-md transition-all cursor-pointer ${
            activeTab === 'pos' 
              ? (isLight ? 'bg-black text-white font-black' : 'bg-white text-black font-black') 
              : 'text-neutral-400 font-bold hover:text-black dark:hover:text-white'
          }`}
        >
          <ShoppingBag className="h-5.5 w-5.5 shrink-0" />
          <span className="text-[10px] leading-none uppercase font-black">Caja POS</span>
        </button>

        <button
          onClick={() => setActiveTab('catalog')}
          className={`flex flex-col items-center gap-1 py-1 px-3.5 rounded-md transition-all cursor-pointer ${
            activeTab === 'catalog' 
              ? (isLight ? 'bg-black text-white font-black' : 'bg-white text-black font-black') 
              : 'text-neutral-400 font-bold hover:text-black dark:hover:text-white'
          }`}
        >
          <Layers className="h-5.5 w-5.5 shrink-0" />
          <span className="text-[10px] leading-none uppercase font-black">Catálogo</span>
        </button>

        <button
          onClick={() => setActiveTab('sessions')}
          className={`flex flex-col items-center gap-1 py-1 px-3.5 rounded-md transition-all cursor-pointer ${
            activeTab === 'sessions' 
              ? (isLight ? 'bg-black text-white font-black' : 'bg-white text-black font-black') 
              : 'text-neutral-400 font-bold hover:text-black dark:hover:text-white'
          }`}
        >
          <Calendar className="h-5.5 w-5.5 shrink-0" />
          <span className="text-[10px] leading-none uppercase font-black">Turnos</span>
        </button>

        <button
          onClick={() => setActiveTab('settings')}
          className={`flex flex-col items-center gap-1 py-1 px-3.5 rounded-md transition-all cursor-pointer ${
            activeTab === 'settings' 
              ? (isLight ? 'bg-black text-white font-black' : 'bg-white text-black font-black') 
              : 'text-neutral-400 font-bold hover:text-black dark:hover:text-white'
          }`}
        >
          <Coins className="h-5.5 w-5.5 shrink-0" />
          <span className="text-[10px] leading-none uppercase font-black">Ajustes</span>
        </button>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <POSProvider>
      <MainAppContent />
    </POSProvider>
  );
}

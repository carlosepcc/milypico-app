/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { usePWAInstall } from '../hooks/usePWAInstall';
import { usePOS } from '../context/POSContext';
import { Download, X, Share } from 'lucide-react';

export const PWAInstallButton: React.FC = () => {
  const { isInstallable, isInstalled, isIOS, install } = usePWAInstall();
  const { settings } = usePOS();
  const [showIOSGuide, setShowIOSGuide] = useState(false);
  const isLight = settings.theme === 'light';

  if (isInstalled) {
    return null;
  }

  const btnStyle = isLight 
    ? 'bg-black hover:bg-neutral-900 text-white border-2 border-black font-black text-xs py-2 px-3 shadow-none active:scale-95 transition-all rounded-lg flex items-center gap-2 cursor-pointer' 
    : 'bg-white hover:bg-neutral-100 text-black border-2 border-neutral-100 font-black text-xs py-2 px-3 shadow-none active:scale-95 transition-all rounded-lg flex items-center gap-2 cursor-pointer';
  
  const modalStyle = isLight
    ? 'bg-white border-2 border-black rounded-lg text-black p-6 relative max-w-sm w-full shadow-none'
    : 'bg-neutral-950 border-2 border-neutral-100 rounded-lg text-white p-6 relative max-w-sm w-full shadow-none';

  const closeBtnStyle = isLight
    ? 'absolute top-4 right-4 p-1.5 rounded-lg border border-black bg-white text-black focus:outline-none hover:bg-neutral-100'
    : 'absolute top-4 right-4 p-1.5 rounded-lg border border-neutral-100 bg-neutral-950 text-white focus:outline-none hover:bg-neutral-900';

  const cardInnerStyle = isLight
    ? 'bg-white border border-black rounded-md p-3 flex gap-3 items-start'
    : 'bg-neutral-950 border border-neutral-100 rounded-md p-3 flex gap-3 items-start';

  const badgeStyle = isLight
    ? 'bg-black text-white p-1 rounded font-black text-xs shrink-0'
    : 'bg-white text-black p-1 rounded font-black text-xs shrink-0';

  // Desktop / Android flow
  if (isInstallable) {
    return (
      <button
        onClick={install}
        className={btnStyle}
        title="Instalar como Aplicación PWA"
      >
        <Download className="h-4 w-4 shrink-0" />
        <span>Instalar POS</span>
      </button>
    );
  }

  // iOS Safari flow
  if (isIOS) {
    return (
      <>
        <button
          onClick={() => setShowIOSGuide(true)}
          className={btnStyle}
        >
          <Download className="h-4 w-4 shrink-0" />
          <span>Instalar en iOS</span>
        </button>

        {showIOSGuide && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-xs">
            <div className={modalStyle}>
              <button
                onClick={() => setShowIOSGuide(false)}
                className={closeBtnStyle}
              >
                <X className="h-4 w-4" />
              </button>
              
              <h3 className="text-base font-black uppercase flex items-center gap-2">
                Instalar Milypico en iOS
              </h3>
              
              <div className="mt-4 space-y-3 text-xs">
                <p className="font-bold">
                  Sigue estos pasos en tu navegador <strong>Safari</strong>:
                </p>
                <div className={cardInnerStyle}>
                  <div className={badgeStyle}>
                    <Share className="h-4 w-4 shrink-0" />
                  </div>
                  <div>
                    <span className="font-black block uppercase text-[10px]">1. Botón Compartir</span>
                    <span className="opacity-80">Presiona el botón de compartir en la barra de Safari.</span>
                  </div>
                </div>
                <div className={cardInnerStyle}>
                  <div className="bg-emerald-500 text-white p-1 rounded font-black text-xs shrink-0 border border-black dark:border-neutral-100">
                    ➕
                  </div>
                  <div>
                    <span className="font-black block uppercase text-[10px]">2. Añadir a pantalla</span>
                    <span className="opacity-80">Desliza hacia abajo y presiona <strong>"Añadir a pantalla de inicio"</strong>.</span>
                  </div>
                </div>
              </div>

              <button
                onClick={() => setShowIOSGuide(false)}
                className={`mt-6 w-full py-3 text-xs font-black uppercase ${
                  isLight ? 'bg-black hover:bg-neutral-900 text-white border-2 border-black rounded-lg' : 'bg-white hover:bg-neutral-100 text-black border-2 border-neutral-100 rounded-lg'
                }`}
              >
                Entendido
              </button>
            </div>
          </div>
        )}
      </>
    );
  }

  return null;
};

/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { useOnlineStatus } from '../hooks/usePWAInstall';
import { WifiOff } from 'lucide-react';

export const OfflineIndicator: React.FC = () => {
  const isOnline = useOnlineStatus();

  if (isOnline) return null;

  return (
    <div className="fixed bottom-4 left-4 z-50 flex items-center gap-2 rounded-xl bg-amber-600 px-4 py-2 text-xs font-semibold text-white shadow-xl border border-amber-500 animate-bounce">
      <WifiOff className="h-4 w-4 text-white shrink-0 animate-pulse" />
      <span>Modo Sin Conexión — Operando 100% en Base de Datos Local</span>
    </div>
  );
};

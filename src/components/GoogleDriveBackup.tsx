/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { usePOS } from '../context/POSContext';
import { localDb } from '../db/localDb';
import { Cloud, CloudUpload, CloudDownload, Key, CheckCircle, AlertTriangle, FileUp, FileDown } from 'lucide-react';

interface GoogleDriveBackupProps {
  showToast?: (message: string, type?: 'success' | 'info' | 'error') => void;
}

export const GoogleDriveBackup: React.FC<GoogleDriveBackupProps> = ({ showToast }) => {
  const { restoreBackup, settings, updateSettings, isOnline } = usePOS();
  const isLight = settings.theme === 'light';
  const triggerToast = showToast || ((msg, type) => alert(msg));
  
  // Google OAuth states
  const [token, setToken] = useState<string | null>(null);
  const [userInfo, setUserInfo] = useState<{ email?: string; name?: string; picture?: string } | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSyncTime, setLastSyncTime] = useState<string | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);
  const [driveFileId, setDriveFileId] = useState<string | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  
  // Custom Client ID input state
  const [inputClientId, setInputClientId] = useState(settings.googleClientId || '');

  // Strict High-Contrast Theme classes (no nested card borders, flat and clean)
  const s = {
    title: isLight ? 'text-black font-black' : 'text-white font-black',
    textMuted: isLight ? 'text-zinc-600 font-bold' : 'text-neutral-400 font-bold',
    buttonAccent: isLight 
      ? 'bg-zinc-100 hover:bg-zinc-200 text-black rounded-lg active:scale-95 transition-all cursor-pointer border border-black/25 font-black text-[10px] px-2.5 py-1.5' 
      : 'bg-neutral-900 hover:bg-neutral-850 text-white font-black rounded-lg active:scale-95 transition-all cursor-pointer border border-neutral-100/25 font-black text-[10px] px-2.5 py-1.5',
    input: isLight 
      ? 'bg-white border-2 border-black text-black placeholder-zinc-500 rounded-lg focus:outline-none focus:ring-1 focus:ring-black font-extrabold' 
      : 'bg-neutral-950 border-2 border-neutral-100 text-neutral-100 placeholder-neutral-500 rounded-lg focus:outline-none focus:ring-1 focus:ring-neutral-100 font-extrabold',
    buttonSave: isLight 
      ? 'bg-black hover:bg-neutral-900 text-white rounded-lg font-black border-2 border-black active:scale-95 transition-all' 
      : 'bg-white hover:bg-neutral-100 text-black rounded-lg font-black border-2 border-neutral-100 active:scale-95 transition-all',
    btnGoogle: isLight 
      ? 'bg-black hover:bg-neutral-900 text-white font-black rounded-lg border-2 border-black' 
      : 'bg-white hover:bg-neutral-100 text-black font-black rounded-lg border-2 border-neutral-100',
    btnActionPrimary: isLight 
      ? 'bg-black hover:bg-neutral-900 text-white font-black rounded-lg border-2 border-black' 
      : 'bg-white hover:bg-neutral-100 text-black font-black rounded-lg border-2 border-neutral-100',
    btnActionSecondary: isLight 
      ? 'bg-white hover:bg-zinc-100 text-black border-2 border-black font-black rounded-lg' 
      : 'bg-neutral-950 hover:bg-neutral-900 text-white border-2 border-neutral-100 font-black rounded-lg',
    statusBox: isLight 
      ? 'bg-zinc-50 border border-black/15 text-black rounded-lg p-3' 
      : 'bg-neutral-900/40 border border-neutral-100/15 text-neutral-100 rounded-lg p-3',
  };

  // Parse token from window location hash on mount (Implicit Flow callback)
  useEffect(() => {
    const hash = window.location.hash;
    if (hash) {
      const params = new URLSearchParams(hash.substring(1));
      const accessToken = params.get('access_token');
      if (accessToken) {
        setToken(accessToken);
        setSyncError(null);
        
        // Clean URL hash
        window.history.replaceState(null, '', window.location.pathname + window.location.search);
        
        // Fetch user info
        fetchUserInfo(accessToken);
        // Automatically search or create backup file
        searchOrCreateBackupFile(accessToken);
      }
    }
  }, []);

  const fetchUserInfo = async (accessToken: string) => {
    try {
      const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      if (res.ok) {
        const data = await res.json();
        setUserInfo(data);
      }
    } catch (e) {
      console.error('Error fetching user info', e);
    }
  };

  // Launch OAuth login
  const handleConnectDrive = () => {
    const clientId = settings.googleClientId || '846603202324-example.apps.googleusercontent.com';
    const scope = 'https://www.googleapis.com/auth/drive.file';
    const redirectUri = window.location.origin;
    const oauthUrl = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${encodeURIComponent(clientId)}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=token&scope=${encodeURIComponent(scope)}&state=milypico_implicit`;
    window.location.href = oauthUrl;
  };

  const handleDisconnect = () => {
    setToken(null);
    setUserInfo(null);
    setDriveFileId(null);
    setLastSyncTime(null);
    setSyncError(null);
  };

  // Find if milypico_backup.json exists in user's Drive
  const searchOrCreateBackupFile = async (accessToken: string) => {
    setIsSyncing(true);
    try {
      const q = encodeURIComponent("name = 'milypico_backup.json' and trashed = false");
      const res = await fetch(`https://www.googleapis.com/drive/v3/files?q=${q}&fields=files(id,name)`, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      
      if (!res.ok) {
        throw new Error('No se pudo buscar el archivo en Google Drive. Verifica tu Client ID.');
      }
      
      const data = await res.json();
      if (data.files && data.files.length > 0) {
        const fileId = data.files[0].id;
        setDriveFileId(fileId);
        setLastSyncTime('Conectado');
      } else {
        // File doesn't exist, create it
        const createRes = await fetch('https://www.googleapis.com/drive/v3/files', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            name: 'milypico_backup.json',
            mimeType: 'application/json',
          }),
        });
        
        if (createRes.ok) {
          const fileData = await createRes.json();
          setDriveFileId(fileData.id);
          setLastSyncTime('Respaldo inicializado');
        } else {
          throw new Error('No se pudo inicializar el archivo de respaldo en tu Drive.');
        }
      }
    } catch (e: any) {
      console.error(e);
      setSyncError(e.message || 'Error de conexión con Google Drive');
    } finally {
      setIsSyncing(false);
    }
  };

  // Upload current local state to Google Drive
  const handleBackupToDrive = async () => {
    if (!token || isSyncing) return;
    
    setIsSyncing(true);
    setSyncError(null);
    
    try {
      let fileId = driveFileId;
      
      if (!fileId) {
        const q = encodeURIComponent("name = 'milypico_backup.json' and trashed = false");
        const res = await fetch(`https://www.googleapis.com/drive/v3/files?q=${q}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();
        if (data.files && data.files.length > 0) {
          fileId = data.files[0].id;
          setDriveFileId(fileId);
        } else {
          throw new Error('Archivo de respaldo no encontrado. Por favor, reconecta.');
        }
      }
      
      const backupData = localDb.exportBackup();
      
      const uploadRes = await fetch(`https://www.googleapis.com/upload/drive/v3/files/${fileId}?uploadType=media`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(backupData),
      });
      
      if (!uploadRes.ok) {
        throw new Error('Error al enviar los datos a Google Drive.');
      }
      
      const now = new Date();
      setLastSyncTime(now.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
      triggerToast('Copia en nube completada', 'success');
    } catch (e: any) {
      console.error(e);
      setSyncError(e.message || 'Error al guardar respaldo.');
    } finally {
      setIsSyncing(false);
    }
  };

  // Download and restore state from Google Drive
  const handleRestoreFromDrive = async () => {
    if (!token || !driveFileId || isSyncing) return;
    
    const confirmRestore = window.confirm('¿Estás seguro de que quieres RESTAURAR tus datos desde Google Drive? Esto reemplazará todo tu catálogo, historial de sesiones y carritos activos actuales.');
    if (!confirmRestore) return;
    
    setIsSyncing(true);
    setSyncError(null);
    
    try {
      const res = await fetch(`https://www.googleapis.com/drive/v3/files/${driveFileId}?alt=media`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      if (!res.ok) {
        throw new Error('No se pudo leer el archivo de respaldo en Google Drive.');
      }
      
      const backupData = await res.json();
      const success = restoreBackup(backupData);
      if (success) {
        const now = new Date();
        setLastSyncTime(`Restaurado ${now.toLocaleTimeString()}`);
        triggerToast('Respaldo restaurado', 'success');
      } else {
        throw new Error('El formato del archivo de respaldo es inválido.');
      }
    } catch (e: any) {
      console.error(e);
      setSyncError(e.message || 'Error al restaurar respaldo.');
    } finally {
      setIsSyncing(false);
    }
  };

  // Local Backup Fallback (JSON files)
  const handleLocalDownload = () => {
    const backupData = localDb.exportBackup();
    const jsonString = `data:text/json;charset=utf-8,${encodeURIComponent(
      JSON.stringify(backupData, null, 2)
    )}`;
    
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', jsonString);
    
    const dateStr = new Date().toISOString().slice(0, 10);
    downloadAnchor.setAttribute('download', `milypico_backup_${dateStr}.json`);
    
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  const handleLocalUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const fileReader = new FileReader();
    const file = e.target.files?.[0];
    if (!file) return;

    fileReader.onload = (event) => {
      try {
        const parsed = JSON.parse(event.target?.result as string);
        const confirmRestore = window.confirm('¿Estás seguro de que quieres RESTAURAR los datos desde este archivo? Esto sobrescribirá todos los productos, sesiones e historial del POS.');
        if (!confirmRestore) return;

        const success = restoreBackup(parsed);
        if (success) {
          triggerToast('Respaldo local restaurado', 'success');
        } else {
          triggerToast('Formato de respaldo no válido', 'error');
        }
      } catch (err) {
        triggerToast('Error al leer el archivo JSON', 'error');
      }
    };
    fileReader.readAsText(file);
    e.target.value = '';
  };

  const handleSaveClientId = () => {
    updateSettings({ googleClientId: inputClientId.trim() });
    setShowConfig(false);
    triggerToast('Client ID guardado', 'success');
  };

  return (
    <div className="space-y-4">
      <div className={`flex items-center justify-between border-b pb-2 ${isLight ? 'border-b-2 border-black' : 'border-b-2 border-neutral-100'}`}>
        <h2 className={`text-base font-black uppercase ${s.title} flex items-center gap-1.5`}>
          <Cloud className="h-5 w-5 shrink-0" />
          <span>Sincronización en Nube</span>
        </h2>
        <button 
          onClick={() => setShowConfig(!showConfig)}
          className={s.buttonAccent}
        >
          <Key className="h-3.5 w-3.5 shrink-0" />
          <span>Configurar</span>
        </button>
      </div>

      {showConfig && (
        <div className="space-y-2 text-xs">
          <div className="flex gap-2">
            <input
              type="text"
              placeholder="Google Client ID de Google Cloud"
              value={inputClientId}
              onChange={(e) => setInputClientId(e.target.value)}
              className={`flex-1 px-3 py-1.5 text-[11px] font-mono ${s.input}`}
            />
            <button
              onClick={handleSaveClientId}
              className={`px-3 py-1.5 text-xs font-black shrink-0 ${s.buttonSave}`}
            >
              Guardar
            </button>
          </div>
          <div className="text-[10px] opacity-75 font-mono">
            Origen autorizado: {window.location.origin}
          </div>
        </div>
      )}

      {/* Main Cloud Sync Module */}
      <div className="space-y-3">
        {!token ? (
          <div className="flex flex-col sm:flex-row gap-3 items-center justify-between py-1">
            <span className={`${s.textMuted} text-xs`}>Google Drive Desconectado</span>
            <button
              onClick={handleConnectDrive}
              disabled={!isOnline}
              className={`w-full sm:w-auto font-black py-2 px-4 rounded-lg flex items-center justify-center gap-2 transition-all active:scale-95 text-xs ${
                isOnline 
                  ? s.btnGoogle
                  : 'opacity-35 cursor-not-allowed'
              }`}
            >
              <svg className="w-4 h-4 shrink-0" viewBox="0 0 48 48">
                <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path>
                <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path>
                <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path>
                <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path>
              </svg>
              <span>Conectar Google Drive</span>
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="flex items-center justify-between py-1">
              <div className="flex items-center gap-2">
                {userInfo?.picture ? (
                  <img src={userInfo.picture} alt="User profile" className={`h-6 w-6 rounded-full border ${isLight ? 'border-black' : 'border-neutral-100'}`} />
                ) : (
                  <div className={`rounded-full h-6 w-6 flex items-center justify-center font-black text-[10px] uppercase border ${isLight ? 'bg-black text-white border-black' : 'bg-white text-black border-white'}`}>
                    {userInfo?.name?.charAt(0) || 'U'}
                  </div>
                )}
                <div className="truncate">
                  <span className={`block font-black text-xs leading-tight truncate ${s.title}`}>{userInfo?.name || 'Usuario'}</span>
                  <span className="block text-[9px] opacity-70 truncate font-mono">{userInfo?.email}</span>
                </div>
              </div>
              <button
                onClick={handleDisconnect}
                className="text-[9px] font-black uppercase text-red-650 hover:text-red-750 bg-transparent border border-red-650 px-2.5 py-1 rounded-md active:scale-95 transition-transform shrink-0"
              >
                Cerrar
              </button>
            </div>

            {/* Sync metrics */}
            <div className={s.statusBox}>
              <div className="flex justify-between text-xs font-bold font-mono">
                <div>
                  <span className="opacity-60 text-[10px] block font-sans">ESTADO:</span>
                  <span className="font-black text-emerald-600 dark:text-emerald-400">Listo</span>
                </div>
                <div className="text-right">
                  <span className="opacity-60 text-[10px] block font-sans">SINCRONIZACIÓN:</span>
                  <span className="font-black">{lastSyncTime || 'Conectado'}</span>
                </div>
              </div>
            </div>

            {syncError && (
              <div className="p-2 border border-red-650 rounded-lg flex gap-2 text-red-650 text-[10px] font-black">
                <AlertTriangle className="h-3.5 w-3.5 shrink-0 text-red-650" />
                <span>{syncError}</span>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-2">
              <button
                onClick={handleBackupToDrive}
                disabled={isSyncing}
                className={`flex-1 py-2 px-3 rounded-lg text-xs flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer ${s.btnActionPrimary} disabled:opacity-35`}
              >
                <CloudUpload className={`h-4 w-4 shrink-0 ${isSyncing ? 'animate-bounce' : ''}`} />
                <span>Subir Respaldo</span>
              </button>
              <button
                onClick={handleRestoreFromDrive}
                disabled={isSyncing || !driveFileId}
                className={`flex-1 py-2 px-3 rounded-lg text-xs flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer ${s.btnActionSecondary} disabled:opacity-35`}
              >
                <CloudDownload className="h-4 w-4 shrink-0" />
                <span>Bajar Respaldo</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Local Backup Section */}
      <div className="pt-3 space-y-2">
        <span className="block text-[10px] font-black uppercase tracking-wider text-neutral-400">Archivos Físicos Locales</span>
        
        <div className="flex gap-2">
          {/* Download JSON */}
          <button
            onClick={handleLocalDownload}
            className={`flex-1 py-2 px-2 text-xs flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer ${s.btnActionSecondary}`}
          >
            <FileDown className="h-4 w-4 shrink-0" />
            <span>Guardar JSON</span>
          </button>

          {/* Upload JSON */}
          <label className={`flex-1 py-2 px-2 text-xs flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer text-center ${s.btnActionSecondary}`}>
            <FileUp className="h-4 w-4 shrink-0" />
            <span>Cargar JSON</span>
            <input
              type="file"
              accept=".json"
              onChange={handleLocalUpload}
              className="hidden"
            />
          </label>
        </div>
      </div>
    </div>
  );
};

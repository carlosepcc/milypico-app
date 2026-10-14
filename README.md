# Milypico POS (Flutter Native)

Punto de Venta (POS) Offline-First desarrollado en **Flutter** con arquitectura **Material Design 3**, diseñado para la gestión rápida de ventas en gastronomía y comercio con soporte multi-moneda (CUP, USD, EUR, MLC), carritos múltiples concurrentes por cliente y turnos de caja.

---

## 🛠️ Cómo abrir y ejecutar en Android Studio

1. **Clonar el repositorio:**
   ```bash
   git clone <url-del-repositorio> milypico_pos
   cd milypico_pos
   ```

2. **Abrir en Android Studio:**
   - Abre Android Studio.
   - Selecciona **Open** (o **File > Open...**).
   - Elige la carpeta raíz del proyecto (`milypico_pos`).
   - Android Studio detectará automáticamente el archivo `pubspec.yaml` y la configuración de Flutter/Android.

3. **Instalar dependencias:**
   - Haz clic en **Pub get** en la barra superior de Android Studio, o en la terminal:
   ```bash
   flutter pub get
   ```

4. **Ejecutar en emulador o dispositivo físico:**
   - Selecciona tu dispositivo o emulador Android (API 21+) en el menú desplegable.
   - Presiona el botón verde de **Run** (o `Shift + F10`).
   - O por terminal:
   ```bash
   flutter run -d android
   ```

---

## 🏗️ Arquitectura del Proyecto

```text
├── pubspec.yaml                     # Configuración del proyecto, dependencias y assets
├── analysis_options.yaml            # Reglas oficiales del linter de Dart/Flutter
├── android/                         # Configuración Gradle y AndroidManifest para Android Studio
│   ├── build.gradle
│   ├── settings.gradle
│   └── app/
│       ├── build.gradle             # applicationId "com.milypico.pos", compileSdk 34, minSdk 21
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/com/milypico/pos/MainActivity.kt
└── lib/
    ├── main.dart                    # Punto de entrada con tema Material Design 3 dinámico
    ├── models/
    │   ├── product.dart             # Modelo de Producto, unidades (u/lb) y tarifas
    │   ├── cart.dart                # Carritos dinámicos y CartItem con bloqueo de línea
    │   ├── session.dart             # Turnos de caja, ventas por divisa y arqueos
    │   ├── transaction.dart         # Registro histórico de tickets de venta
    │   ├── currency.dart            # Tasas de cambio relativas a CUP
    │   ├── settings.dart            # Configuración de usuario, haptics y cliente Google
    │   └── backup.dart              # Esquema de serialización de respaldo JSON
    ├── providers/
    │   └── pos_provider.dart        # Estado reactivo global con ChangeNotifier (Provider)
    ├── services/
    │   ├── local_storage_service.dart# Persistencia offline en SharedPreferences con seed inicial
    │   └── backup_service.dart      # Generación y restauración de copias de seguridad
    ├── screens/
    │   ├── home_screen.dart         # Navegación principal con NavigationBar M3
    │   ├── pos_screen.dart          # Caja POS con clientes concurrentes y catálogo
    │   ├── sessions_screen.dart     # Gestión de apertura y cierre de turnos de caja
    │   ├── catalog_screen.dart      # Administración de productos, precios y categorías
    │   ├── currencies_screen.dart   # Modificación y creación de tasas de cambio
    │   └── settings_screen.dart     # Preferencias, tema claro/oscuro y respaldo
    └── widgets/
        ├── keypad_widget.dart       # Teclado táctil ergonómico (+1, +5, -1, C, ⌫) y bloqueo
        ├── checkout_dialog.dart     # Modal BottomSheet de cobro multi-divisa con cálculo de cambio
        ├── price_tier_dialog.dart   # Selector de tarifa (Normal, Mayorista, Oferta, Personalizado)
        ├── session_metrics_dialog.dart# Desglose de KPIs y ranking de productos más vendidos
        └── session_history_dialog.dart# Historial de turnos archivados
```

---

## 🚀 Compilación para Producción

```bash
# APK instalable para Android
flutter build apk --release

# App Bundle (AAB) para Google Play Store
flutter build appbundle --release

# Versión Web
flutter build web --release
```

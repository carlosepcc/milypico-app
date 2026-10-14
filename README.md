# Milypico POS - Flutter Edition

Punto de Venta (POS) Offline-First desarrollado enteramente en Flutter para la gestión ágil de ventas, carritos dinámicos múltiples, multi-divisa (CUP, USD, EUR, MLC) y sincronización con Google Drive.

## 📱 Características Principales

- **Offline-First:** Funciona de forma 100% autónoma sin depender de conexión a internet.
- **Teclado Táctil Integrado:** Teclado numérico ergonómico para ingreso de cantidades, decimales, pasos rápidos (+1, +5, -1) y bloqueo de líneas.
- **Carritos Múltiples:** Gestión simultánea de carritos por cliente (#1, #2, #3...) con códigos de color.
- **Multi-Divisa en Tiempo Real:** Configuración de tasas de cambio respecto al Peso Cubano (CUP), conversión automática del total y cálculo de vuelto en divisas extranjeras o CUP.
- **Tarifas de Precios Flexibles:** Precios normales, mayoristas, de oferta o personalizados por ítem.
- **Sesiones de Caja:** Apertura y cierre de turnos de caja con generación automática de nombres ("16 Sep", "16 Sep (2)"), auditoría de ventas, métricas y desglose por moneda.
- **Respaldo & Sincronización:** Exportación e importación de respaldo JSON completo y sincronización con Google Drive.

## 🚀 Requisitos y Ejecución

### Prerrequisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión >= 3.0.0)
- Dart SDK

### Instalación de dependencias
```bash
flutter pub get
```

### Ejecutar en modo desarrollo
```bash
# En el navegador Web
flutter run -d chrome

# En un emulador o dispositivo Android
flutter run -d android

# En un simulador iOS o dispositivo Apple
flutter run -d ios
```

### Compilar para Producción
```bash
# APK de Android
flutter build apk --release

# Bundle de Android para Google Play Store
flutter build appbundle --release

# Versión Web
flutter build web --release
```

## 📂 Arquitectura del Proyecto

```text
lib/
├── main.dart                      # Punto de entrada de la aplicación y temas Material 3
├── models/
│   ├── product.dart               # Modelo de Producto, unidades (u/lb) y tarifas
│   ├── cart.dart                  # Modelo de Carrito y CartItem con bloqueo
│   ├── session.dart               # Sesión de caja, totales y ventas por divisa
│   ├── transaction.dart           # Registro de transacciones y tickets
│   ├── currency.dart              # Tasas de cambio multi-moneda
│   ├── settings.dart              # Preferencias y opciones de usuario
│   └── backup.dart                # Esquema de serialización de respaldo
├── providers/
│   └── pos_provider.dart          # Gestión de estado global reactivo (ChangeNotifier)
├── services/
│   ├── local_storage_service.dart # Persistencia offline con SharedPreferences
│   └── backup_service.dart        # Generación y validación de JSON de respaldo
├── screens/
│   ├── home_screen.dart           # Navegación principal Material 3
│   ├── pos_screen.dart            # Pantalla de venta, catálogo y teclado táctil
│   ├── sessions_screen.dart       # Gestión de turnos y arqueos de caja
│   ├── catalog_screen.dart        # Administración de productos y precios
│   ├── currencies_screen.dart     # Gestión de tasas de cambio y monedas
│   └── settings_screen.dart       # Opciones de sistema, haptics y respaldo
└── widgets/
    ├── keypad_widget.dart         # Teclado numérico táctil y barra de producto
    ├── checkout_dialog.dart       # Modal de cobro con selector de divisa y cálculo de vuelto
    ├── price_tier_dialog.dart     # Selector de tarifas (normal, mayorista, oferta)
    ├── session_metrics_dialog.dart# Desglose de KPIs y productos más vendidos
    └── session_history_dialog.dart# Historial de sesiones cerradas
```

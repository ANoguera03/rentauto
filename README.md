# RentAuto 🚗

App móvil en Flutter para alquilar vehículos entre particulares, con validación de documentos mediante inteligencia artificial.

Proyecto final de Desarrollo Móvil · Universidad de Nariño
**Autor:** Andrés Felipe Noguera

## Problema que resuelve

En Pasto hay mucha movilidad y una demanda particular de vehículos para viajes cortos a municipios cercanos (Ipiales, Laguna de la Cocha, Túquerres) o para un fin de semana. Las agencias tradicionales de renta suelen ser costosas y burocráticas. RentAuto conecta directamente a dueños de vehículos con personas que necesitan alquilarlos.

## Funcionalidades

- [x] Selector de perfil (cliente / dueño)
- [x] Catálogo de vehículos con tarjetas
- [x] Publicar vehículo con foto (solo modo dueño)
- [x] Detalle del vehículo
- [ ] Validación de licencia de conducción con IA
- [ ] Reservas por fechas sin cruces
- [ ] Estados de reserva y calificaciones
- [ ] Perfil y documentos

## Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter / Dart | Interfaz de la aplicación |
| provider | Manejo de estado |
| sqflite | Base de datos local (SQLite) |
| image_picker | Selección de fotos |
| http | Comunicación con la API de IA |
| intl | Formato de fechas |

## Arquitectura

```
lib/
 ├── models/       # Clases de datos (Vehiculo)
 ├── services/     # Acceso a datos y a la IA (DatabaseService, AIService)
 ├── providers/    # Estado de la app (VehiculoProvider)
 ├── screens/      # Pantallas
 └── widgets/      # Componentes reutilizables
```

La lógica de negocio está separada de la interfaz: las pantallas nunca hablan directo con la base de datos, siempre pasan por el provider.

## Cómo ejecutar el proyecto

1. Instalar Flutter y tener un emulador Android o dispositivo físico.
2. Clonar el repositorio:
```bash
   git clone https://github.com/TU_USUARIO/rentauto.git
   cd rentauto
```
3. Instalar dependencias:
```bash
   flutter pub get
```
4. Ejecutar:
```bash
   flutter run
```

## Variables de entorno

*(Se completará al integrar la IA.)* La API key se guarda en un archivo `.env` en la raíz del proyecto, que no se sube al repositorio:

```
GEMINI_API_KEY=tu_clave_aqui
```

## Estado del proyecto

En desarrollo. Prototipo con persistencia local en SQLite, diseñado para poder migrar a Firebase más adelante.
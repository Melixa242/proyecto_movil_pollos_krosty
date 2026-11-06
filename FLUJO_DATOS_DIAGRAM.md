# Diagrama de Flujo - Sistema de Composición de Productos

## 🔄 Flujo General de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│                    APLICACIÓN FLUTTER                           │
└─────────────────────────────────────────────────────────────────┘

┌─ SCREEN: ProductoComposicionScreen ──────────────────────────────┐
│                                                                   │
│  - Tabla de composiciones                                        │
│  - Búsqueda                                                      │
│  - Botones: Crear, Editar, Eliminar, Ver                       │
│  - Manejo de loading, error, success                             │
│                                                                   │
│  Interacciones:                                                 │
│  └─> provider.fetchComposiciones()  ────┐                       │
│  └─> provider.createComposicion()    ────┼──> PROVIDER         │
│  └─> provider.updateComposicion()    ────┤                      │
│  └─> provider.deleteComposicion()    ────┘                      │
└───────────────────┬─────────────────────────────────────────────┘
                    │ watch()
                    ▼
┌─ PROVIDER: ProductoComposicionProvider ──────────────────────────┐
│                                                                   │
│  State:                                                          │
│  - List<ProductoComposicion> _composiciones                     │
│  - bool _isLoading                                              │
│  - String? _error                                               │
│                                                                   │
│  Methods:                                                       │
│  ├─ fetchComposiciones()    ──┐                                 │
│  ├─ createComposicion()    ───┼──> API_SERVICE                 │
│  ├─ updateComposicion()    ───┤                                 │
│  └─ deleteComposicion()    ──┘                                  │
│                                                                   │
│  Después de cada acción:                                        │
│  - Recargar datos (fetchComposiciones)                          │
│  - Notificar listeners (notifyListeners)                        │
│  - Screen re-renderiza automáticamente                          │
└───────────────────┬─────────────────────────────────────────────┘
                    │ async
                    ▼
┌─ SERVICE: ApiService ──────────────────────────────────────────────┐
│                                                                   │
│  HTTP Methods:                                                  │
│  ├─ get(endpoint)          HTTP GET request                     │
│  ├─ post(endpoint, data)   HTTP POST request                    │
│  ├─ put(endpoint, data)    HTTP PUT request                     │
│  └─ delete(endpoint)       HTTP DELETE request                  │
│                                                                   │
│  Todos los métodos:                                             │
│  ✓ Agregan Authorization: Bearer {token}                        │
│  ✓ Content-Type: application/json                               │
│  ✓ Accept: application/json                                     │
│  ✓ Parsean respuestas como JSON                                 │
│                                                                   │
│  Token: obtenido de SharedPreferences (login)                  │
└───────────────────┬─────────────────────────────────────────────┘
                    │ HTTP
                    ▼
┌─ BACKEND API: Laravel ────────────────────────────────────────────┐
│                                                                   │
│  Endpoints:                                                     │
│  GET    /api/composicion-productos            (listado)         │
│  POST   /api/composicion-productos            (crear)           │
│  PUT    /api/composicion-productos/{id}       (actualizar)      │
│  DELETE /api/composicion-productos/{id}       (eliminar)        │
│                                                                   │
│  Autenticación: Sanctum (Bearer token)                          │
│  Validación: Request validation middleware                      │
└───────────────────┬─────────────────────────────────────────────┘
                    │ Database
                    ▼
┌─ DATABASE: MySQL ─────────────────────────────────────────────────┐
│                                                                   │
│  Table: composicion_productos                                   │
│  ├─ id (PK)                                                     │
│  ├─ producto_padre_id (FK → productos.id)                      │
│  ├─ producto_hijo_id (FK → productos.id)                       │
│  ├─ cantidad (decimal 12,2)                                    │
│  └─ estado (int, default 1)                                     │
│                                                                   │
│  Constraints:                                                   │
│  - ON DELETE CASCADE en ambas FKs                               │
│  - Índices en FK columns                                        │
│  - Validación de integridad referencial                         │
└───────────────────────────────────────────────────────────────────┘
```

## 📊 Flujo de Operación: Crear Composición

```
Usuario hace click en "Nueva composición"
           │
           ▼
showComposicionFormDialog()
           │
    ┌──────┴──────┐
    │             │
 Usuario llena    Usuario cancela
 el formulario
    │
    ▼
Usuario presiona "Guardar"
    │
    ▼
Screen → provider.createComposicion(composicion)
    │
    ▼
Provider → _apiService.post(
    '/composicion-productos',
    {producto_padre_id, producto_hijo_id, cantidad, estado}
)
    │
    ▼
ApiService → HTTP POST http://localhost:8000/api/composicion-productos
    │        Headers: Authorization: Bearer {token}
    │        Body: JSON
    │
    ▼
Backend → ComposicionProductoController::store()
    │     ├─ Validate input
    │     ├─ Check FK constraints
    │     └─ ComposicionProducto::create()
    │
    ▼
Database → INSERT into composicion_productos
    │
    ▼
Response: 201 Created + JSON data
    │
    ▼
Provider recibe response
    │
    ├─ if statusCode == 201
    │  ├─ fetchComposiciones() (recarga lista)
    │  └─ return true
    │
    ├─ else
    │  └─ return false + set error
    │
    ▼
Screen muestra SnackBar
    │
    ├─ "Composición creada" (si ok)
    │ │
    │ ▼
    │ Tabla actualiza automáticamente
    │
    └─ "Error al crear composición" (si error)
       │
       ▼
       Usuario ve el error y puede reintentar
```

## 🔄 Flujo de Operación: Actualizar Composición

```
Usuario hace click en "Editar" en una fila
           │
           ▼
showComposicionFormDialog(composicion)
           │
           ├─ Pre-llena campos con datos actuales
           │
    ┌──────┴──────────┐
    │                 │
 Usuario modifica     Usuario cancela
 uno o más campos
    │
    ▼
Usuario presiona "Guardar"
    │
    ▼
Screen → provider.updateComposicion(updated_composicion)
    │
    ▼
Provider → _apiService.put(
    '/composicion-productos/{id}',
    {producto_padre_id, producto_hijo_id, cantidad, estado}
)
    │
    ▼
ApiService → HTTP PUT http://localhost:8000/api/composicion-productos/{id}
    │        Headers: Authorization: Bearer {token}
    │        Body: JSON
    │
    ▼
Backend → ComposicionProductoController::update()
    │     ├─ Validate input
    │     ├─ Check FK constraints
    │     └─ $composicion->update()
    │
    ▼
Database → UPDATE composicion_productos SET ... WHERE id = {id}
    │
    ▼
Response: 200 OK + JSON data
    │
    ▼
Provider recibe response
    │
    ├─ if statusCode == 200
    │  ├─ fetchComposiciones() (recarga lista)
    │  └─ return true
    │
    ├─ else
    │  └─ return false + set error
    │
    ▼
Screen muestra SnackBar + Tabla actualiza
```

## 🗑️ Flujo de Operación: Eliminar Composición

```
Usuario hace click en "Eliminar" en una fila
           │
           ▼
AlertDialog("¿Eliminar esta composición?")
           │
    ┌──────┴───────┐
    │              │
 Usuario dice      Usuario dice
 "Sí"             "No"
    │              │
    ▼              └─> Dialog cierra
Provider.deleteComposicion(id)

    ▼
Provider → _apiService.delete(
    '/composicion-productos/{id}'
)
    │
    ▼
ApiService → HTTP DELETE http://localhost:8000/api/composicion-productos/{id}
    │         Headers: Authorization: Bearer {token}
    │
    ▼
Backend → ComposicionProductoController::destroy()
    │     └─ $composicion->delete()
    │
    ▼
Database → DELETE FROM composicion_productos WHERE id = {id}
    │
    ▼
Response: 200 OK
    │
    ▼
Provider recibe response
    │
    ├─ if statusCode == 200
    │  ├─ Elimina de lista local
    │  ├─ fetchComposiciones() (recarga)
    │  └─ return true
    │
    ├─ else
    │  └─ return false + set error
    │
    ▼
Screen muestra SnackBar + Tabla actualiza
```

## 🔍 Flujo de Operación: Búsqueda

```
Usuario escribe en el campo de búsqueda
           │
           ▼
_searchController.text cambia
           │
           ▼
Usuario presiona "Buscar" o Enter
           │
           ▼
_runSearch() → setState()
    │
    ▼
_query = texto.lowercase()
    │
    ▼
Screen re-renderiza
    │
    ▼
_filter(provider.composiciones)
    │
    ▼
Retorna lista filtrada donde:
  - productoPadreId.toString().contains(_query) OR
  - productoHijoId.toString().contains(_query) OR
  - cantidad.toString().contains(_query)
    │
    ▼
Tabla muestra solo resultados que coincidan
    │
    │ Si usuario presiona "Limpiar"
    └─> _clearSearch()
       ├─ controller.clear()
       ├─ _query = ''
       └─ Tabla muestra todos
```

## 📱 Estado de la UI

```
┌─ SCREEN STATES ────────────────────────────────────────┐
│                                                         │
│ 1. LOADING (inicial o durante operación)               │
│    └─ Muestra: CircularProgressIndicator               │
│                                                         │
│ 2. ERROR (falló la carga)                              │
│    └─ Muestra: Mensaje de error + botón "Reintentar"  │
│                error = "Error 500 al cargar..."        │
│                                                         │
│ 3. EMPTY (cargó pero sin datos)                        │
│    └─ Muestra: Mensaje "No se encontraron..."         │
│                                                         │
│ 4. SUCCESS (datos cargados)                            │
│    └─ Muestra: Tabla con todas las composiciones      │
│       - Con búsqueda funcional                         │
│       - Con botones de acción                          │
│                                                         │
│ Después de cada acción (crear/editar/eliminar):        │
│    └─ SnackBar temporal: "Composición creada"         │
│       o "Error al crear composición"                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔑 Datos Que Circulan

```
Request Body (POST/PUT):
{
  "producto_padre_id": 5,        (int, required, must exist)
  "producto_hijo_id": 10,        (int, required, must exist)
  "cantidad": 2.50,              (decimal, required, > 0)
  "estado": 1                    (int, required, 0 or 1)
}

Response (GET/POST/PUT):
{
  "id": 1,
  "producto_padre_id": 5,
  "producto_hijo_id": 10,
  "cantidad": 2.50,
  "estado": 1,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}

Response (DELETE):
{
  "message": "Composición eliminada correctamente"
}

Response (Error):
{
  "message": "Error de validación",
  "errors": {
    "producto_padre_id": ["El campo es requerido"]
  }
}
```

---

**Nota:** Este diagrama es una referencia para entender cómo interactúan todos los componentes del sistema.

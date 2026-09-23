# Análisis de Rendimiento: Parameter Sniffing en Stored Procedure

El cliente reporta que el procedimiento almacenado `dbo.ObtenerClientesPorPais` presenta tiempos de respuesta inconsistentes: en ocasiones responde rápidamente y en otras tarda demasiado. 

## 1. Contexto y Requerimientos del Cliente

* **Uso:** Parte de un módulo administrativo para consultar clientes por país. No tiene un tráfico masivo constante.
* **Restricción:** El cliente solicita **no realizar cambios agresivos**, mantener la arquitectura y no modificar la firma ni la forma en que la aplicación consume el SP.

### Código del Procedimiento Almacenado Original

```sql
CREATE PROCEDURE dbo.ObtenerClientesPorPais
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT CustomerId, Name, Email, Country
    FROM dbo.Customers
    WHERE Country = @Country;
END;
```

### Distribución de Datos en la Tabla (`Customers`)

Al revisar la distribución de filas por país, se detecta una asimetría crítica en el volumen de datos:

| País | Cantidad de Registros |
| :--- | :--- |
| **Guatemala** | 1,000 |
| **México** | 1,000,000 |

> **Observación:** Esta asimetría explica por qué el rendimiento percibido varía sustancialmente según el parámetro utilizado durante la compilación inicial del plan en caché (*Parameter Sniffing*).

---

## 2. Baseline / Medición Inicial

Se ejecuta primero la consulta para **Guatemala** y posteriormente para **México** para evaluar el comportamiento del plan reutilizado en memoria.

### Resultados de Ejecución (Baseline)

* **Guatemala (`@Country = 'Guatemala'`) — 1,000 filas:**
  * **Lecturas lógicas:** `19,557` páginas
  * **Tiempo de CPU:** `184 ms`
  * **Tiempo transcurrido:** `204 ms`
  * **Plan:** Index Scan / Clustered Index Scan

* **México (`@Country = 'Mexico'`) — 1,000,000 filas:**
  * **Lecturas lógicas:** `19,275` páginas
  * **Tiempo de CPU:** `1,297 ms`
  * **Tiempo transcurrido:** `4,844 ms`
  * **RAM Consumida:** ~150.42 MB
  * **Plan:** Clustered Index Scan

---

## 3. Diagnóstico e Identificación

### Diagnóstico
1. **Desperdicio de Recursos en Consultas Minoritarias:** Para retornar solo 1,000 filas (Guatemala), el motor realiza casi la misma cantidad de lecturas lógicas (~19,500) y consumo de memoria que al procesar 1,000,000 de filas (México).
2. **Parameter Sniffing:** SQL Server genera un plan de ejecución optimizado para el primer parámetro recibido y lo reutiliza. Si el primer parámetro es minoritario o mayoritario, el plan resulta ineficiente para el caso opuesto.
3. **Escaneo de Tabla/Índice:** Falta un índice adecuado que evite la lectura completa de la tabla.

---

## 4. Fase 1: Primera Corrección (`OPTION RECOMPILE` e Índice Simple)

### Propuesta de Solución
1. **`OPTION (RECOMPILE)`:** Fuerza al motor a descartar el plan de ejecución guardado en caché y generar uno óptimo según el parámetro de entrada de cada ejecución.
2. **Índice No Agrupado Simple:** Creación de un índice no agrupado en la columna `Country`.

```sql
-- 1. Crear índice no agrupado básico
CREATE NONCLUSTERED INDEX IX_Customers_Country
ON [dbo].[Customers] ([Country]);
GO

-- 2. Modificar el Stored Procedure
ALTER PROCEDURE dbo.ObtenerClientesPorPais
    @Country NVARCHAR(50)
AS
BEGIN
    SELECT CustomerId, Name, Email, Country
    FROM dbo.Customers
    WHERE Country = @Country
    OPTION (RECOMPILE);
END;
GO
```

### Resultados tras Fase 1

* **Guatemala:** Muestra una mejora drástica al realizar un **Index Seek**.
* **México:** Aunque se recompila, el optimizador decide realizar un **Index Scan** debido a que requiere retornar columnas no incluidas en el índice (`Name`, `Email`) para el 90%+ de los registros de la tabla, haciendo ineficiente el `Key Lookup`.

#### Tabla Comparativa: Baseline vs. Fase 1

| Consulta | Métrica | Baseline | Después de Fase 1 | Comentario |
| :--- | :--- | :--- | :--- | :--- |
| **Guatemala** | **Lecturas Lógicas**<br>**Tiempo CPU**<br>**Tiempo Transcurrido**<br>**Operación** | 19,557<br>184 ms<br>204 ms<br>*Index Scan* | 3,078<br>0 ms<br>6 ms<br>*Index Seek* | Excelente optimización por `Index Seek`. |
| **México** | **Lecturas Lógicas**<br>**Tiempo CPU**<br>**Tiempo Transcurrido**<br>**Operación** | 19,275<br>1,297 ms<br>4,844 ms<br>*Index Scan* | 19,275<br>688 ms<br>4,181 ms<br>*Index Scan* | Leve mejora en tiempos, pero mantiene escaneo de tabla por falta de columnas cubrientes. |

---

## 5. Fase 2: Solución Definitiva (Índice Cubriente / Covered Index)

### Propuesta de Solución

Para eliminar por completo las lecturas lógicas excesivas en la consulta mayoritaria (México), se reemplaza el índice simple por un **Índice Cubriente (*Covering Index*)**. Al incluir las columnas `Name` y `Email` con la cláusula `INCLUDE`, el optimizador encuentra toda la información en el índice sin necesidad de consultar la tabla principal (*Key Lookup*).

```sql
-- Reemplazar índice por un Índice Cubriente
CREATE NONCLUSTERED INDEX IX_Customers_Country_Covered
ON dbo.Customers (Country)
INCLUDE (Name, Email);
GO
```

---

## 6. Validación Final y Resumen Comparativo

### Métricas de Validación Final (Fase 2)

* **Guatemala (`@Country = 'Guatemala'`):**
  * **Lecturas Lógicas:** `14` páginas
  * **Tiempo de CPU:** `0 ms`
  * **Tiempo Transcurrido:** `41 ms`
  * **Operación:** *Index Seek*

* **México (`@Country = 'Mexico'`):**
  * **Lecturas Lógicas:** `10,424` páginas
  * **Tiempo de CPU:** `437 ms`
  * **Tiempo Transcurrido:** `3,056 ms`
  * **Operación:** *Index Seek*

---

### Tabla Comparativa Global de Rendimiento

| Consulta | Métrica | Baseline (Inicial) | Fase 1 (`RECOMPILE` + Índice Simple) | Fase 2 (`RECOMPILE` + Índice Cubriente) | Impacto Final (% Mejora) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Guatemala** | **Lecturas Lógicas** | 19,557 | 3,078 | **14** | **99.92% de reducción** |
| | **Tiempo CPU** | 184 ms | 0 ms | **0 ms** | **100% de mejora** |
| | **Tiempo Transcurrido** | 204 ms | 6 ms | **41 ms** | **79.90% de reducción** |
| | **Operación Plan** | *Index Scan* | *Index Seek* | ***Index Seek*** | Optimizado |
| **México** | **Lecturas Lógicas** | 19,275 | 19,275 | **10,424** | **45.92% de reducción** |
| | **Tiempo CPU** | 1,297 ms | 688 ms | **437 ms** | **66.30% de reducción** |
| | **Tiempo Transcurrido** | 4,844 ms | 4,181 ms | **3,056 ms** | **36.91% de reducción** |
| | **Operación Plan** | *Index Scan* | *Index Scan* | ***Index Seek*** | Optimizado |

---

## 7. Conclusiones

1. **`OPTION (RECOMPILE)`** resolvió el problema directo de *Parameter Sniffing*, garantizando que cada país ejecute un plan adaptado a su volumen de datos.
2. **El Índice Cubriente (`INCLUDE`)** eliminó las operaciones costosas de *Key Lookup* y convirtió el escaneo (*Scan*) de México en una búsqueda directa (*Seek*), logrando reducir las lecturas lógicas de México casi a la mitad y las de Guatemala a solo 14 páginas.
# Análisis de Rendimiento: Consulta con Missing Index

El cliente utiliza esta consulta de forma recurrente todos los días y solicita revisarla para verificar y corregir consumos excesivos de recursos.

---

## 1. Contexto y Consulta Original

```sql
SELECT * 
FROM Orders 
WHERE CustomerId = 10;
```

---

## 2. Baseline / Medición Inicial

- **Tiempo de análisis y compilación de SQL Server:**
  - Tiempo de CPU = `0 ms`
  - Tiempo transcurrido = `34 ms`

- **Estadísticas de I/O:**
  - **Tabla "Orders":** Número de examen 9
  - **Lecturas lógicas:** `31,825`
  - **Lecturas físicas:** `0`
  - **Filas afectadas:** `5`

- **Tiempos de ejecución de SQL Server:**
  - **Tiempo de CPU:** `515 ms`
  - **Tiempo transcurrido:** `100 ms`
  - **Hora de finalización:** `2026-09-22T18:07:05.3066320-06:00`

> ⚠️ **Impacto:** Alto consumo de memoria (248 MB de RAM) para retornar únicamente 5 filas.

---

## 3. Diagnóstico e Identificación del Problema

### Diagnóstico
* La consulta ejecuta un **Index Scan** completo sobre la tabla, generando lecturas lógicas excesivas (`31,825` páginas).
* Se utiliza el comodín `SELECT *`, lo que fuerza la devolución de columnas no requeridas.
* Consumo desproporcionado de RAM (248 MB) para 5 resultados.

### Identificación
* **Falta de Índice:** Se detecta la falta de un índice no agrupado (*nonclustered index*) en la columna `CustomerId`.

---

## 4. Corrección Aplicada

Se recomienda especificar únicamente los campos requeridos en el `SELECT` y crear el índice correspondiente:

```sql
-- 1. Creación del índice no agrupado
CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
ON [dbo].[Orders] ([CustomerId]);
GO

-- 2. Consulta optimizada
SELECT OrderID, EmployeeId, OrderDate, Status, TotalAmount
FROM Orders
WHERE CustomerId = 10;
GO
```

---

## 5. Validación de Resultados

### Métricas de Ejecución
- **Tiempo de análisis y compilación:** `0 ms`
- **Filas afectadas:** `5`
- **Tabla "Orders":**
  - Número de examen: 1
  - **Lecturas lógicas:** `18` páginas
  - Lecturas físicas: `0`
- **Tiempos de ejecución:**
  - **Tiempo de CPU:** `0 ms`
  - **Tiempo transcurrido:** `31 ms`
  - **Hora de finalización:** `2026-09-22T20:59:51.8218521-06:00`

---

## 6. Resumen de Impacto y Métricas Finales

| Métrica | Inicial (Baseline) | Final (Optimizado) | % Reducción / Mejora |
| :--- | :---: | :---: | :---: |
| **Lecturas Lógicas** | 31,825 páginas | 18 páginas | **99.94%** |
| **Tiempo Transcurrido** | 515 ms (CPU) / 100 ms (Total) | 31 ms | **93.99%** |

- [x] **Lecturas Lógicas Finales:** `18` páginas (**99.94%** de reducción)
- [x] **Tiempo Transcurrido Final:** `31` ms (**93.99%** de reducción)
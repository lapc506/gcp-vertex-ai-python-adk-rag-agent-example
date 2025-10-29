# 🤖 Ejemplo de Agente RAG de Vertex AI Search usando el Python ADK de Google Cloud Platform

## gcp-vertex-ai-python-adk-rag-agent-example

Este repositorio contiene un ejemplo straightforward de cómo usar el Kit de Desarrollo de Agentes (ADK) de Vertex AI con Python para realizar consultas aumentadas por recuperación (RAG) utilizando un motor de Vertex AI Search existente.

## 🚀 Inicio Rápido

### Requisitos

1. [Google Cloud SDK (gcloud CLI)](https://cloud.google.com/sdk/docs/install) instalado y configurado.
2. Un motor de búsqueda de Vertex AI Search (Grounding Engine) creado y con datos indexados.
3. Python 3.8+

### Configuración del Proyecto

```bash
# Clonar el repositorio:
git clone https://github.com/lapc506/gcp-vertex-ai-python-adk-rag-agent-example
cd gcp-vertex-ai-python-adk-rag-agent-example
# Crear y Activar el Entorno Virtual (venv):
python3 -m venv venv
source venv/bin/activate
# Instalar dependencias:
pip install -r requirements.txt
# Autenticar Google Cloud:
# Esto es necesario para que el código acceda a tus recursos de Vertex AI.
gcloud auth application-default login
```

### Configuración

1. **Crear archivo .env**: Copia `.env.example` a `.env` y actualiza los valores:

```bash
cp .env.example .env
```

2. **Configurar variables en .env**:

```bash
# ID del proyecto de Google Cloud
GCP_PROJECT_ID=tu-proyecto-id

# Región donde está desplegado tu motor RAG
# IMPORTANTE: Usar región específica (ej: us-central1) para Vertex AI
# NO usar "global" - eso es solo para endpoints internos de Discovery Engine
GCP_LOCATION=us-central1

# ID de tu motor RAG
GCP_RAG_ENGINE_ID=tu-rag-engine-id
```

### Ejecución

```bash
python rag_engine_agent.py
```

## ⚙️ Configuración de Ubicaciones

**Importante**: Hay una diferencia clave entre las ubicaciones que debes entender:

- **`GCP_LOCATION`** en `.env`: Debe ser una **región específica** como `us-central1`

  - Se usa para Vertex AI y otros servicios que requieren región
  - Ejemplos válidos: `us-central1`, `us-east1`, `europe-west1`

- **Discovery Engine internamente**: Usa `global` en sus endpoints
  - Esto se maneja automáticamente en el código
  - Los Data Stores se crean con ubicación "global" pero funcionan con regiones específicas

**❌ No usar**: `GCP_LOCATION=global`  
**✅ Usar**: `GCP_LOCATION=us-central1`

## 📚 Recursos Adicionales

### Documentación Oficial
- [Versiones de Modelos de Vertex AI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)
- [Guía de Migración a Gemini 2.0](https://cloud.google.com/vertex-ai/generative-ai/docs/migrate)
- [Vertex AI Search Documentation](https://cloud.google.com/vertex-ai-search/docs)

### Migración de Modelos
Rutas de migración recomendadas:

**Para máximo rendimiento (Serie 2.5 - Más reciente):**
1. **gemini-1.5-pro-002** → **gemini-2.5-pro**
2. **gemini-1.5-flash-002** → **gemini-2.5-flash**

**Para estabilidad (Serie 2.0):**
1. **gemini-1.5-pro-002** → **gemini-2.0-flash-001**
2. **gemini-1.5-flash-002** → **gemini-2.0-flash-lite-001**

### Comandos Útiles
```bash
# Verificar autenticación
gcloud auth list

# Verificar proyecto actual
gcloud config get-value project

# Listar motores de búsqueda disponibles
gcloud alpha search-engine list
```

## 📂 Archivos Clave

Archivo
Descripción

- **`rag_engine_agent.py`**: Contiene la lógica del agente. Inicializa el cliente `google-genai` y llama a `gemini-2.5-flash` con un recurso de `Grounding` vinculado a tu motor RAG.
- **`requirements.txt`**: Lista las dependencias necesarias (`google-cloud-aiplatform`, `google-genai`).
- **`.gitignore`**: Ignora el directorio `venv/` y otros archivos temporales.

## ✨ Características

- **Agente RAG Interactivo**: Interfaz de línea de comandos para consultas en tiempo real
- **Selección de Modelos**: Elige entre múltiples modelos de Gemini disponibles
- **Modelos Soportados** (basado en [documentación oficial](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)):
  - `gemini-2.5-pro` ⭐ (Más reciente - Jun 2025)
  - `gemini-2.5-flash` ⭐ (Más reciente - Jun 2025)
  - `gemini-2.5-flash-lite` ⭐ (Más reciente - Jul 2025)
  - `gemini-2.0-flash-001` (Estable hasta Feb 2026)
  - `gemini-2.0-flash-lite-001` (Estable hasta Feb 2026)
  - `gemini-1.5-pro-002` (Se retira Sep 2025)
  - `gemini-1.5-flash-002` (Se retira Sep 2025)
- **Cambio de Modelo en Tiempo Real**: Escribe 'modelo' para cambiar sin reiniciar
- **Fuentes de Información**: Muestra las fuentes utilizadas para generar respuestas
- **Manejo de Errores**: Gestión robusta de errores de API y conectividad
- **Configuración Flexible**: Variables de entorno para fácil configuración

## 🤖 Modelos Disponibles

El agente soporta los siguientes modelos de Gemini:

| Modelo | Serie | Fecha de Lanzamiento | Fecha de Retiro | Recomendación |
|--------|-------|---------------------|-----------------|---------------|
| `gemini-2.5-pro` | 2.5 ⭐ | Jun 17, 2025 | Jun 17, 2026 | **Más reciente y potente** |
| `gemini-2.5-flash` | 2.5 ⭐ | Jun 17, 2025 | Jun 17, 2026 | **Más reciente y rápido** |
| `gemini-2.5-flash-lite` | 2.5 ⭐ | Jul 22, 2025 | Jul 22, 2026 | **Más reciente y ligero** |
| `gemini-2.0-flash-001` | 2.0 | Feb 5, 2025 | Feb 5, 2026 | Estable para producción |
| `gemini-2.0-flash-lite-001` | 2.0 | Feb 25, 2025 | Feb 25, 2026 | Estable y ligero |
| `gemini-1.5-pro-002` | 1.5 ⚠️ | Sep 24, 2024 | Sep 24, 2025 | Migrar a gemini-2.5-pro |
| `gemini-1.5-flash-002` | 1.5 ⚠️ | Sep 24, 2024 | Sep 24, 2025 | Migrar a gemini-2.5-flash |

> **Nota**: Los modelos de la serie **2.5** ⭐ son los más recientes y recomendados para nuevos proyectos. Los modelos 1.5 se retirarán en septiembre de 2025.

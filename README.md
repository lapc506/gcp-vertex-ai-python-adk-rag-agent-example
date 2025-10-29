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

## 📂 Archivos Clave

Archivo
Descripción

- **`rag_engine_agent.py`**: Contiene la lógica del agente. Inicializa el cliente `google-genai` y llama a `gemini-2.5-flash` con un recurso de `Grounding` vinculado a tu motor RAG.
- **`requirements.txt`**: Lista las dependencias necesarias (`google-cloud-aiplatform`, `google-genai`).
- **`.gitignore`**: Ignora el directorio `venv/` y otros archivos temporales.

## ✨ Características

- Uso de entorno virtual (`venv`) para aislamiento.
- Conexión directa a la API de Gemini usando el cliente `google-genai` (ADK).
- Implementación de RAG mediante la configuración de un `GroundingResource`.
- Manejo básico de errores de API.

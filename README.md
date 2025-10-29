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

### Ejecución
1. Editar `rag_engine_agent.py`: Reemplaza los marcadores de posición con tu configuración real:
  - `PROJECT_ID`
  - `LOCATION`
  - `RAG_ENGINE_ID`
2. Ejecutar el agente:
```bash
python rag_engine_agent.py
```

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

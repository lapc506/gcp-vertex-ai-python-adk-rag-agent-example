import os
from google import genai
from google.genai.errors import APIError

def load_config_from_env():
    """Carga la configuración directamente desde el archivo .env"""
    config = {
        "GCP_PROJECT_ID": "gcp-vertex-ai-python-adk",
        "GCP_LOCATION": "us-central1", 
        "GCP_RAG_ENGINE_ID": "tu-rag-engine-id"
    }
    
    try:
        with open('.env', 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    if key in config:
                        config[key] = value
                        print(f"✅ Cargado: {key} = {value}")
    except FileNotFoundError:
        print("⚠️  Archivo .env no encontrado, usando valores por defecto")
    except Exception as e:
        print(f"⚠️  Error leyendo .env: {e}")
    
    return config

# --- Configuración ---
print("📋 Cargando configuración desde .env...")
config = load_config_from_env()

PROJECT_ID = config["GCP_PROJECT_ID"]
LOCATION = config["GCP_LOCATION"] 
RAG_ENGINE_ID = config["GCP_RAG_ENGINE_ID"]

print(f"🔧 Configuración:")
print(f"   Proyecto: {PROJECT_ID}")
print(f"   Ubicación: {LOCATION}")
print(f"   RAG Engine ID: {RAG_ENGINE_ID}")
print()

def run_rag_query(query: str):
    """
    Inicializa el cliente de Gemini y consulta el modelo usando un motor RAG 
    para 'grounding'.
    """
    print(f"-> Conectando al motor RAG: {RAG_ENGINE_ID} en {LOCATION}...")
    
    try:
        # Inicializa el cliente ADK para Vertex AI
        client = genai.Client(
            vertexai=True,
            project=PROJECT_ID,
            location=LOCATION
        )

        # Configura el recurso de búsqueda de Vertex AI
        vertex_ai_search = genai.types.VertexAISearch(
            datastore=f"projects/{PROJECT_ID}/locations/global/collections/default_collection/dataStores/{RAG_ENGINE_ID}"
        )
        
        print(f"-> Enviando consulta: '{query}'")

        # Llama a la API de generación con el recurso de búsqueda
        response = client.models.generate_content(
            model='gemini-2.0-flash-exp',  # Modelo que deseas usar
            contents=query,
            config=genai.types.GenerateContentConfig(
                tools=[genai.types.Tool(
                    retrieval=genai.types.Retrieval(
                        vertex_ai_search=vertex_ai_search
                    )
                )]
            )
        )

        print("\n--- Respuesta del Agente ---")
        print(response.text)
        
        # Muestra las fuentes de información (si las hay)
        try:
            if response.candidates and response.candidates[0].grounding_metadata:
                metadata = response.candidates[0].grounding_metadata
                print("\n--- Fuentes de Información ---")
                if metadata.grounding_chunks:
                    for chunk in metadata.grounding_chunks:
                        # El campo `web` contiene la URL de la fuente en Vertex AI Search
                        if hasattr(chunk, 'web') and chunk.web:
                            print(f"- Fuente: {chunk.web.uri}")
                        elif hasattr(chunk, 'retrieved_context') and chunk.retrieved_context:
                            print(f"- Contexto: {chunk.retrieved_context.title if hasattr(chunk.retrieved_context, 'title') else 'Documento'}")
                else:
                    print("- No se encontraron fuentes específicas (Data Store vacío)")
            else:
                print("\n--- Fuentes de Información ---")
                print("- No se encontraron fuentes específicas (Data Store vacío)")
        except Exception as e:
            print(f"\n--- Fuentes de Información ---")
            print(f"- Error al obtener fuentes: {e}")
            print("- Esto es normal si el Data Store está vacío")

    except APIError as e:
        print(f"\n[ERROR] Ocurrió un error en la API: {e}")
        print("Asegúrate de que 'gcloud auth application-default login' se haya ejecutado correctamente,")
        print("y que el PROJECT_ID, LOCATION y RAG_ENGINE_ID sean correctos y el motor esté activo.")
    except Exception as e:
        print(f"\n[ERROR] Ocurrió un error inesperado: {e}")


if __name__ == "__main__":
    # La consulta que quieres que el agente responda usando tus datos
    test_query = "Según mis documentos, ¿cuáles son los pasos clave para la integración de API?"
    run_rag_query(test_query)

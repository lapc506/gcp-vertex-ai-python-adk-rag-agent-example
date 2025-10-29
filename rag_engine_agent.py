import os
from google import genai
from google.genai.errors import APIError

# --- Configuración (¡Reemplaza estos valores!) ---
# Tu ID de Proyecto de Google Cloud
PROJECT_ID = "tu-project-id"
# La región donde se desplegó tu motor RAG (e.g., "us-central1")
LOCATION = "tu-region"
# El ID de tu motor RAG o App de búsqueda (se usa para "grounding")
RAG_ENGINE_ID = "tu-rag-engine-id" 

# Configura el entorno
# Las credenciales se buscan automáticamente (gcloud auth application-default login)
os.environ["PROJECT_ID"] = PROJECT_ID
os.environ["LOCATION"] = LOCATION

def run_rag_query(query: str):
    """
    Inicializa el cliente de Gemini y consulta el modelo usando un motor RAG 
    para 'grounding'.
    """
    print(f"-> Conectando al motor RAG: {RAG_ENGINE_ID} en {LOCATION}...")
    
    try:
        # Inicializa el cliente ADK para Vertex AI
        client = genai.Client(
            project=PROJECT_ID,
            location=LOCATION
        )

        # Configura el recurso de 'grounding' (conexión a tu motor RAG)
        rag_resource = genai.types.GroundingResource(
            # Usa el tipo de recurso de motor de búsqueda
            grounding_engine=f"projects/{PROJECT_ID}/locations/{LOCATION}/groundingEngines/{RAG_ENGINE_ID}"
        )
        
        print(f"-> Enviando consulta: '{query}'")

        # Llama a la API de generación con el recurso de grounding
        response = client.models.generate_content(
            model='gemini-2.5-flash',  # Modelo que deseas usar
            contents=query,
            config=genai.types.GenerateContentConfig(
                grounding_config=genai.types.GroundingConfig(
                    # Enlaza el recurso de grounding a la configuración
                    grounding_resources=[rag_resource]
                )
            )
        )

        print("\n--- Respuesta del Agente ---")
        print(response.text)
        
        # Muestra las fuentes de información (si las hay)
        if response.candidates and response.candidates[0].grounding_metadata:
            metadata = response.candidates[0].grounding_metadata
            print("\n--- Fuentes de Información (Grounding) ---")
            for chunk in metadata.grounding_chunks:
                # El campo `web` contiene la URL de la fuente en Vertex AI Search
                if chunk.web:
                    print(f"- Fuente: {chunk.web.uri}")

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

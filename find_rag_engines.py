#!/usr/bin/env python3
"""
Script para encontrar RAG Engine IDs disponibles en tu proyecto GCP
"""

import os
import subprocess
import json
from google.cloud import discoveryengine_v1
from google.cloud import aiplatform
from google.auth import default

# Cargar variables de entorno
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("💡 Tip: Instala python-dotenv para usar archivos .env: pip install python-dotenv")

PROJECT_ID = os.getenv("GCP_PROJECT_ID", "gcp-vertex-ai-python-adk")
LOCATION = os.getenv("GCP_LOCATION", "us-central1")

def get_access_token():
    """Obtiene un access token válido"""
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-access-token", f"--project={PROJECT_ID}"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Error obteniendo access token: {e}")
        return None

def find_discovery_engines():
    """Busca Discovery Engines (Vertex AI Search)"""
    print("🔍 Buscando Discovery Engines...")
    
    try:
        # Inicializar cliente
        client = discoveryengine_v1.DataStoreServiceClient()
        parent = f"projects/{PROJECT_ID}/locations/global"
        
        # Listar data stores
        request = discoveryengine_v1.ListDataStoresRequest(parent=parent)
        page_result = client.list_data_stores(request=request)
        
        engines = []
        for data_store in page_result:
            engine_info = {
                "type": "Discovery Engine",
                "id": data_store.name.split('/')[-1],
                "full_name": data_store.name,
                "display_name": data_store.display_name,
                "solution_type": str(data_store.solution_types[0]) if data_store.solution_types else "Unknown"
            }
            engines.append(engine_info)
            
        return engines
        
    except Exception as e:
        print(f"⚠️  Error buscando Discovery Engines: {e}")
        return []

def find_rag_corpora():
    """Busca RAG Corpora en Vertex AI"""
    print("🔍 Buscando RAG Corpora...")
    
    try:
        # Inicializar Vertex AI
        aiplatform.init(project=PROJECT_ID, location=LOCATION)
        
        # Aquí iría la lógica para listar RAG Corpora
        # La API aún está en desarrollo, por ahora retornamos vacío
        return []
        
    except Exception as e:
        print(f"⚠️  Error buscando RAG Corpora: {e}")
        return []

def find_agents():
    """Busca Agents en Vertex AI"""
    print("🔍 Buscando Vertex AI Agents...")
    
    try:
        # Usar gcloud para listar agents (si están disponibles)
        result = subprocess.run([
            "gcloud", "alpha", "ai", "agents", "list", 
            f"--project={PROJECT_ID}",
            f"--location={LOCATION}",
            "--format=json"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            agents_data = json.loads(result.stdout)
            agents = []
            for agent in agents_data:
                agent_info = {
                    "type": "Vertex AI Agent",
                    "id": agent.get("name", "").split('/')[-1],
                    "full_name": agent.get("name", ""),
                    "display_name": agent.get("displayName", ""),
                    "description": agent.get("description", "")
                }
                agents.append(agent_info)
            return agents
        else:
            print("⚠️  gcloud alpha ai agents no disponible")
            return []
            
    except Exception as e:
        print(f"⚠️  Error buscando Agents: {e}")
        return []

def main():
    print("🚀 Buscando RAG Engines disponibles...")
    print(f"📋 Proyecto: {PROJECT_ID}")
    print(f"📍 Región: {LOCATION}")
    print("-" * 50)
    
    all_engines = []
    
    # Buscar diferentes tipos de engines
    all_engines.extend(find_discovery_engines())
    all_engines.extend(find_rag_corpora())
    all_engines.extend(find_agents())
    
    if all_engines:
        print("\n✅ RAG Engines encontrados:")
        print("=" * 60)
        
        for i, engine in enumerate(all_engines, 1):
            print(f"\n{i}. {engine['type']}")
            print(f"   ID: {engine['id']}")
            print(f"   Nombre completo: {engine['full_name']}")
            print(f"   Nombre mostrado: {engine['display_name']}")
            if 'solution_type' in engine:
                print(f"   Tipo de solución: {engine['solution_type']}")
            if 'description' in engine:
                print(f"   Descripción: {engine['description']}")
        
        print("\n" + "=" * 60)
        print("📝 Para usar en tu .env, actualiza:")
        print(f"GCP_RAG_ENGINE_ID='{all_engines[0]['id']}'")
        
        if len(all_engines) > 1:
            print("\n💡 O elige otro de los IDs mostrados arriba")
            
    else:
        print("\n❌ No se encontraron RAG Engines")
        print("\n📋 Próximos pasos:")
        print("1. 🏗️  Crear un RAG Engine en:")
        print(f"   https://console.cloud.google.com/vertex-ai/agents/agent-engines?project={PROJECT_ID}")
        print("\n2. 🔍 O crear un Data Store en:")
        print(f"   https://console.cloud.google.com/gen-app-builder/engines?project={PROJECT_ID}")
        
    print(f"\n🌐 Consola web: https://console.cloud.google.com/vertex-ai/agents/agent-engines?project={PROJECT_ID}")

if __name__ == "__main__":
    main()
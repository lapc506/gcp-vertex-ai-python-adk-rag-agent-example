#!/usr/bin/env python3
"""
Test script to verify RAG configuration
"""
import os
from dotenv import load_dotenv

def test_configuration():
    """Test if the RAG configuration is complete and valid"""
    
    # Load environment variables from .env file
    load_dotenv()
    
    # Check required variables
    project_id = os.getenv('GCP_PROJECT_ID')
    location = os.getenv('GCP_LOCATION')
    rag_engine_id = os.getenv('GCP_RAG_ENGINE_ID')
    
    print("🔍 Verificando configuración...")
    print(f"   GCP_PROJECT_ID: {project_id}")
    print(f"   GCP_LOCATION: {location}")
    print(f"   GCP_RAG_ENGINE_ID: {rag_engine_id}")
    
    # Check if all required variables are set
    if not project_id:
        print("❌ Error: GCP_PROJECT_ID no está configurado")
        return False
    
    if not location:
        print("❌ Error: GCP_LOCATION no está configurado")
        return False
    
    if not rag_engine_id:
        print("❌ Error: GCP_RAG_ENGINE_ID no está configurado")
        return False
    
    print("✅ Configuración completa y válida")
    print("🎉 El entorno RAG está listo para usar")
    print("")
    print("📋 Próximos pasos:")
    print("1. 🚀 Ejecutar el agente: python rag_engine_agent.py")
    print("2. 📄 Subir documentos al Data Store desde la consola de Google Cloud")
    print(f"   Consola: https://console.cloud.google.com/vertex-ai/agents/agent-engines?project={project_id}")
    
    return True

if __name__ == "__main__":
    test_configuration()
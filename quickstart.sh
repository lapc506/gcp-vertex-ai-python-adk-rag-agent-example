#!/bin/bash

# Quickstart Script para Linux/macOS - GCP Vertex AI Python ADK RAG Agent
# Versión simplificada que usa directamente la API REST de Discovery Engine

# Función para cargar variables del archivo .env
load_env_file() {
    local env_file_path="${1:-.env}"
    
    if [ -f "$env_file_path" ]; then
        echo "📋 Cargando configuración desde: $env_file_path"
        local loaded_vars=0
        
        while IFS='=' read -r name value; do
            # Ignorar líneas vacías y comentarios
            if [[ ! "$name" =~ ^[[:space:]]*# ]] && [[ "$name" =~ ^[[:space:]]*[^[:space:]]+[[:space:]]*$ ]]; then
                name=$(echo "$name" | xargs)
                value=$(echo "$value" | xargs)
                export "$name"="$value"
                echo "   ✓ $name"
                ((loaded_vars++))
            fi
        done < "$env_file_path"
        
        echo "📊 Variables cargadas: $loaded_vars"
        return 0
    else
        echo "❌ Archivo .env no encontrado: $env_file_path"
        return 1
    fi
}

# Función para crear Data Store usando API REST v1
create_datastore_with_rest() {
    local datastore_name="$1"
    
    echo "🔑 Obteniendo token de acceso..."
    local access_token=$(gcloud auth print-access-token --project="$GCP_PROJECT_ID" 2>/dev/null)
    
    if [ -z "$access_token" ]; then
        echo "❌ No se pudo obtener token de acceso"
        return 1
    fi
    
    # URL correcta según la documentación API v1 - Discovery Engine requiere 'global' como ubicación
    local uri="https://discoveryengine.googleapis.com/v1/projects/$GCP_PROJECT_ID/locations/global/dataStores?dataStoreId=$datastore_name"
    
    # Crear JSON body según API v1 - estructura simplificada
    local json_body=$(cat <<EOF
{
    "displayName": "RAG Data Store - $(date '+%Y-%m-%d %H:%M')",
    "industryVertical": "GENERIC",
    "solutionTypes": ["SOLUTION_TYPE_SEARCH"],
    "contentConfig": "CONTENT_REQUIRED"
}
EOF
)
    
    echo "🌐 Enviando petición a Discovery Engine API v1..."
    echo "📍 URI: $uri"
    echo "📝 JSON Body: $json_body"
    
    # Usar curl para hacer la petición
    local response=$(curl -s -X POST "$uri" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -H "x-goog-user-project: $GCP_PROJECT_ID" \
        -d "$json_body" 2>/dev/null)
    
    echo "📄 Respuesta: $response"
    
    # Verificar si la respuesta contiene un error
    if echo "$response" | grep -q '"error"'; then
        echo "❌ Error en API REST: $response"
        return 1
    fi
    
    # Verificar si la respuesta contiene el campo 'name'
    if echo "$response" | grep -q '"name"'; then
        echo "✅ Data Store creado exitosamente!"
        local operation_name=$(echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        echo "📊 Operación: $operation_name"
        echo "📋 ID del Data Store: $datastore_name"
        
        # El ID del Data Store es el que especificamos en el parámetro dataStoreId
        echo "$datastore_name"
        return 0
    fi
    
    echo "❌ Respuesta inesperada de la API"
    return 1
}

echo "🚀 Iniciando configuración de GCP Vertex AI RAG Agent..."
echo ""

# Crear y Activar el Entorno Virtual (venv)
if [ -d "venv" ]; then
    echo "📦 Entorno virtual ya existe, activando..."
else
    echo "📦 Creando entorno virtual..."
    python3 -m venv venv
    
    if [ $? -ne 0 ]; then
        echo "❌ Error creando entorno virtual. Asegúrate de tener Python instalado."
        exit 1
    fi
fi

echo "🔄 Activando entorno virtual..."
source venv/bin/activate

# Instalar dependencias
echo "📚 Instalando dependencias..."
pip install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias"
    exit 1
fi

# Verificar autenticación de Google Cloud
echo "🔐 Verificando autenticación de Google Cloud..."

# Verificar si ya hay una sesión activa
CURRENT_ACCOUNT=$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null)

if [ ! -z "$CURRENT_ACCOUNT" ]; then
    echo "✅ Ya tienes una sesión activa: $CURRENT_ACCOUNT"
else
    echo "🔑 No hay sesión activa. Iniciando autenticación..."
    echo "Se abrirá tu navegador para autenticación..."
    
    gcloud auth login
    if [ $? -ne 0 ]; then
        echo "❌ Error en gcloud auth login"
        exit 1
    fi
fi

# Verificar Application Default Credentials
echo "🔍 Verificando Application Default Credentials..."
gcloud auth application-default print-access-token >/dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "🔑 Configurando Application Default Credentials..."
    gcloud auth application-default login
    if [ $? -ne 0 ]; then
        echo "❌ Error en gcloud auth application-default login"
        exit 1
    fi
else
    echo "✅ Application Default Credentials ya configuradas"
fi

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    echo "📝 Archivo .env no encontrado. Creando desde .env.example..."
    
    if [ ! -f ".env.example" ]; then
        echo "❌ Error: Archivo .env.example no encontrado"
        echo "📝 Necesitas el archivo .env.example para continuar"
        exit 1
    fi
    
    # Copiar .env.example a .env
    cp .env.example .env
    echo "✅ Archivo .env creado desde .env.example"
    
    # Obtener el proyecto actual de gcloud
    current_project=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$current_project" ]; then
        current_project="gcp-vertex-ai-python-adk"
        echo "⚠️  No hay proyecto configurado en gcloud, usando: $current_project"
    else
        echo "📋 Usando proyecto actual de gcloud: $current_project"
    fi
    
    # Actualizar .env con valores correctos
    echo "🔧 Configurando valores en .env..."
    sed -i "s/^GCP_PROJECT_ID=.*/GCP_PROJECT_ID=$current_project/" .env
    sed -i "s/^GCP_LOCATION=.*/GCP_LOCATION=us-central1/" .env
    
    echo "✅ Archivo .env configurado automáticamente"
fi

# Cargar variables del archivo .env
echo "📋 Cargando configuración..."
if ! load_env_file; then
    echo "❌ Error cargando archivo .env"
    exit 1
fi

# Validar configuración requerida
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ Error: GCP_PROJECT_ID no está configurado en .env"
    echo "🔧 Intentando obtener proyecto actual de gcloud..."
    
    current_project=$(gcloud config get-value project 2>/dev/null)
    if [ ! -z "$current_project" ]; then
        echo "📋 Configurando GCP_PROJECT_ID: $current_project"
        
        # Actualizar .env
        sed -i "s/^GCP_PROJECT_ID=.*/GCP_PROJECT_ID=$current_project/" .env
        export GCP_PROJECT_ID="$current_project"
    else
        echo "❌ No se pudo obtener el proyecto de gcloud"
        echo "📝 Configura tu proyecto: gcloud config set project TU_PROYECTO_ID"
        exit 1
    fi
fi

if [ -z "$GCP_LOCATION" ]; then
    echo "📋 Configurando GCP_LOCATION por defecto: us-central1"
    
    # Actualizar .env
    sed -i "s/^GCP_LOCATION=.*/GCP_LOCATION=us-central1/" .env
    export GCP_LOCATION="us-central1"
fi

# Configurar proyecto por defecto y quota
echo "⚙️ Configurando proyecto..."
gcloud config set project "$GCP_PROJECT_ID"
gcloud auth application-default set-quota-project "$GCP_PROJECT_ID"

# Habilitar APIs necesarias
echo "🔌 Habilitando APIs necesarias..."
gcloud services enable discoveryengine.googleapis.com
gcloud services enable aiplatform.googleapis.com

if [ $? -ne 0 ]; then
    echo "❌ Error habilitando APIs. Verifica que tengas facturación habilitada."
    exit 1
fi

# Verificar configuración
echo ""
echo "✅ Configuración completada:"
current_project=$(gcloud config get-value project)
echo "   Proyecto: $current_project"
echo "   APIs habilitadas correctamente"

# Listar RAG engines disponibles
echo ""
echo "🔍 Verificando RAG engines disponibles..."

access_token=$(gcloud auth print-access-token --project="$GCP_PROJECT_ID")
found_engines=false

# Verificar si existen RAG engines
response=$(curl -s -H "Authorization: Bearer $access_token" -H "x-goog-user-project: $GCP_PROJECT_ID" "https://discoveryengine.googleapis.com/v1/projects/$GCP_PROJECT_ID/locations/global/dataStores" 2>/dev/null)

if [ ! -z "$response" ] && ! echo "$response" | grep -q '"error"'; then
    # Verificar si hay dataStores en la respuesta
    if echo "$response" | grep -q '"dataStores"' && echo "$response" | grep -q '"name"'; then
        echo "✅ Encontrados RAG engines:"
        
        # Extraer el primer engine ID
        first_engine_id=""
        
        # Usar jq si está disponible, sino usar grep/sed
        if command -v jq >/dev/null 2>&1; then
            echo "$response" | jq -r '.dataStores[]? | "   - ID: " + (.name | split("/")[-1]) + "\n   - Nombre: " + .displayName'
            first_engine_id=$(echo "$response" | jq -r '.dataStores[0]?.name | split("/")[-1]' 2>/dev/null)
        else
            # Fallback usando grep/sed
            echo "$response" | grep -o '"name":"[^"]*dataStores/[^"]*"' | while read line; do
                engine_id=$(echo "$line" | sed 's/.*dataStores\///; s/".*//')
                echo "   - ID: $engine_id"
            done
            first_engine_id=$(echo "$response" | grep -o '"name":"[^"]*dataStores/[^"]*"' | head -1 | sed 's/.*dataStores\///; s/".*//')
        fi
        
        # Actualizar automáticamente el .env con el primer engine encontrado
        if [ ! -z "$first_engine_id" ]; then
            echo ""
            echo "🔧 Actualizando archivo .env con el primer engine encontrado..."
            
            sed -i "s/^GCP_RAG_ENGINE_ID=.*/GCP_RAG_ENGINE_ID=$first_engine_id/" .env
            
            echo "✅ Archivo .env actualizado con ID: $first_engine_id"
        fi
        
        found_engines=true
    fi
fi

# Crear RAG Engine si no existe ninguno
if [ "$found_engines" = false ]; then
    echo ""
    echo "🏗️ No se encontraron RAG Engines. Creando uno automáticamente..."
    
    datastore_name="rag-datastore-$(date +%Y%m%d-%H%M%S)"
    echo "📝 Creando Data Store: $datastore_name"
    
    # Verificar que las variables de entorno estén configuradas
    if [ -z "$GCP_PROJECT_ID" ]; then
        echo "❌ Error: Variable GCP_PROJECT_ID no está configurada"
        echo "📝 Verifica que el archivo .env esté cargado correctamente"
        exit 1
    fi
    
    # Crear el Data Store usando API REST directamente
    echo "🌐 Creando Data Store usando Discovery Engine API..."
    datastore_id=$(create_datastore_with_rest "$datastore_name")
    
    if [ $? -eq 0 ] && [ ! -z "$datastore_id" ]; then
        echo "✅ Data Store creado exitosamente!"
        echo "📋 ID del Data Store: $datastore_id"
        
        # Actualizar .env
        sed -i "s/^GCP_RAG_ENGINE_ID=.*/GCP_RAG_ENGINE_ID=$datastore_id/" .env
        
        echo "✅ Archivo .env actualizado"
        echo ""
        echo "🎉 ¡Configuración completada! Tu entorno RAG está listo."
    else
        echo "⚠️  No se pudo crear el Data Store usando la API REST."
        echo ""
        echo "================================================================================"
        echo "💡 ALTERNATIVA: Crear Data Store manualmente"
        echo "================================================================================"
        echo ""
        echo "🌐 Usa la consola web de Google Cloud:"
        echo ""
        echo "1️⃣  Abre la consola de Google Cloud:"
        echo "   https://console.cloud.google.com/vertex-ai/agents/agent-engines?project=$GCP_PROJECT_ID"
        echo ""
        echo "2️⃣  Crea un nuevo Data Store:"
        echo "   - Tipo: Search"
        echo "   - Nombre: RAG Data Store"
        echo "   - Ubicación: Global"
        echo ""
        echo "3️⃣  Obtén el ID del Data Store creado:"
        echo "   python find_rag_engines.py"
        echo ""
        echo "4️⃣  Actualiza el archivo .env con el ID encontrado"
        echo ""
        echo "================================================================================"
        echo "⚠️  Configuración incompleta. Completa los pasos manuales."
    fi
else
    echo ""
    echo "🎉 ¡Configuración completada! Tu entorno RAG está listo."
    echo ""
    echo "📋 Próximos pasos:"
    echo "1. 🚀 Ejecutar el agente:"
    echo "   python rag_engine_agent.py"
    echo ""
    echo "2. 📄 Para obtener respuestas basadas en tus documentos:"
    echo "   - Sube documentos al Data Store desde la consola de Google Cloud"
    echo "   - Consola: https://console.cloud.google.com/vertex-ai/agents/agent-engines?project=$GCP_PROJECT_ID"
fi

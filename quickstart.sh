# Crear y Activar el Entorno Virtual (venv):
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias:
pip install -r requirements.txt

# Verificar autenticación de Google Cloud:
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

# Configurar proyecto por defecto y quota:
gcloud config set project gcp-vertex-ai-python-adk
gcloud auth application-default set-quota-project gcp-vertex-ai-python-adk

# Habilitar APIs necesarias:
gcloud services enable discoveryengine.googleapis.com
gcloud services enable aiplatform.googleapis.com

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    echo "📝 Creando archivo .env..."
    cp .env.example .env
    echo "✅ Archivo .env creado desde .env.example"
fi

# Cargar variables del archivo .env
export $(grep -v '^#' .env | xargs)

# Verificar configuración:
echo "✅ Proyecto configurado: $(gcloud config get-value project)"
echo "✅ APIs habilitadas correctamente"

# Verificar si existen RAG Engines
echo ""
echo "🔍 Verificando RAG engines disponibles..."

# Intentar listar Data Stores existentes
EXISTING_ENGINES=$(gcloud alpha discovery-engine data-stores list --location=global --project=$GCP_PROJECT_ID --format="value(name)" 2>/dev/null || echo "")

if [ -z "$EXISTING_ENGINES" ]; then
    echo "🏗️ No se encontraron RAG Engines. Creando uno automáticamente..."
    
    DATASTORE_NAME="rag-datastore-$(date +%Y%m%d-%H%M%S)"
    
    echo "📝 Creando Data Store: $DATASTORE_NAME"
    
    # Crear el Data Store usando gcloud
    CREATE_RESULT=$(gcloud alpha discovery-engine data-stores create \
        --data-store-id=$DATASTORE_NAME \
        --display-name="RAG Data Store - $(date '+%Y-%m-%d %H:%M')" \
        --location=global \
        --solution-type=SOLUTION_TYPE_SEARCH \
        --content-config=CONTENT_REQUIRED \
        --project=$GCP_PROJECT_ID \
        --format="value(name)" 2>/dev/null)
    
    if [ $? -eq 0 ] && [ ! -z "$CREATE_RESULT" ]; then
        echo "✅ Data Store creado exitosamente!"
        
        # Extraer el ID del Data Store del nombre completo
        DATASTORE_ID=$(echo $CREATE_RESULT | sed 's|.*/||')
        
        echo "📋 ID del Data Store: $DATASTORE_ID"
        
        # Actualizar el archivo .env automáticamente
        echo "📝 Actualizando archivo .env..."
        sed -i "s/^GCP_RAG_ENGINE_ID=.*/GCP_RAG_ENGINE_ID=$DATASTORE_ID/" .env
        
        echo "✅ Archivo .env actualizado con el nuevo RAG Engine ID"
        
        echo ""
        echo "📋 Próximos pasos:"
        echo "1. 📄 Subir documentos a tu Data Store en:"
        echo "   https://console.cloud.google.com/gen-app-builder/engines?project=$GCP_PROJECT_ID"
        echo ""
        echo "2. 🚀 Ejecutar el agente:"
        echo "   python rag_engine_agent.py"
        
    else
        echo "⚠️  No se pudo crear el Data Store automáticamente."
        echo "📋 Pasos manuales:"
        echo "1. 🏗️  Crear un RAG Engine en:"
        echo "   https://console.cloud.google.com/vertex-ai/agents/agent-engines?project=$GCP_PROJECT_ID"
        echo ""
        echo "2. 🔍 Ejecutar para encontrar el ID:"
        echo "   python find_rag_engines.py"
        echo ""
        echo "3. 📝 Actualizar manualmente el archivo .env"
    fi
else
    echo "✅ Encontrados RAG engines existentes:"
    echo "$EXISTING_ENGINES" | while read engine; do
        ENGINE_ID=$(echo $engine | sed 's|.*/||')
        echo "   - ID: $ENGINE_ID"
    done
    
    echo ""
    echo "📋 Próximos pasos:"
    echo "1. 📝 Actualizar el archivo .env con uno de los Engine IDs mostrados arriba"
    echo "2. 🚀 Ejecutar el agente: python rag_engine_agent.py"
fi

echo ""
echo "🎉 ¡Configuración completada! Tu entorno RAG está listo."

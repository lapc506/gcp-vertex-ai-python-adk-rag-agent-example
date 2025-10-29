# Quickstart Script para Windows - GCP Vertex AI Python ADK RAG Agent
# Versión simplificada que usa directamente la API REST de Discovery Engine

# Función para verificar si se ejecuta como administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Función para cargar variables del archivo .env
function Load-EnvFile {
    param([string]$EnvFilePath = ".env")
    
    if (Test-Path $EnvFilePath) {
        Write-Host "📋 Cargando configuración desde: $EnvFilePath" -ForegroundColor Gray
        $loadedVars = 0
        Get-Content $EnvFilePath | ForEach-Object {
            if ($_ -match '^([^#][^=]+)=(.*)$') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($name, $value, 'Process')
                $loadedVars++
                Write-Host "   ✓ $name" -ForegroundColor DarkGreen
            }
        }
        Write-Host "📊 Variables cargadas: $loadedVars" -ForegroundColor Gray
    } else {
        Write-Host "❌ Archivo .env no encontrado: $EnvFilePath" -ForegroundColor Red
        return $false
    }
    return $true
}

# Función para crear Data Store usando API REST v1
function Create-DataStoreWithREST {
    param([string]$DataStoreName)
    
    try {
        Write-Host "🔑 Obteniendo token de acceso..." -ForegroundColor Gray
        $accessToken = gcloud auth print-access-token --project=$env:GCP_PROJECT_ID 2>$null
        
        if (-not $accessToken) {
            Write-Host "❌ No se pudo obtener token de acceso" -ForegroundColor Red
            return $null
        }
        
        # URL correcta según la documentación API v1 - Discovery Engine requiere 'global' como ubicación
        $uri = "https://discoveryengine.googleapis.com/v1/projects/$env:GCP_PROJECT_ID/locations/global/dataStores?dataStoreId=$DataStoreName"
        
        # Crear JSON body según API v1 - estructura simplificada
        $jsonBody = @{
            displayName = "RAG Data Store - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            industryVertical = "GENERIC"
            solutionTypes = @("SOLUTION_TYPE_SEARCH")
            contentConfig = "CONTENT_REQUIRED"
        } | ConvertTo-Json -Depth 3
        
        Write-Host "🌐 Enviando petición a Discovery Engine API v1..." -ForegroundColor Gray
        Write-Host "📍 URI: $uri" -ForegroundColor DarkGray
        Write-Host "📝 JSON Body: $jsonBody" -ForegroundColor DarkGray
        
        # Usar Invoke-RestMethod
        $response = Invoke-RestMethod -Uri $uri -Method POST -Headers @{
            "Authorization" = "Bearer $accessToken"
            "Content-Type" = "application/json"
            "x-goog-user-project" = $env:GCP_PROJECT_ID
        } -Body $jsonBody -ErrorAction Stop
        
        if ($response -and $response.name) {
            Write-Host "✅ Data Store creado exitosamente!" -ForegroundColor Green
            Write-Host "📊 Operación: $($response.name)" -ForegroundColor Cyan
            Write-Host "📋 ID del Data Store: $DataStoreName" -ForegroundColor Cyan
            
            # El ID del Data Store es el que especificamos en el parámetro dataStoreId
            return $DataStoreName
        }
        
        return $null
        
    } catch {
        Write-Host "❌ Error en API REST: $($_.Exception.Message)" -ForegroundColor Red
        
        # Mostrar detalles del error si están disponibles
        if ($_.Exception.Response) {
            try {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorBody = $reader.ReadToEnd()
                Write-Host "📄 Detalles del error: $errorBody" -ForegroundColor Gray
            } catch {
                # Ignorar errores al leer el stream
            }
        }
        
        # Intentar con curl como fallback
        Write-Host "🔄 Intentando con curl como alternativa..." -ForegroundColor Yellow
        
        try {
            # Crear archivo temporal con el JSON
            $tempFile = [System.IO.Path]::GetTempFileName()
            $jsonBody | Out-File -FilePath $tempFile -Encoding UTF8
            
            $curlResult = curl -s -X POST $uri `
                -H "Authorization: Bearer $accessToken" `
                -H "Content-Type: application/json" `
                -H "x-goog-user-project: $env:GCP_PROJECT_ID" `
                -d "@$tempFile" 2>&1
            
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            
            Write-Host "📄 Respuesta de curl: $curlResult" -ForegroundColor DarkGray
            
            if ($curlResult -and -not ($curlResult -match '"error"')) {
                try {
                    $curlResponse = $curlResult | ConvertFrom-Json
                    if ($curlResponse.name) {
                        Write-Host "✅ Data Store creado exitosamente con curl!" -ForegroundColor Green
                        Write-Host "📊 Operación: $($curlResponse.name)" -ForegroundColor Cyan
                        Write-Host "📋 ID del Data Store: $DataStoreName" -ForegroundColor Cyan
                        
                        # El ID del Data Store es el que especificamos en el parámetro dataStoreId
                        return $DataStoreName
                    }
                } catch {
                    Write-Host "❌ Error parseando respuesta de curl" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Error en curl: $curlResult" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Error con curl: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        return $null
    }
}

Write-Host "🚀 Iniciando configuración de GCP Vertex AI RAG Agent..." -ForegroundColor Green
Write-Host ""

# Crear y Activar el Entorno Virtual (venv)
if (Test-Path "venv") {
    Write-Host "📦 Entorno virtual ya existe, activando..." -ForegroundColor Yellow
} else {
    Write-Host "📦 Creando entorno virtual..." -ForegroundColor Yellow
    python -m venv venv
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error creando entorno virtual. Asegúrate de tener Python instalado." -ForegroundColor Red
        exit 1
    }
}

Write-Host "🔄 Activando entorno virtual..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# Instalar dependencias
Write-Host "📚 Instalando dependencias..." -ForegroundColor Yellow
pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error instalando dependencias" -ForegroundColor Red
    exit 1
}

# Verificar autenticación de Google Cloud
Write-Host "🔐 Verificando autenticación de Google Cloud..." -ForegroundColor Yellow

# Verificar si ya hay una sesión activa
$currentAccount = gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>$null

if ($currentAccount -and $currentAccount.Trim() -ne "") {
    Write-Host "✅ Ya tienes una sesión activa: $($currentAccount.Trim())" -ForegroundColor Green
} else {
    Write-Host "🔑 No hay sesión activa. Iniciando autenticación..." -ForegroundColor Yellow
    Write-Host "Se abrirá tu navegador para autenticación..."
    
    gcloud auth login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error en gcloud auth login" -ForegroundColor Red
        exit 1
    }
}

# Verificar Application Default Credentials
Write-Host "🔍 Verificando Application Default Credentials..." -ForegroundColor Yellow
$adcCheck = gcloud auth application-default print-access-token 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "🔑 Configurando Application Default Credentials..." -ForegroundColor Yellow
    gcloud auth application-default login
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Error en gcloud auth application-default login" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Application Default Credentials ya configuradas" -ForegroundColor Green
}

# Configurar proyecto por defecto y quota
Write-Host "⚙️ Configurando proyecto..." -ForegroundColor Yellow
gcloud config set project $env:GCP_PROJECT_ID
gcloud auth application-default set-quota-project $env:GCP_PROJECT_ID

# Habilitar APIs necesarias
Write-Host "🔌 Habilitando APIs necesarias..." -ForegroundColor Yellow
gcloud services enable discoveryengine.googleapis.com
gcloud services enable aiplatform.googleapis.com

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error habilitando APIs. Verifica que tengas facturación habilitada." -ForegroundColor Red
    exit 1
}

# Crear archivo .env si no existe
if (-not (Test-Path ".env")) {
    Write-Host "📝 Archivo .env no encontrado. Creando desde .env.example..." -ForegroundColor Yellow
    
    if (-not (Test-Path ".env.example")) {
        Write-Host "❌ Error: Archivo .env.example no encontrado" -ForegroundColor Red
        Write-Host "📝 Necesitas el archivo .env.example para continuar" -ForegroundColor Yellow
        exit 1
    }
    
    # Copiar .env.example a .env
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Archivo .env creado desde .env.example" -ForegroundColor Green
    
    # Obtener el proyecto actual de gcloud
    $currentProject = gcloud config get-value project 2>$null
    if (-not $currentProject -or $currentProject.Trim() -eq "") {
        $currentProject = "gcp-vertex-ai-python-adk"
        Write-Host "⚠️  No hay proyecto configurado en gcloud, usando: $currentProject" -ForegroundColor Yellow
    } else {
        Write-Host "📋 Usando proyecto actual de gcloud: $currentProject" -ForegroundColor Green
    }
    
    # Actualizar .env con valores correctos
    Write-Host "🔧 Configurando valores en .env..." -ForegroundColor Yellow
    $envContent = Get-Content .env
    $newEnvContent = $envContent | ForEach-Object {
        if ($_ -match '^GCP_PROJECT_ID=') {
            "GCP_PROJECT_ID=$currentProject"
        } elseif ($_ -match '^GCP_LOCATION=') {
            "GCP_LOCATION=us-central1"
        } else {
            $_
        }
    }
    $newEnvContent | Set-Content .env
    
    Write-Host "✅ Archivo .env configurado automáticamente" -ForegroundColor Green
}

# Cargar variables del archivo .env
Write-Host "📋 Cargando configuración..." -ForegroundColor Yellow
$envLoaded = Load-EnvFile

if (-not $envLoaded) {
    Write-Host "❌ Error cargando archivo .env" -ForegroundColor Red
    exit 1
}

# Validar configuración requerida
if (-not $env:GCP_PROJECT_ID -or $env:GCP_PROJECT_ID -eq "") {
    Write-Host "❌ Error: GCP_PROJECT_ID no está configurado en .env" -ForegroundColor Red
    Write-Host "� Intentalndo obtener proyecto actual de gcloud..." -ForegroundColor Yellow
    
    $currentProject = gcloud config get-value project 2>$null
    if ($currentProject -and $currentProject.Trim() -ne "") {
        Write-Host "📋 Configurando GCP_PROJECT_ID: $currentProject" -ForegroundColor Green
        
        # Actualizar .env
        $envContent = Get-Content .env
        $newEnvContent = $envContent | ForEach-Object {
            if ($_ -match '^GCP_PROJECT_ID=') {
                "GCP_PROJECT_ID=$currentProject"
            } else {
                $_
            }
        }
        $newEnvContent | Set-Content .env
        [Environment]::SetEnvironmentVariable('GCP_PROJECT_ID', $currentProject, 'Process')
    } else {
        Write-Host "❌ No se pudo obtener el proyecto de gcloud" -ForegroundColor Red
        Write-Host "📝 Configura tu proyecto: gcloud config set project TU_PROYECTO_ID" -ForegroundColor Yellow
        exit 1
    }
}

if (-not $env:GCP_LOCATION -or $env:GCP_LOCATION -eq "") {
    Write-Host "📋 Configurando GCP_LOCATION por defecto: us-central1" -ForegroundColor Yellow
    
    # Actualizar .env
    $envContent = Get-Content .env
    $newEnvContent = $envContent | ForEach-Object {
        if ($_ -match '^GCP_LOCATION=') {
            "GCP_LOCATION=us-central1"
        } else {
            $_
        }
    }
    $newEnvContent | Set-Content .env
    [Environment]::SetEnvironmentVariable('GCP_LOCATION', 'us-central1', 'Process')
}

# Verificar configuración
Write-Host ""
Write-Host "✅ Configuración completada:" -ForegroundColor Green
$currentProject = gcloud config get-value project
Write-Host "   Proyecto: $currentProject" -ForegroundColor White
Write-Host "   APIs habilitadas correctamente" -ForegroundColor White

# Listar RAG engines disponibles
Write-Host ""
Write-Host "🔍 Verificando RAG engines disponibles..." -ForegroundColor Yellow

$accessToken = gcloud auth print-access-token --project=$env:GCP_PROJECT_ID
$foundEngines = $false

# Verificar si existen RAG engines
try {
    $response = curl -s -H "Authorization: Bearer $accessToken" -H "x-goog-user-project: $env:GCP_PROJECT_ID" "https://discoveryengine.googleapis.com/v1/projects/$env:GCP_PROJECT_ID/locations/global/dataStores" 2>$null
    
    if ($response -and -not ($response -match '"error"')) {
        $jsonResponse = $response | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($jsonResponse -and $jsonResponse.PSObject.Properties.Name -contains "dataStores" -and $jsonResponse.dataStores.Count -gt 0) {
            Write-Host "✅ Encontrados RAG engines:" -ForegroundColor Green
            $firstEngineId = $null
            foreach ($store in $jsonResponse.dataStores) {
                $engineId = $store.name.Split('/')[-1]
                Write-Host "   - ID: $engineId" -ForegroundColor White
                Write-Host "   - Nombre: $($store.displayName)" -ForegroundColor White
                if (-not $firstEngineId) {
                    $firstEngineId = $engineId
                }
            }
            
            # Actualizar automáticamente el .env con el primer engine encontrado
            if ($firstEngineId) {
                Write-Host ""
                Write-Host "🔧 Actualizando archivo .env con el primer engine encontrado..." -ForegroundColor Yellow
                
                $envContent = Get-Content .env
                $newEnvContent = $envContent | ForEach-Object {
                    if ($_ -match '^GCP_RAG_ENGINE_ID=') {
                        "GCP_RAG_ENGINE_ID=$firstEngineId"
                    } else {
                        $_
                    }
                }
                $newEnvContent | Set-Content .env
                
                Write-Host "✅ Archivo .env actualizado con ID: $firstEngineId" -ForegroundColor Green
            }
            
            $foundEngines = $true
        }
    }
}
catch {
    # Continuar
}

# Crear RAG Engine si no existe ninguno
if (-not $foundEngines) {
    Write-Host ""
    Write-Host "🏗️ No se encontraron RAG Engines. Creando uno automáticamente..." -ForegroundColor Yellow
    
    $dataStoreName = "rag-datastore-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "📝 Creando Data Store: $dataStoreName" -ForegroundColor Cyan
    
    # Verificar que las variables de entorno estén configuradas
    if (-not $env:GCP_PROJECT_ID) {
        Write-Host "❌ Error: Variable GCP_PROJECT_ID no está configurada" -ForegroundColor Red
        Write-Host "📝 Verifica que el archivo .env esté cargado correctamente" -ForegroundColor Yellow
        exit 1
    }
    
    # Crear el Data Store usando API REST directamente
    Write-Host "🌐 Creando Data Store usando Discovery Engine API..." -ForegroundColor Cyan
    $dataStoreId = Create-DataStoreWithREST $dataStoreName
    
    if ($dataStoreId) {
        Write-Host "✅ Data Store creado exitosamente!" -ForegroundColor Green
        Write-Host "📋 ID del Data Store: $dataStoreId" -ForegroundColor White
        
        # Actualizar .env
        $envContent = Get-Content .env
        $newEnvContent = $envContent | ForEach-Object {
            if ($_ -match '^GCP_RAG_ENGINE_ID=') {
                "GCP_RAG_ENGINE_ID=$dataStoreId"
            } else {
                $_
            }
        }
        $newEnvContent | Set-Content .env
        
        Write-Host "✅ Archivo .env actualizado" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 ¡Configuración completada! Tu entorno RAG está listo." -ForegroundColor Green
    } else {
        Write-Host "⚠️  No se pudo crear el Data Store usando la API REST." -ForegroundColor Red
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Yellow
        Write-Host "💡 ALTERNATIVA: Crear Data Store manualmente" -ForegroundColor Yellow
        Write-Host "=" * 80 -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🌐 Usa la consola web de Google Cloud:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1️⃣  Abre la consola de Google Cloud:" -ForegroundColor Cyan
        Write-Host "   https://console.cloud.google.com/vertex-ai/agents/agent-engines?project=$env:GCP_PROJECT_ID" -ForegroundColor Green
        Write-Host ""
        Write-Host "2️⃣  Crea un nuevo Data Store:" -ForegroundColor Cyan
        Write-Host "   - Tipo: Search" -ForegroundColor White
        Write-Host "   - Nombre: RAG Data Store" -ForegroundColor White
        Write-Host "   - Ubicación: Global" -ForegroundColor White
        Write-Host ""
        Write-Host "3️⃣  Obtén el ID del Data Store creado:" -ForegroundColor Cyan
        Write-Host "   python find_rag_engines.py" -ForegroundColor Green
        Write-Host ""
        Write-Host "4️⃣  Actualiza el archivo .env con el ID encontrado" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Yellow
        Write-Host "⚠️  Configuración incompleta. Completa los pasos manuales." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "🎉 ¡Configuración completada! Tu entorno RAG está listo." -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Próximos pasos:" -ForegroundColor Cyan
    Write-Host "1. 🚀 Ejecutar el agente:" -ForegroundColor Yellow
    Write-Host "   python rag_engine_agent.py" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 📄 Para obtener respuestas basadas en tus documentos:" -ForegroundColor Yellow
    Write-Host "   - Sube documentos al Data Store desde la consola de Google Cloud" -ForegroundColor White
    Write-Host "   - Consola: https://console.cloud.google.com/vertex-ai/agents/agent-engines?project=$env:GCP_PROJECT_ID" -ForegroundColor Green
}
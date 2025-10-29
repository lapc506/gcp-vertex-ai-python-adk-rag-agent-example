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

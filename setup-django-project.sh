#!/bin/bash
# setup-django-project.sh - Automated Django + Docker project setup
#
# Usage: 
#   setup-django-project.sh [project_name] [target_directory]
#
# Arguments:
#   project_name       Optional. Name for the project directory.
#                      If not provided, prompts user or generates random name.
#   target_directory   Optional. Parent directory where project will be created.
#                      If not provided, prompts user or uses current directory.
#
# Examples:
#   ./setup-django-project.sh
#   ./setup-django-project.sh my-django-app
#   ./setup-django-project.sh my-django-app ~/projects
#   ./setup-django-project.sh "" ~/projects  # Random name in ~/projects
#
# Description:
#   Creates a complete Django + Docker development environment with:
#   - Django project with config/ and core/ apps
#   - PostgreSQL database configuration
#   - Docker and docker-compose setup
#   - Environment files
#   - Git initialization
#
# Requirements:
#   - uv (Python package manager)
#   - docker
#   - git

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#######################################
# Constants
#######################################
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PYTHON_VERSION="3.13"

#######################################
# Colors for output
#######################################
readonly COLOR_RESET='\033[0m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'

#######################################
# Print error message to stderr and exit.
# Arguments:
#   Error message string
# Outputs:
#   Writes error to stderr
#######################################
err() {
  echo -e "${COLOR_RED}[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $*${COLOR_RESET}" >&2
  exit 1
}

#######################################
# Log info message to stdout.
# Arguments:
#   Info message string
# Outputs:
#   Writes to stdout
#######################################
log() {
  echo -e "${COLOR_BLUE}[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $*${COLOR_RESET}"
}

#######################################
# Log success message to stdout.
# Arguments:
#   Success message string
# Outputs:
#   Writes to stdout
#######################################
success() {
  echo -e "${COLOR_GREEN}[SUCCESS] $*${COLOR_RESET}"
}

#######################################
# Log warning message to stdout.
# Arguments:
#   Warning message string
# Outputs:
#   Writes to stdout
#######################################
warn() {
  echo -e "${COLOR_YELLOW}[WARN] $*${COLOR_RESET}"
}

#######################################
# Display help message.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes help to stdout
#######################################
show_help() {
  cat << 'EOF'
Django + Docker Project Setup
==============================

Automated setup script for Django projects with Docker, PostgreSQL, and uv.

USAGE:
    setup-django-project.sh [OPTIONS] [PROJECT_NAME] [TARGET_DIRECTORY]

OPTIONS:
    -h, --help, -?      Show this help message and exit

ARGUMENTS:
    PROJECT_NAME        Optional. Name for the project directory.
                        - Must contain only lowercase letters, numbers, and hyphens
                        - If not provided, script will prompt or generate random name
                        - Examples: my-app, django-api, web-project-2024

    TARGET_DIRECTORY    Optional. Parent directory where project will be created.
                        - If not provided, uses current directory
                        - Can use tilde (~) for home directory
                        - Examples: ~/projects, /var/www, ./apps

INTERACTIVE MODE:
    When invoked without arguments, the script runs in interactive mode:
    1. Asks if you want to create project in current directory
    2. Prompts for project name (or auto-generates if left empty)
    3. Shows confirmation before proceeding

EXAMPLES:
    # Interactive mode - prompts for all options
    ./setup-django-project.sh

    # Create project with auto-generated name in current directory
    ./setup-django-project.sh ""

    # Create project with specific name in current directory
    ./setup-django-project.sh my-django-app

    # Create project in specific directory
    ./setup-django-project.sh my-app ~/projects

    # Auto-generated name in specific directory
    ./setup-django-project.sh "" ~/projects

    # Create in home directory
    ./setup-django-project.sh my-app ~

    # Show this help message
    ./setup-django-project.sh --help

WHAT IT CREATES:
    The script sets up a complete Django + Docker environment with:
    
    ✓ Django 6.0+ with config/ project structure
    ✓ Core app with basic views and URLs
    ✓ PostgreSQL 18.1 database
    ✓ Separate Dockerfiles for dev and production
    ✓ Docker Compose files for both environments
    ✓ Hot-reload support with Docker Compose watch
    ✓ Environment files (.env, .env.prod)
    ✓ Static and media file directories
    ✓ Git repository initialization
    ✓ Comprehensive README with usage instructions

PROJECT STRUCTURE:
    your-project/
    ├── manage.py
    ├── config/              # Django settings
    │   ├── __init__.py
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    ├── core/                # Main Django app
    │   ├── urls.py
    │   ├── views.py
    │   └── ...
    ├── static/              # Static files (CSS, JS, images)
    ├── templates/           # HTML templates
    ├── media/               # User uploads
    ├── staticfiles/         # Collected static files
    ├── Dockerfile.dev       # Development Docker image
    ├── Dockerfile.prod      # Production Docker image
    ├── docker-compose.dev.yml
    ├── docker-compose.prod.yml
    ├── pyproject.toml       # Python dependencies (uv)
    ├── uv.lock             # Locked dependencies
    ├── .env                # Development environment variables
    ├── .env.prod           # Production environment variables
    ├── .dockerignore
    ├── .gitignore
    └── README.md

REQUIREMENTS:
    The following tools must be installed on your system:
    
    • uv       - Python package manager
                 Install: curl -LsSf https://astral.sh/uv/install.sh | sh
                 Docs: https://docs.astral.sh/uv/
    
    • docker   - Container platform
                 Install: https://docs.docker.com/get-docker/
    
    • git      - Version control
                 Install: https://git-scm.com/downloads

AFTER SETUP:
    1. Navigate to your project directory
    2. Start development environment:
       docker compose -f docker-compose.dev.yml up --build
    
    3. Run migrations (in another terminal):
       docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate
    
    4. Visit http://localhost:8000

PRODUCTION DEPLOYMENT:
    1. Update .env.prod with secure values:
       - DJANGO_SECRET_KEY (generate with Django)
       - DJANGO_DEBUG=False
       - DJANGO_ALLOWED_HOSTS=yourdomain.com
       - POSTGRES_PASSWORD (strong password)
    
    2. Build and start production containers:
       docker compose -f docker-compose.prod.yml up -d --build
    
    3. Run migrations:
       docker compose -f docker-compose.prod.yml exec web-prod python manage.py migrate
    
    4. Visit http://localhost:5000

PYTHON VERSION:
    This script uses Python 3.13 and creates projects with:
    - Django 6.0+
    - psycopg[binary] 3.3.2+ (PostgreSQL adapter)
    - gunicorn 23.0.0+ (production WSGI server)

DOCKER IMAGES:
    Development:  Uses all dependencies for hot-reload
    Production:   Optimized with UV_NO_DEV=1, runs with gunicorn

SUPPORT:
    For issues, questions, or contributions, see the project repository.

EOF
}


#######################################
# Generate random project name.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes random project name to stdout
#######################################
generate_project_name() {
  local adjectives=("happy" "sleepy" "brave" "clever" "swift" "bright" "calm" "wise")
  local nouns=("django" "python" "docker" "server" "app" "project" "api" "web")
  local random_adj="${adjectives[$((RANDOM % ${#adjectives[@]}))]}"
  local random_noun="${nouns[$((RANDOM % ${#nouns[@]}))]}"
  local random_num=$((RANDOM % 1000))
  
  echo "${random_adj}-${random_noun}-${random_num}"
}

#######################################
# Prompt user for project setup preferences.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Sets target_dir and project_name variables
# Returns:
#   0 if user wants to continue, exits otherwise
#######################################
prompt_user_setup() {
  echo ""
  echo "========================================="
  echo "  Django + Docker Project Setup"
  echo "========================================="
  echo ""
  
  # Ask about current directory
  read -rp "Create project in current directory ($(pwd))? (y/N): " use_current_dir
  
  if [[ ! "${use_current_dir}" =~ ^[Yy]$ ]]; then
    log "Setup cancelled by user"
    exit 0
  fi
  
  # Ask for project name
  echo ""
  read -rp "Enter project name (leave empty for auto-generated name): " input_project_name
  
  if [[ -z "${input_project_name}" ]]; then
    input_project_name="$(generate_project_name)"
    log "Auto-generated project name: ${input_project_name}"
  fi
  
  # Validate project name
  if [[ ! "${input_project_name}" =~ ^[a-z0-9-]+$ ]]; then
    err "Invalid project name. Use only lowercase letters, numbers, and hyphens."
  fi
  
  # Export for use in main
  export PROMPTED_PROJECT_NAME="${input_project_name}"
  export PROMPTED_TARGET_DIR="$PWD"
  
  echo ""
  log "Project '${input_project_name}' will be created in: $PWD/${input_project_name}"
  echo ""
  read -rp "Continue? (Y/n): " confirm
  
  if [[ "${confirm}" =~ ^[Nn]$ ]]; then
    log "Setup cancelled by user"
    exit 0
  fi
}

#######################################
# Check if required commands are available.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if all commands available, exits otherwise
#######################################
check_prerequisites() {
  log "Checking prerequisites..."
  
  local missing_commands=()
  local install_instructions=""
  
  # Check for uv
  if ! command -v uv &> /dev/null; then
    missing_commands+=("uv")
    install_instructions+="\n${COLOR_YELLOW}uv (Python package manager):${COLOR_RESET}"
    install_instructions+="\n  macOS/Linux: curl -LsSf https://astral.sh/uv/install.sh | sh"
    install_instructions+="\n  Windows:     powershell -c \"irm https://astral.sh/uv/install.ps1 | iex\""
    install_instructions+="\n  Docs:        https://docs.astral.sh/uv/getting-started/installation/"
  fi
  
  # Check for docker
  if ! command -v docker &> /dev/null; then
    missing_commands+=("docker")
    install_instructions+="\n\n${COLOR_YELLOW}Docker:${COLOR_RESET}"
    install_instructions+="\n  macOS:       https://docs.docker.com/desktop/install/mac-install/"
    install_instructions+="\n  Windows:     https://docs.docker.com/desktop/install/windows-install/"
    install_instructions+="\n  Linux:       https://docs.docker.com/engine/install/"
  fi
  
  # Check for git
  if ! command -v git &> /dev/null; then
    missing_commands+=("git")
    install_instructions+="\n\n${COLOR_YELLOW}Git:${COLOR_RESET}"
    install_instructions+="\n  macOS:       brew install git  (or download from https://git-scm.com/)"
    install_instructions+="\n  Windows:     https://git-scm.com/download/win"
    install_instructions+="\n  Linux:       sudo apt install git  (Debian/Ubuntu)"
    install_instructions+="\n               sudo yum install git  (RHEL/CentOS)"
  fi
  
  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo ""
    echo -e "${COLOR_RED}❌ Missing required commands: ${missing_commands[*]}${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_BLUE}📦 Installation Instructions:${COLOR_RESET}"
    echo -e "${install_instructions}"
    echo ""
    exit 1
  fi
  
  success "All prerequisites found ✓"
}

#######################################
# Create project directory.
# Arguments:
#   $1: Project directory name
#   $2: Target parent directory (optional, defaults to PWD)
# Returns:
#   0 on success, exits on failure
#######################################
create_project_directory() {
  local project_name="$1"
  local target_dir="${2:-$PWD}"
  
  # Expand tilde and make absolute path
  target_dir="${target_dir/#\~/$HOME}"
  target_dir="$(cd "${target_dir}" 2>/dev/null && pwd)" || err "Target directory does not exist: ${target_dir}"
  
  local project_dir="${target_dir}/${project_name}"
  
  if [[ -d "${project_dir}" ]]; then
    warn "Directory '${project_dir}' already exists"
    read -rp "Continue and overwrite? (y/N): " response
    if [[ ! "${response}" =~ ^[Yy]$ ]]; then
      err "Setup cancelled by user"
    fi
  else
    log "Creating project directory: ${project_dir}"
    mkdir -p "${project_dir}" || err "Failed to create directory: ${project_dir}"
  fi
  
  cd "${project_dir}" || err "Failed to change to directory: ${project_dir}"
  success "Project directory ready: ${project_dir}"
  
  # Export for use in other functions
  export PROJECT_DIR="${project_dir}"
}

#######################################
# Initialize uv project and add dependencies.
# Globals:
#   PYTHON_VERSION
# Arguments:
#   None
# Returns:
#   0 on success, exits on failure
#######################################
initialize_uv_project() {
  log "Initializing uv project..."
  
  # Initialize uv project
  if [[ ! -f "pyproject.toml" ]]; then
    uv init --bare --app --python "${PYTHON_VERSION}" || err "Failed to initialize uv project"
    success "Initialized uv project"
  else
    warn "pyproject.toml already exists, skipping uv init"
  fi
  
  # Add dependencies
  log "Adding Django dependencies..."
  uv add "django>=5.2.9" || err "Failed to add Django"
  
  log "Adding PostgreSQL adapter..."
  uv add "psycopg[binary]>=3.3.2" || err "Failed to add psycopg"
  
  log "Adding Gunicorn..."
  uv add "gunicorn>=23.0.0" || err "Failed to add Gunicorn"
  
  success "All dependencies added"
}

#######################################
# Create Django project structure.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success, exits on failure
#######################################
create_django_project() {
  log "Creating Django project..."
  
  if [[ -f "manage.py" ]]; then
    warn "Django project already exists (manage.py found)"
    return 0
  fi
  
  # Create Django project
  uv run django-admin startproject config . || err "Failed to create Django project"
  
  # Create core app
  log "Creating core app..."
  uv run python manage.py startapp core || err "Failed to create core app"
  
  # Create additional directories
  log "Creating project directories..."
  mkdir -p static/{css,js,images} templates media staticfiles
  
  success "Django project structure created"
}

#######################################
# Create core app URLs.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates core/urls.py
#######################################
create_core_urls() {
  log "Creating core/urls.py..."
  
  cat > core/urls.py << 'EOF'
from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    path('', views.index, name='index'),
]
EOF

  success "Created core/urls.py"
}

#######################################
# Create core app views.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates core/views.py
#######################################
create_core_views() {
  log "Creating core/views.py..."
  
  cat > core/views.py << 'EOF'
from django.http import HttpResponse


def index(request):
    """Homepage view."""
    return HttpResponse("Hello, Django! 🚀")
EOF

  success "Created core/views.py"
}

#######################################
# Update Django settings.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Updates config/settings.py
#######################################
update_django_settings() {
  log "Updating Django settings..."
  
  cat > config/settings.py << 'EOF'
import os
from pathlib import Path

# Build paths inside the project
BASE_DIR = Path(__file__).resolve().parent.parent

# Docker-friendly with simple defaults
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'dev-secret-key-change-in-production')
DEBUG = os.getenv('DJANGO_DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.getenv('DJANGO_ALLOWED_HOSTS', '*').split(',')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# Database - PostgreSQL for Docker
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB', 'postgres'),
        'USER': os.getenv('POSTGRES_USER', 'postgres'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD', 'postgres'),
        'HOST': os.getenv('POSTGRES_HOST', 'db'),
        'PORT': os.getenv('POSTGRES_PORT', '5432'),
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
EOF

  success "Updated Django settings"
}

#######################################
# Update Django URLs.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Updates config/urls.py
#######################################
update_django_urls() {
  log "Updating Django URLs..."
  
  cat > config/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('core.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
EOF

  success "Updated Django URLs"
}

#######################################
# Create Dockerfile.dev
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates Dockerfile.dev
#######################################
create_dockerfile_dev() {
  log "Creating Dockerfile.dev..."
  
  cat > Dockerfile.dev << 'EOF'
# Build stage
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1 \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /build

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

COPY . /build

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable

# Final stage
FROM python:3.13-slim-bookworm AS final

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"


RUN groupadd --system --gid 1001 app && \
    useradd --system --gid 1001 --uid 1001 --no-create-home app

COPY --from=builder --chown=app:app /build/.venv /app/.venv
COPY --from=builder --chown=app:app /build /app

WORKDIR /app

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000')" || exit 1

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF

  success "Created Dockerfile.dev"
}

#######################################
# Create Dockerfile.prod
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates Dockerfile.prod
#######################################
create_dockerfile_prod() {
  log "Creating Dockerfile.prod..."
  
  cat > Dockerfile.prod << 'EOF'
# Build stage
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_NO_DEV=1 \
    UV_PYTHON_DOWNLOADS=0

WORKDIR /build

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

COPY . /build

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable

# Final stage
FROM python:3.13-slim-bookworm AS final

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

RUN groupadd --system --gid 1001 app && \
    useradd --system --gid 1001 --uid 1001 --no-create-home app

COPY --from=builder --chown=app:app /build/.venv /app/.venv
COPY --from=builder --chown=app:app /build /app

WORKDIR /app

USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000')" || exit 1

CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "config.wsgi:application"]
EOF

  success "Created Dockerfile.prod"
}

#######################################
# Create docker-compose files.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates docker-compose.dev.yml and docker-compose.prod.yml
#######################################
create_docker_compose_files() {
  log "Creating docker-compose files..."
  
  # Development compose file with watch
  cat > docker-compose.dev.yml << 'EOF'
services:
  web-dev:
    build: 
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db-dev:
        condition: service_healthy
    develop:
      watch:
        # Sync Python source files for hot reload
        - action: sync
          path: ./
          target: /app
          ignore:
            - .venv/
            - __pycache__/
            - "*.pyc"
            - "*.pyo"
            - "*.pyd"
            - .pytest_cache/
            - "*.db"
            - "*.sqlite3"
            - .git/
            - staticfiles/
            - media/
            - "*.md"
            - .env
            - .env.*
            - docker-compose*.yml
            - Dockerfile*
            - .dockerignore
            - .gitignore
        
        # Rebuild on dependency changes
        - action: rebuild
          path: ./pyproject.toml
        
        - action: rebuild
          path: ./uv.lock
  
  db-dev:
    image: postgres:18.1-bookworm
    volumes:
      - postgres_data_dev:/var/lib/postgresql
    env_file:
      - .env
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

volumes:
  postgres_data_dev:
EOF

  # Production compose file
  cat > docker-compose.prod.yml << 'EOF'
services:
  web-prod:
    build:
      context: .
      dockerfile: Dockerfile.prod
    image: django-app:latest
    ports:
      - "5000:5000"
    env_file:
      - .env.prod
    depends_on:
      db-prod:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5000')"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
  
  db-prod:
    image: postgres:18.1-bookworm
    volumes:
      - postgres_data_prod:/var/lib/postgresql
    env_file:
      - .env.prod
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data_prod:
EOF

  success "Created docker-compose files"
}

#######################################
# Create environment files.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates .env and .env.prod
#######################################
create_env_files() {
  log "Creating environment files..."
  
  # Development .env
  cat > .env << 'EOF'
# Development settings
DJANGO_DEBUG=True
DJANGO_SECRET_KEY=dev-secret-key-change-in-production
DJANGO_ALLOWED_HOSTS=*

# PostgreSQL
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=db-dev
POSTGRES_PORT=5432
EOF

  # Production .env.prod (template)
  cat > .env.prod << 'EOF'
# Production settings
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=CHANGE-THIS-TO-A-SECURE-SECRET-KEY
DJANGO_ALLOWED_HOSTS=localhost,0.0.0.0,127.0.0.1

# PostgreSQL
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE-THIS-TO-A-SECURE-PASSWORD
POSTGRES_HOST=db-prod
POSTGRES_PORT=5432
EOF

  success "Created environment files"
}

#######################################
# Create .dockerignore file.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates .dockerignore
#######################################
create_dockerignore() {
  log "Creating .dockerignore..."
  
  cat > .dockerignore << 'EOF'
# Python
__pycache__/
*.py[cod]
.Python
.venv
venv/

# Django
*.log
db.sqlite3
/media
/staticfiles

# Docker
docker-compose*.yml
Dockerfile*
.dockerignore

# IDE
.vscode
.idea
*.swp

# Git
.git
.gitignore

# Documentation
*.md
README*

# OS
.DS_Store
Thumbs.db

# Tests
.pytest_cache
.coverage
EOF

  success "Created .dockerignore"
}

#######################################
# Create .gitignore file.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates .gitignore
#######################################
create_gitignore() {
  log "Creating .gitignore..."
  
  cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
.venv
venv/

# Django
*.log
db.sqlite3
/media
/staticfiles

# Environment
.env
.env.*

# IDE
.vscode
.idea
*.swp

# OS
.DS_Store
Thumbs.db

# uv
.mypy_cache/
.pytest_cache/

# uv init created files
hello.py
EOF

  success "Created .gitignore"
}

#######################################
# Remove uv init generated files.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
cleanup_uv_init_files() {
  log "Cleaning up uv init generated files..."
  
  # Remove main.py if it exists (uv --app creates main.py)
  if [[ -f "main.py" ]]; then
    rm main.py
    log "Removed main.py"
  fi
  
  success "Cleanup complete"
}

#######################################
# Create README.md file.
# Arguments:
#   $1: Project name
# Outputs:
#   Creates README.md
#######################################
create_readme() {
  local project_name="$1"
  
  log "Creating README.md..."
  
  cat > README.md << EOF
# ${project_name}

Django + Docker project created automatically.

## Quick Start

### Development

\`\`\`bash
# Start development environment
docker compose -f docker-compose.dev.yml up --build

# In another terminal, run migrations (REQUIRED on first run)
docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate

# Create superuser (optional)
docker compose -f docker-compose.dev.yml exec web-dev python manage.py createsuperuser

# Visit http://localhost:8000
\`\`\`

### First Time Setup

After starting the containers for the first time, you MUST run migrations:

\`\`\`bash
docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate
\`\`\`

### Production

\`\`\`bash
# Update .env.prod with production settings
docker compose -f docker-compose.prod.yml up -d --build

# Run migrations
docker compose -f docker-compose.prod.yml exec web-prod python manage.py migrate

# Collect static files
docker compose -f docker-compose.prod.yml exec web-prod python manage.py collectstatic --noinput

# Visit http://localhost:5000
\`\`\`

## Project Structure

\`\`\`
${project_name}/
├── manage.py
├── config/              # Django settings
├── core/                # Main app
├── static/              # Static files
├── templates/           # HTML templates
├── Dockerfile.dev       # Development Dockerfile
├── Dockerfile.prod      # Production Dockerfile
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── pyproject.toml
├── uv.lock
├── .env                 # Development environment
└── .env.prod            # Production environment
\`\`\`

## Useful Commands

\`\`\`bash
# View logs
docker compose -f docker-compose.dev.yml logs -f web-dev

# Run migrations
docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate

# Create superuser
docker compose -f docker-compose.dev.yml exec web-dev python manage.py createsuperuser

# Run Django shell
docker compose -f docker-compose.dev.yml exec web-dev python manage.py shell

# Test database connection
docker compose -f docker-compose.dev.yml exec web-dev python manage.py dbshell

# Run any Django command
docker compose -f docker-compose.dev.yml exec web-dev python manage.py <command>

# Add new Python packages
uv add <package-name>

# Stop services
docker compose -f docker-compose.dev.yml down

# Stop and remove volumes (fresh database)
docker compose -f docker-compose.dev.yml down -v
\`\`\`

## Adding Dependencies

\`\`\`bash
# Add a new package
uv add django-debug-toolbar

# Rebuild Docker image
docker compose -f docker-compose.dev.yml up --build
\`\`\`

## Production Deployment Checklist

Before deploying to production:

1. ✅ Update \`.env.prod\` with secure values
2. ✅ Generate a secure secret key:
   \`\`\`bash
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   \`\`\`
3. ✅ Set \`DJANGO_DEBUG=False\`
4. ✅ Configure \`DJANGO_ALLOWED_HOSTS\` with your domain
5. ✅ Set a strong \`POSTGRES_PASSWORD\`
EOF

  success "Created README.md"
}

#######################################
# Initialize git repository.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 on success
#######################################
initialize_git() {
  log "Initializing git repository..."
  
  if [[ -d ".git" ]]; then
    warn "Git repository already exists"
    return 0
  fi
  
  git init || warn "Failed to initialize git repository"
  
  success "Git repository initialized"
}

#######################################
# Display setup summary.
# Arguments:
#   $1: Project name
# Outputs:
#   Writes summary to stdout
#######################################
display_summary() {
  local project_name="$1"
  
  echo ""
  echo "========================================"
  success "Django + Docker project setup complete!"
  echo "========================================"
  echo ""
  echo "Project: ${project_name}"
  echo "Location: ${PROJECT_DIR}"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. cd ${PROJECT_DIR}"
  echo "  2. docker compose -f docker-compose.dev.yml up --build"
  echo "  3. docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate"
  echo "  4. Visit http://localhost:8000"
  echo ""
  echo "For more information, see README.md"
  echo ""
}

#######################################
# Main function - orchestrates project setup.
# Arguments:
#   $1: Optional project name or help flag
#   $2: Optional target directory
# Returns:
#   0 on success, exits on failure
#######################################
main() {
  # Safely get arguments
  local first_arg="${1:-}"
  local second_arg="${2:-}"
  
  # Check for help flags
  if [[ "$first_arg" == "-h" || "$first_arg" == "--help" || "$first_arg" == "-?" ]]; then
    show_help
    exit 0
  fi
  
  local project_name="$first_arg"
  local target_dir="$second_arg"
  
  # Check if running in interactive mode (no args provided at all)
  if [[ $# -eq 0 ]]; then
    prompt_user_setup
    project_name="${PROMPTED_PROJECT_NAME}"
    target_dir="${PROMPTED_TARGET_DIR}"
  else
    # Command-line arguments provided
    
    # Generate project name if empty or not provided
    if [[ -z "${project_name}" ]]; then
      project_name="$(generate_project_name)"
      log "No project name provided, generated: ${project_name}"
    else
      # Validate project name (lowercase, hyphens, numbers only)
      if [[ ! "${project_name}" =~ ^[a-z0-9-]+$ ]]; then
        err "Invalid project name. Use only lowercase letters, numbers, and hyphens."
      fi
    fi
    
    # Use current directory if not provided
    if [[ -z "${target_dir}" ]]; then
      target_dir="$PWD"
    fi
    
    # Validate target directory if provided and different from PWD
    if [[ -n "${target_dir}" && "${target_dir}" != "$PWD" ]]; then
      # Expand tilde
      target_dir="${target_dir/#\~/$HOME}"
      
      if [[ ! -d "${target_dir}" ]]; then
        warn "Target directory does not exist: ${target_dir}"
        read -rp "Create it? (y/N): " response
        if [[ "${response}" =~ ^[Yy]$ ]]; then
          mkdir -p "${target_dir}" || err "Failed to create target directory: ${target_dir}"
          success "Created target directory: ${target_dir}"
        else
          err "Setup cancelled by user"
        fi
      fi
    fi
  fi
  
  # Run setup steps
  check_prerequisites
  create_project_directory "${project_name}" "${target_dir}"
  initialize_uv_project
  cleanup_uv_init_files
  create_django_project
  create_core_urls
  create_core_views
  update_django_settings
  update_django_urls
  create_dockerfile_dev
  create_dockerfile_prod
  create_docker_compose_files
  create_env_files
  create_dockerignore
  create_gitignore
  create_readme "${project_name}"
  initialize_git
  
  # Display summary
  display_summary "${project_name}"
  
  return 0
}

# Execute main only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi


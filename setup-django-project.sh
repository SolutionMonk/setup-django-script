#!/bin/bash
# setup-django-project.sh - Automated Django + Docker project setup
#
# Usage: setup-django-project.sh [project_name]
#   project_name: Optional. Name for the project directory.
#                 If not provided, generates a random name.
#
# Example:
#   ./setup-django-project.sh my-django-app
#   ./setup-django-project.sh
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
readonly PYTHON_VERSION="3.12"

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
  
  local required_commands=("uv" "docker" "git")
  local missing_commands=()
  
  for cmd in "${required_commands[@]}"; do
    if ! command -v "${cmd}" &> /dev/null; then
      missing_commands+=("${cmd}")
    fi
  done
  
  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    err "Missing required commands: ${missing_commands[*]}\nPlease install them and try again."
  fi
  
  success "All prerequisites found"
}

#######################################
# Create project directory.
# Arguments:
#   $1: Project directory name
# Returns:
#   0 on success, exits on failure
#######################################
create_project_directory() {
  local project_dir="$1"
  
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
  uv add "django>=6.0" || err "Failed to add Django"
  
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
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
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
# Create Dockerfile.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Creates Dockerfile
#######################################
create_dockerfile() {
  log "Creating Dockerfile..."
  
  cat > Dockerfile << 'EOF'
# Build stage
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

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
FROM python:3.12-slim-bookworm AS final

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:$PATH"

# No need to install libpq5 - psycopg[binary] includes it!

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

  success "Created Dockerfile"
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
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db:
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
            - Dockerfile
            - .dockerignore
            - .gitignore
        
        # Rebuild on dependency changes
        - action: rebuild
          path: ./pyproject.toml
        
        - action: rebuild
          path: ./uv.lock
  
  db:
    image: postgres:18.1-bookworm
    volumes:
      - postgres_data:/var/lib/postgresql
    env_file:
      - .env
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

volumes:
  postgres_data:
EOF

  # Production compose file
  cat > docker-compose.prod.yml << 'EOF'
services:
  web:
    build: .
    image: django-app:latest
    command: gunicorn --bind 0.0.0.0:8000 --workers 4 config.wsgi:application
    ports:
      - "8000:8000"
    env_file:
      - .env.prod
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000')"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
  
  db:
    image: postgres:18.1-bookworm
    volumes:
      - postgres_data:/var/lib/postgresql
    env_file:
      - .env.prod
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
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
POSTGRES_HOST=db
POSTGRES_PORT=5432
EOF

  # Production .env.prod (template)
  cat > .env.prod << 'EOF'
# Production settings
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=CHANGE-THIS-TO-A-SECURE-SECRET-KEY
DJANGO_ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# PostgreSQL
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE-THIS-TO-A-SECURE-PASSWORD
POSTGRES_HOST=db
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
Dockerfile
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
  
  # Remove hello.py if it exists
  if [[ -f "hello.py" ]]; then
    rm main.py
    log "Removed main.py"
  fi
  
  success "Cleanup complete"
}

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
docker compose -f docker-compose.dev.yml exec web python manage.py migrate

# Create superuser (optional)
docker compose -f docker-compose.dev.yml exec web python manage.py createsuperuser

# Visit http://localhost:8000
\`\`\`

### First Time Setup

After starting the containers for the first time, you MUST run migrations:

\`\`\`bash
docker compose -f docker-compose.dev.yml exec web python manage.py migrate
\`\`\`

### Production

\`\`\`bash
# Update .env.prod with production settings
docker compose -f docker-compose.prod.yml up -d --build

# Run migrations
docker compose -f docker-compose.prod.yml exec web python manage.py migrate

# Collect static files
docker compose -f docker-compose.prod.yml exec web python manage.py collectstatic --noinput
\`\`\`

## Project Structure

\`\`\`
${project_name}/
├── manage.py
├── config/              # Django settings
├── core/                # Main app
├── static/              # Static files
├── templates/           # HTML templates
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Dockerfile
├── pyproject.toml
├── uv.lock
└── .env
\`\`\`

## Useful Commands

\`\`\`bash
# View logs
docker compose -f docker-compose.dev.yml logs -f web

# Run migrations
docker compose -f docker-compose.dev.yml exec web python manage.py migrate

# Create superuser
docker compose -f docker-compose.dev.yml exec web python manage.py createsuperuser

# Run Django commands
docker compose -f docker-compose.dev.yml exec web python manage.py <command>

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
#   $2: Project directory path
# Outputs:
#   Writes summary to stdout
#######################################
display_summary() {
  local project_name="$1"
  local project_dir="$2"
  
  echo ""
  echo "========================================"
  success "Django + Docker project setup complete!"
  echo "========================================"
  echo ""
  echo "Project: ${project_name}"
  echo "Location: ${project_dir}"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. cd ${project_name}"
  echo "  2. docker compose -f docker-compose.dev.yml up --build"
  echo "  3. docker compose -f docker-compose.dev.yml exec web python manage.py migrate"
  echo "  4. Visit http://localhost:8000"
  echo ""
  echo "For more information, see README.md"
  echo ""
}

#######################################
# Main function - orchestrates project setup.
# Arguments:
#   $1: Optional project name
# Returns:
#   0 on success, exits on failure
#######################################
main() {
  local project_name="${1:-}"
  
  # Generate project name if not provided
  if [[ -z "${project_name}" ]]; then
    project_name="$(generate_project_name)"
    log "No project name provided, generated: ${project_name}"
  fi
  
  # Validate project name (lowercase, hyphens, numbers only)
  if [[ ! "${project_name}" =~ ^[a-z0-9-]+$ ]]; then
    err "Invalid project name. Use only lowercase letters, numbers, and hyphens."
  fi
  
  local project_dir="${PWD}/${project_name}"
  
  # Run setup steps
  check_prerequisites
  create_project_directory "${project_name}"
  initialize_uv_project
  cleanup_uv_init_files
  create_django_project
  create_core_urls
  create_core_views
  update_django_settings
  update_django_urls
  create_dockerfile
  create_docker_compose_files
  create_env_files
  create_dockerignore
  create_gitignore
  create_readme "${project_name}"
  initialize_git
  
  # Display summary
  display_summary "${project_name}" "${project_dir}"
  
  return 0
}

# Execute main only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

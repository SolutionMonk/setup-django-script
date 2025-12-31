```markdown
# Django Docker Setup Script

An automated setup script that creates a Django project with Docker, PostgreSQL, and hot-reload support.

## What This Does

This script automatically creates a complete Django web application with:

- Django 6.0 with PostgreSQL database
- Docker containers for development and production
- Automatic code reloading during development
- All configuration files and folder structure
- Git repository initialization

## Requirements

You need these installed on your computer:

- uv - Python package manager
- Docker - Container platform
- Git - Version control

### Installing Requirements

**uv (Python package manager):**

macOS/Linux:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Windows:
```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Docker:**

Download and install Docker Desktop from https://www.docker.com/products/docker-desktop

**Git:**

Download from https://git-scm.com/downloads

## Quick Start

### Download the Script

```bash
curl -O https://raw.githubusercontent.com/yourusername/yourrepo/main/setup-django-project.sh
chmod +x setup-django-project.sh
```

### Run the Script

Interactive mode (asks questions):
```bash
./setup-django-project.sh
```

With project name:
```bash
./setup-django-project.sh my-project
```

With project name and location:
```bash
./setup-django-project.sh my-project ~/projects
```

## Usage

```
./setup-django-project.sh [PROJECT_NAME] [DIRECTORY]
```

**Arguments:**

- PROJECT_NAME - Name for your project (optional)
  - Must use lowercase letters, numbers, and hyphens only
  - Leave empty for auto-generated name
  
- DIRECTORY - Where to create the project (optional)
  - Defaults to current directory
  - Can use tilde (~) for home directory

**Options:**

- `-h`, `--help`, `-?` - Show detailed help message

## Examples

Create project in current directory (interactive):
```bash
./setup-django-project.sh
```

Create project with specific name:
```bash
./setup-django-project.sh my-blog
```

Create project in specific location:
```bash
./setup-django-project.sh my-shop ~/websites
```

Auto-generate name in specific location:
```bash
./setup-django-project.sh "" ~/projects
```

## What Gets Created

```
your-project/
├── manage.py
├── config/                  Django settings
├── core/                    Main app
├── static/                  CSS, JS, images
├── templates/               HTML files
├── Dockerfile.dev           Development container
├── Dockerfile.prod          Production container
├── docker-compose.dev.yml   Development setup
├── docker-compose.prod.yml  Production setup
├── pyproject.toml           Python dependencies
├── .env                     Development settings
├── .env.prod                Production settings
└── README.md                Project instructions
```

## After Setup

Navigate to your project:
```bash
cd your-project-name
```

Start the development server:
```bash
docker compose -f docker-compose.dev.yml up --build
```

Run database migrations (in another terminal):
```bash
docker compose -f docker-compose.dev.yml exec web-dev python manage.py migrate
```

Visit http://localhost:8000 in your browser.

## Configuration

### Development

The script creates a `.env` file with development defaults. You can edit this file to change settings like database credentials.

### Production

Before deploying, edit `.env.prod` and change:

- DJANGO_SECRET_KEY (generate a random secret)
- DJANGO_DEBUG (set to False)
- DJANGO_ALLOWED_HOSTS (your domain name)
- POSTGRES_PASSWORD (strong password)

## Troubleshooting

**Script says command not found:**

Make sure uv, docker, and git are installed and in your PATH.

**Permission denied:**

Make the script executable:
```bash
chmod +x setup-django-project.sh
```

**Directory already exists:**

The script will ask if you want to continue and overwrite.

**Port already in use:**

Stop any existing containers:
```bash
docker compose down
```

## Python and Django Versions

- Python: 3.13
- Django: 6.0+
- PostgreSQL: 18.1
- Gunicorn: 23.0+ (production)

## Project Structure Explained

**config/** - Django project settings and URLs

**core/** - Your main Django application

**static/** - CSS, JavaScript, images (served by Django in development)

**templates/** - HTML template files

**Dockerfile.dev** - Instructions for building development container

**Dockerfile.prod** - Instructions for building production container with Gunicorn

**docker-compose.dev.yml** - Development environment with hot-reload on port 8000

**docker-compose.prod.yml** - Production environment with Gunicorn on port 5000

## License

MIT License - feel free to use and modify.

## Support

For issues or questions, please open an issue on GitHub.
```

This README:
- Explains what the script does clearly
- Lists requirements with installation links
- Shows simple usage examples
- Explains all arguments and options
- Shows what gets created
- Includes troubleshooting section
- Uses plain markdown, no emojis
- Written for complete beginners
- Focused on the script itself, not the generated project
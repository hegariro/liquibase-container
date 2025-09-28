# Liquibase Docker Service

Servicio containerizado para gestión de migraciones de base de datos usando Liquibase 4.33.0, diseñado para arquitecturas de microservicios.

## 🚀 Características

- **Multi-stage Docker build** optimizado para cacheo de capas
- **Usuario no-root** para mayor seguridad
- **Configuración flexible** mediante variables de entorno
- **Soporte para múltiples bases de datos** (PostgreSQL, MySQL, Aurora, etc.)
- **Healthcheck integrado** para validación de estado
- **Script de entrada robusto** con validaciones automáticas
- **Volúmenes persistentes** para changelogs y drivers personalizados

## 📋 Requisitos

- Docker 20.10+
- Base de datos objetivo (PostgreSQL, MySQL, Aurora PostgreSQL, etc.)
- Changelogs de Liquibase organizados

## 🛠️ Configuración

### Variables de Entorno (.env)

Crea un archivo `.env` utilizando como referencia le archivo `.env.example`, se debe ver más o menos así:

```env
# Database connection
LIQUIBASE_COMMAND_URL=jdbc:postgresql://your-host:5432/database
LIQUIBASE_COMMAND_USERNAME=db_user
LIQUIBASE_COMMAND_PASSWORD=db_password
LIQUIBASE_COMMAND_DRIVER=org.postgresql.Driver

# Liquibase configuration
LIQUIBASE_COMMAND_CHANGELOG_FILE=changelog/db.changelog-master.xml
LIQUIBASE_LOG_LEVEL=INFO
```

Si haces uso del Makefile, debes crear un archivo `.env` por cada ambiente; por ejemplo, para el ambiente
de desarrollo (**develop**) debe existir el ___env file___ `.env.dev` y para el ambiente de producción
(**prod**) debe existir el ___env file___ `.env.prod`.

Para más detalles revisa los comandos de despliegue del **Makefile**.

### Estructura de Directorios

```
.
├── Dockerfile
├── docker-entrypoint.sh
├── .env
├── changelog/
│   ├── db.changelog-master.xml
│   ├── migrations/
│   └── rollbacks/
└── drivers/          # Drivers JDBC adicionales (opcional)
```

## 🚀 Uso

### Con Makefile (Recomendado)

El proyecto incluye un Makefile para simplificar las operaciones más comunes:

#### Comandos Básicos
```bash
# Construir imagen
make build

# Aplicar migraciones
make update

# Ver estado de migraciones
make status

# Validar changelogs
make validate

# Rollback a tag específico
make rollback TAG=v1.0.0
```

#### Comandos Avanzados
```bash
# Rollback de N changesets
make rollback-count COUNT=5

# Ver diferencias entre BD y changelog
make diff

# Historial de migraciones ejecutadas
make history

# Sincronizar changelog sin aplicar cambios
make changelog-sync

# Generar changelog desde BD existente
make generate-changelog
```

#### Gestión por Ambientes
```bash
# Desarrollo (usa .env.dev)
make dev

# Staging (usa .env.staging)  
make staging

# Producción (usa .env.prod con confirmación)
make prod
```

#### Utilidades
```bash
# Ver ayuda completa
make help

# Shell interactivo en el contenedor
make shell

# Limpiar imágenes no utilizadas
make clean

# Deploy completo (build + update)
make deploy

# Verificación completa (validate + status)
make check
```

#### Personalización de Variables
```bash
# Usar archivo de env específico
make update ENV_FILE=.env.staging

# Cambiar nombre e imagen
make build IMAGE_NAME=mi-liquibase IMAGE_TAG=v2.0

# Directorios personalizados
make update CHANGELOG_DIR=./migrations DRIVERS_DIR=./jdbc-drivers
```

### Uso Directo con Docker (Alternativo)

Si prefieres usar Docker directamente:

```bash
# Construcción
docker build -t my-liquibase:latest .

# Aplicar migraciones
docker run --rm --env-file .env \
  -v $(pwd)/changelog:/liquibase/changelog \
  my-liquibase:latest update

# Verificar estado
docker run --rm --env-file .env \
  -v $(pwd)/changelog:/liquibase/changelog \
  my-liquibase:latest status

# Rollback por tags
docker run --rm --env-file .env \
  -v $(pwd)/changelog:/liquibase/changelog \
  my-liquibase:latest rollback v1.0.0
```

### Ejecución con Docker Compose

```yaml
version: '3.8'
services:
  liquibase:
    build: .
    env_file: .env
    volumes:
      - ./changelog:/liquibase/changelog
      - ./drivers:/liquibase/drivers
    command: update
    depends_on:
      - database
```

## 🔧 Casos de Uso Comunes

### Para Aurora PostgreSQL (AWS)
```env
LIQUIBASE_COMMAND_URL=jdbc:postgresql://cluster.cluster-xyz.region.rds.amazonaws.com:5432/db
LIQUIBASE_COMMAND_DRIVER=org.postgresql.Driver
```

### Para diferentes entornos
```bash
# Desarrollo
docker run --rm --env-file .env.dev my-liquibase:latest update

# Staging  
docker run --rm --env-file .env.staging my-liquibase:latest update

# Producción
docker run --rm --env-file .env.prod my-liquibase:latest update
```

## 📁 Archivos Incluidos

- **`Dockerfile`**: Multi-stage build optimizado con mejores prácticas
- **`docker-entrypoint.sh`**: Script de entrada con validaciones y logging
- **`.env.example`**: Plantilla de configuración

## 🔒 Consideraciones de Seguridad

- Usuario no-root (`liquibase:1001`)
- Variables sensibles externalizadas 
- Validación de conectividad previa
- Soporte para Docker secrets

## 🤝 Integración con Microservicios

Este servicio está diseñado para integrarse con arquitecturas de microservicios:

- Ejecutar migraciones antes del despliegue de aplicaciones
- Usar en pipelines CI/CD
- Despliegue independiente por ambiente
- Rollbacks controlados

## 📊 Monitoreo

- Healthcheck integrado en puerto 8080
- Logging estructurado con timestamps
- Códigos de salida estándar para CI/CD

## Enlaces de interés

- Documentación Liquibase Pro [Liquibase Pro](https://docs.liquibase.com/pro)
- Documentación de liquibase en Dockerfile [Docker + Liquibase](https://docs.liquibase.com/oss/get-started/upgrade-to-liquibase-pro-4-32-with-docker)
- Imagen de Liquibase en DockerHub [Liquibase DockerHub](https://hub.docker.com/_/liquibase)
- Bases de datos soportadas por Liquibase [DBs soportadas](https://docs.liquibase.com/oss/integration-guide/what-databases-are-supported-by-liquibase)


---

**Desarrollado para gestión de migraciones en arquitecturas de microservicios**



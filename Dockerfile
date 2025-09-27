
FROM liquibase/liquibase:4.33.0 as base

# Stage 1: Preparación de dependencias y configuración
FROM base as dependencies
USER root

# Instalar herramientas adicionales necesarias
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Crear usuario no-root para seguridad
RUN groupadd -r liquibase && useradd -r -g liquibase -u 1001 liquibase

# Crear directorios necesarios con permisos correctos
RUN mkdir -p /liquibase/changelog \
    /liquibase/drivers \
    /liquibase/scripts \
    /liquibase/config \
    && chown -R liquibase:liquibase /liquibase

# Stage 2: Runtime optimizado
FROM base as runtime

# Copiar configuraciones desde stage anterior
COPY --from=dependencies /etc/passwd /etc/passwd
COPY --from=dependencies /etc/group /etc/group
COPY --from=dependencies --chown=liquibase:liquibase /liquibase /liquibase

# Variables de entorno para configuración
ENV LIQUIBASE_HOME=/liquibase
ENV LIQUIBASE_COMMAND_CHANGELOG_FILE=changelog/db.changelog-master.xml
ENV LIQUIBASE_COMMAND_URL=""
ENV LIQUIBASE_COMMAND_USERNAME=""
ENV LIQUIBASE_COMMAND_PASSWORD=""
ENV LIQUIBASE_COMMAND_DRIVER=""
ENV LIQUIBASE_LOG_LEVEL=INFO
ENV LIQUIBASE_HUB_MODE=off

# Configurar directorio de trabajo
WORKDIR /liquibase

# Cambiar a usuario no-root
USER liquibase

# Crear volúmenes para persistencia
VOLUME ["/liquibase/changelog", "/liquibase/drivers"]

# Exponer puerto para healthcheck si es necesario
EXPOSE 8080

# Script de entrada personalizable
COPY --chown=liquibase:liquibase docker-entrypoint.sh /liquibase/
RUN chmod +x /liquibase/docker-entrypoint.sh

# Healthcheck para verificar que Liquibase está listo
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD liquibase --version || exit 1

# Labels para metadata
LABEL maintainer="DevOps Team" \
      version="1.0" \
      description="Liquibase 4.33.0 container for database migrations" \
      liquibase.version="4.33.0"

# Punto de entrada
ENTRYPOINT ["/liquibase/docker-entrypoint.sh"]
CMD ["update"]


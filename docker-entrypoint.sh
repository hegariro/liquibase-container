#!/bin/bash
set -e

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Validaciones previas
validate_environment() {
    if [ -z "$LIQUIBASE_COMMAND_URL" ]; then
        log "ERROR: LIQUIBASE_COMMAND_URL is required"
        exit 1
    fi
    
    if [ -z "$LIQUIBASE_COMMAND_USERNAME" ]; then
        log "WARNING: LIQUIBASE_COMMAND_USERNAME not set"
    fi
}

# Configurar drivers adicionales si existen
setup_drivers() {
    if [ -d "/liquibase/drivers" ] && [ "$(ls -A /liquibase/drivers)" ]; then
        log "Setting up additional JDBC drivers..."
        export LIQUIBASE_COMMAND_CLASSPATH="/liquibase/drivers/*:$LIQUIBASE_COMMAND_CLASSPATH"
    fi
}

# Verificar conectividad a base de datos
check_database_connectivity() {
    log "Checking database connectivity..."
    timeout 30 liquibase validate || {
        log "ERROR: Cannot connect to database or changelog validation failed"
        exit 1
    }
}

# Función principal
main() {
    log "Starting Liquibase container..."
    log "Liquibase version: $(liquibase --version)"
    
    validate_environment
    setup_drivers
    
    # Si el comando es update, validate, o otros comandos de migración, verificar conectividad
    case "$1" in
        update|rollback*|validate|status|diff*|generate*)
            check_database_connectivity
            ;;
    esac
    
    log "Executing Liquibase command: $*"
    
    # Ejecutar comando de Liquibase
    exec liquibase "$@"
}

# Si se pasa un comando personalizado (no de Liquibase), ejecutarlo directamente
if [ "${1:0:1}" = '-' ] || [ "$1" = "liquibase" ]; then
    main "$@"
elif command -v "$1" > /dev/null 2>&1; then
    log "Executing custom command: $*"
    exec "$@"
else
    main "$@"
fi


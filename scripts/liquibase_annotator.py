#!/usr/bin/env python3
"""
Liquibase Annotator Script
Procesa archivos SQL y los convierte a formato Liquibase con información del commit
"""

import argparse
import sys
import os
import datetime

# Configuration por defecto
DEFAULT_MIGRATIONS_DIR = "migrations"
DEFAULT_OUTPUT_DIR = "changelogs"
DEFAULT_AUTHOR = "Anonymous"

def main():
    # Configurar argumentos de línea de comandos
    parser = argparse.ArgumentParser(description='Convierte archivos SQL a formato Liquibase con información del commit')
    
    parser.add_argument('--author', 
                       default=DEFAULT_AUTHOR,
                       help=f'Nombre del autor del commit (default: {DEFAULT_AUTHOR})')
    
    parser.add_argument('--message', 
                       required=False,
                       help='Mensaje del commit')
    
    parser.add_argument('--email', 
                       required=False,
                       help='Email del autor del commit')
    
    parser.add_argument('--hash', 
                       required=False,
                       help='Hash corto del commit')
    
    parser.add_argument('--migrations-dir', 
                       default=DEFAULT_MIGRATIONS_DIR,
                       help=f'Directorio de archivos SQL origen (default: {DEFAULT_MIGRATIONS_DIR})')
    
    parser.add_argument('--output-dir', 
                       default=DEFAULT_OUTPUT_DIR,
                       help=f'Directorio de salida para changelogs (default: {DEFAULT_OUTPUT_DIR})')
    
    # Parsear argumentos
    args = parser.parse_args()
    
    # Mostrar información recibida
    print("🚀 Ejecutando Liquibase Annotator")
    print(f"📝 Autor: {args.author}")
    print(f"💬 Mensaje: {args.message or 'No especificado'}")
    print(f"📧 Email: {args.email or 'No especificado'}")
    print(f"🔗 Hash: {args.hash or 'No especificado'}")
    print(f"📁 Directorio origen: {args.migrations_dir}")
    print(f"📁 Directorio destino: {args.output_dir}")
    print("-" * 60)
    
    try:
        # Procesar migraciones
        process_migrations(args)
        
        print("✅ Procesamiento completado exitosamente")
        
    except Exception as e:
        print(f"❌ Error durante el procesamiento: {e}")
        sys.exit(1)

def ensure_output_dir(output_dir: str):
    """Crear directorio de salida si no existe"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"📁 Directorio creado: {output_dir}")

def generate_changeset(sql_file: str, content: str, args) -> str:
    """Generar changeset de Liquibase con información del commit"""
    base_name = os.path.splitext(os.path.basename(sql_file))[0]
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    changeset_id = f"{base_name}-{timestamp}"
    
    # Header de Liquibase con información del commit
    liquibase_header = [
        "--liquibase formatted sql",
        f"--changeset {args.author}:{changeset_id}"
    ]
    
    # Agregar información adicional del commit si está disponible
    if args.message:
        liquibase_header.append(f"--comment {args.message}")
    
    if args.hash:
        liquibase_header.append(f"--labels commit-{args.hash}")
    
    # Rollback placeholder
    liquibase_header.extend([
        f"--rollback /* TODO: agregar rollback para {base_name} */",
        ""
    ])
    
    # Metadata adicional como comentarios
    metadata_comments = []
    if args.email:
        metadata_comments.append(f"-- Autor Email: {args.email}")
    if args.hash:
        metadata_comments.append(f"-- Commit Hash: {args.hash}")
    if args.message:
        metadata_comments.append(f"-- Commit Message: {args.message}")
    
    metadata_comments.append(f"-- Generado: {datetime.datetime.now().isoformat()}")
    metadata_comments.append("")
    
    # Combinar header + metadata + contenido SQL
    full_content = (
        "\n".join(liquibase_header) + 
        "\n".join(metadata_comments) + 
        "\n" + content.strip() + "\n"
    )
    
    return full_content

def process_migrations(args):
    """Procesar todos los archivos SQL del directorio de migraciones"""
    ensure_output_dir(args.output_dir)
    
    if not os.path.exists(args.migrations_dir):
        print(f"⚠️  Directorio {args.migrations_dir} no encontrado")
        return
    
    processed_files = 0
    
    # Recorrer recursivamente toda la estructura de directorios
    for root, dirs, files in os.walk(args.migrations_dir):
        for filename in files:
            if filename.endswith(".sql"):
                # Ruta completa del archivo origen
                input_path = os.path.join(root, filename)
                
                # Calcular la ruta relativa desde migrations_dir
                relative_path = os.path.relpath(input_path, args.migrations_dir)
                
                # Construir la ruta de destino manteniendo la estructura
                output_path = os.path.join(args.output_dir, relative_path)
                
                # Crear los directorios necesarios en destino
                output_subdir = os.path.dirname(output_path)
                if output_subdir and not os.path.exists(output_subdir):
                    os.makedirs(output_subdir)
                    print(f"📁 Directorio creado: {output_subdir}")
                
                try:
                    # Leer archivo SQL original
                    with open(input_path, "r", encoding="utf-8") as f:
                        sql_content = f.read()
                    
                    # Generar changeset de Liquibase
                    changeset_content = generate_changeset(filename, sql_content, args)
                    
                    # Escribir archivo procesado
                    with open(output_path, "w", encoding="utf-8") as f:
                        f.write(changeset_content)
                    
                    print(f"✅ Archivo procesado: {relative_path}")
                    print(f"   📁 {input_path} => {output_path}")
                    processed_files += 1
                    
                except Exception as e:
                    print(f"❌ Error procesando {relative_path}: {e}")
    
    if processed_files == 0:
        print("⚠️  No se encontraron archivos .sql para procesar")
    else:
        print(f"🎉 Total de archivos procesados: {processed_files}")
        print(f"📁 Estructura de directorios conservada en: {args.output_dir}")

if __name__ == "__main__":
    main()






#!/user/bin/env python3
import os
import datetime

# Configuration
MIGRATIONS_DIR = "migrations"
OUTPUT_DIR = "changelogs"
AUTHOR = "heiner"

def ensure_output_dir():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

def generate_changeset(sql_file: str, content: str) -> str:
    base_name = os.path.splitext(os.path.basename(sql_file))[0]
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    changeset_id = f"{base_name}-{timestamp}"

    liquibase_header = [
        "--liquibase formatted sql",
        f"--changeset {AUTHOR}:{changeset_id}",
        f"--rollback /* TODO: agregar rollback para {base_name} */",
        ""
    ]
    return "\n".join(liquibase_header) + "\n" + content.strip() + "\n"

def process_migrations():
    ensure_output_dir()
    for filename in os.listdir(MIGRATIONS_DIR):
        if filename.endswith(".sql"):
            input_path = os.path.join(MIGRATION_DIR, filename)
            output_path = os.path.join(OUTPUT, filename)
            with open(input_path, "r", encoding="utf-8") as f:
                sql_content = f.read()
            changeset_content = generate_changeset(filename, sql_content)

            with open(output_path, "w", encoding="utf-8") as f:
                f.write(changeset_content)

            print(f"Archivo procesado {filename} => {output_path}")

if __name__ == "__main__":
    process_migrations()


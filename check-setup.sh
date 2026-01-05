#!/bin/bash

# Script para verificar la configuración de AuraMovies
# Ejecutar: chmod +x check-setup.sh && ./check-setup.sh

echo "🎬 AuraMovies - Verificación de Configuración"
echo "=============================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Contadores
ERRORS=0
WARNINGS=0

# Función para verificar
check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        ((ERRORS++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# 1. Verificar MongoDB
echo "📦 Verificando MongoDB..."
if command -v mongod &> /dev/null; then
    check 0 "MongoDB instalado"
    
    # Verificar si está corriendo
    if pgrep -x "mongod" > /dev/null; then
        check 0 "MongoDB está corriendo"
        
        # Intentar conectar
        if mongosh --eval "db.version()" --quiet &> /dev/null; then
            check 0 "Conexión a MongoDB exitosa"
        else
            check 1 "No se puede conectar a MongoDB"
        fi
    else
        warn "MongoDB no está corriendo. Ejecuta: brew services start mongodb-community"
    fi
else
    check 1 "MongoDB no encontrado. Instálalo con: brew install mongodb-community"
fi

echo ""

# 2. Verificar archivo .env
echo "🔧 Verificando configuración del Backend..."
if [ -f "Backend/.env" ]; then
    check 0 "Archivo .env existe"
    
    # Verificar variables
    source Backend/.env 2>/dev/null
    
    if [ ! -z "$MONGO_HOST" ]; then
        check 0 "MONGO_HOST configurado: $MONGO_HOST"
    else
        check 1 "MONGO_HOST no está configurado"
    fi
    
    if [ ! -z "$PORT" ]; then
        check 0 "PORT configurado: $PORT"
    else
        check 1 "PORT no está configurado"
    fi
    
    if [ ! -z "$SMTP_EMAIL" ]; then
        if [[ "$SMTP_EMAIL" == *"@gmail.com"* ]] && [[ "$SMTP_EMAIL" != "tucorreo@gmail.com" ]]; then
            check 0 "SMTP_EMAIL configurado"
        else
            warn "SMTP_EMAIL debe ser actualizado con tu email real"
        fi
    else
        check 1 "SMTP_EMAIL no está configurado"
    fi
    
    if [ ! -z "$SMTP_PASSWORD" ]; then
        if [[ "$SMTP_PASSWORD" != "tu-password-app" ]]; then
            check 0 "SMTP_PASSWORD configurado"
        else
            warn "SMTP_PASSWORD debe ser actualizado con tu contraseña de aplicación de Gmail"
        fi
    else
        check 1 "SMTP_PASSWORD no está configurado"
    fi
    
    if [ ! -z "$TMDB_API_KEY" ]; then
        check 0 "TMDB_API_KEY configurado"
    else
        check 1 "TMDB_API_KEY no está configurado"
    fi
else
    check 1 "Archivo Backend/.env no encontrado"
fi

echo ""

# 3. Verificar Swift
echo "🔨 Verificando Swift..."
if command -v swift &> /dev/null; then
    SWIFT_VERSION=$(swift --version | head -n 1)
    check 0 "Swift instalado: $SWIFT_VERSION"
else
    check 1 "Swift no encontrado. Instala Xcode Command Line Tools"
fi

echo ""

# 4. Verificar dependencias del Backend
echo "📚 Verificando Backend..."
if [ -d "Backend" ]; then
    check 0 "Directorio Backend existe"
    
    if [ -f "Backend/Package.swift" ]; then
        check 0 "Package.swift encontrado"
    else
        check 1 "Package.swift no encontrado"
    fi
    
    # Verificar archivos clave
    if [ -f "Backend/Sources/Backend/main.swift" ]; then
        check 0 "main.swift encontrado"
    else
        check 1 "main.swift no encontrado"
    fi
    
    if [ -f "Backend/Sources/Backend/Controllers/AuthController.swift" ]; then
        check 0 "AuthController.swift encontrado"
    else
        check 1 "AuthController.swift no encontrado"
    fi
else
    check 1 "Directorio Backend no encontrado"
fi

echo ""

# 5. Verificar App iOS
echo "📱 Verificando App iOS..."
if [ -d "App" ]; then
    check 0 "Directorio App existe"
    
    if [ -f "App/AuraMovies.xcodeproj/project.pbxproj" ]; then
        check 0 "Proyecto Xcode encontrado"
    else
        check 1 "Proyecto Xcode no encontrado"
    fi
    
    # Verificar archivos clave
    if [ -f "App/AuraMovies/App/AuraMoviesApp.swift" ]; then
        check 0 "AuraMoviesApp.swift encontrado"
    else
        check 1 "AuraMoviesApp.swift no encontrado"
    fi
    
    if [ -f "App/AuraMovies/Core/Networking/AuthService.swift" ]; then
        check 0 "AuthService.swift encontrado"
    else
        check 1 "AuthService.swift no encontrado"
    fi
    
    # Verificar assets
    if [ -f "App/AuraMovies/App/Assets.xcassets/AppIcon.appiconset/appiconauramovies.png" ]; then
        check 0 "Logo de la app encontrado"
    else
        warn "Logo de la app no encontrado"
    fi
else
    check 1 "Directorio App no encontrado"
fi

echo ""

# 6. Verificar puerto disponible
echo "🔌 Verificando puerto 8080..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    warn "Puerto 8080 ya está en uso. Puede que el backend ya esté corriendo."
else
    check 0 "Puerto 8080 disponible"
fi

echo ""
echo "=============================================="
echo "📊 Resumen:"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Todo configurado correctamente!${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Iniciar el backend:"
    echo "   cd Backend && swift run"
    echo ""
    echo "2. Abrir y ejecutar la app:"
    echo "   cd App && open AuraMovies.xcodeproj"
else
    echo -e "${RED}❌ Se encontraron $ERRORS errores${NC}"
    echo ""
    echo "Por favor, revisa los errores arriba y corrígelos antes de continuar."
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Se encontraron $WARNINGS advertencias${NC}"
    echo ""
    echo "Las advertencias no bloquean la ejecución, pero deberían revisarse."
fi

echo ""
echo "📖 Para más información, consulta la guía de configuración."
echo ""

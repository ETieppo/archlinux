#!/bin/bash

THEME_NAME="space"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================="
echo "  Instalador do Tema SDDM - Space"
echo "==================================="
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root"
    echo "   Use: sudo ./install.sh"
    exit 1
fi

# Verificar se o SDDM está instalado
if ! command -v sddm &> /dev/null; then
    echo "❌ SDDM não está instalado!"
    echo "   Instale com: sudo pacman -S sddm"
    exit 1
fi

# Criar diretório do tema
echo "📁 Criando diretório do tema..."
mkdir -p "$THEME_DIR"

# Copiar arquivos do tema
echo "📋 Copiando arquivos..."
cp -r "$SCRIPT_DIR"/* "$THEME_DIR/"
rm -f "$THEME_DIR/install.sh"

# Definir permissões corretas
echo "🔒 Configurando permissões..."
chmod 755 "$THEME_DIR"
chmod 644 "$THEME_DIR"/*
chmod 644 "$THEME_DIR"/*.jpg 2>/dev/null
chmod 644 "$THEME_DIR"/*.jpeg 2>/dev/null
chmod 644 "$THEME_DIR"/*.qml 2>/dev/null

# Configurar SDDM para usar o tema
echo "⚙️  Configurando SDDM..."
SDDM_CONF="/etc/sddm.conf"

if [ ! -f "$SDDM_CONF" ]; then
    echo "[Theme]" > "$SDDM_CONF"
    echo "Current=$THEME_NAME" >> "$SDDM_CONF"
else
    if grep -q "^\[Theme\]" "$SDDM_CONF"; then
        sed -i "/^\[Theme\]/,/^\[/ s/^Current=.*/Current=$THEME_NAME/" "$SDDM_CONF"
    else
        echo "" >> "$SDDM_CONF"
        echo "[Theme]" >> "$SDDM_CONF"
        echo "Current=$THEME_NAME" >> "$SDDM_CONF"
    fi
fi

echo ""
echo "✅ Tema instalado com sucesso!"
echo ""
echo "📍 Local: $THEME_DIR"
echo "🎨 Tema ativo: $THEME_NAME"
echo ""
echo "Para testar o tema, execute:"
echo "   sddm-greeter --test-mode --theme $THEME_DIR"
echo ""
echo "Para habilitar o SDDM na inicialização:"
echo "   sudo systemctl enable sddm"
echo "   sudo systemctl start sddm"
echo ""

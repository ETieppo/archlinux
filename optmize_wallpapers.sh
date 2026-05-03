#!/usr/bin/env bash
#
# optimize-wallpapers.sh
#
# Reencoda vídeos de wallpaper pra resolução do monitor + 30fps + H.264
# sem áudio. Sobrescreve os arquivos originais (via temp file pra
# evitar corrupção). Idempotente: pula o que já está dentro do alvo.
#
# Uso:
#   ./optimize-wallpapers.sh                        # usa ~/.local/share/wallpapers
#   ./optimize-wallpapers.sh /caminho/da/pasta
#   TARGET_W=2560 TARGET_H=1440 ./optimize-wallpapers.sh
#   TARGET_FPS=24 ./optimize-wallpapers.sh

set -euo pipefail

WALLPAPER_DIR="${1:-$HOME/.local/share/wallpapers}"
TARGET_FPS="${TARGET_FPS:-30}"
EXTENSIONS=(mp4 mkv mov webm avi m4v)

# --- Detecta resolução do primeiro monitor (Hyprland) -----------------------
if [[ -z "${TARGET_W:-}" || -z "${TARGET_H:-}" ]]; then
    if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
        read -r TARGET_W TARGET_H < <(
            hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height)"'
        )
    else
        TARGET_W=1920
        TARGET_H=1080
    fi
fi

# --- Sanidade ---------------------------------------------------------------
for cmd in ffmpeg ffprobe; do
    command -v "$cmd" >/dev/null \
        || { echo "erro: '$cmd' não está instalado" >&2; exit 1; }
done

[[ -d "$WALLPAPER_DIR" ]] \
    || { echo "erro: diretório '$WALLPAPER_DIR' não existe" >&2; exit 1; }

# --- Coleta arquivos --------------------------------------------------------
shopt -s nullglob nocaseglob
files=()
for ext in "${EXTENSIONS[@]}"; do
    for f in "$WALLPAPER_DIR"/*."$ext"; do
        files+=("$f")
    done
done
shopt -u nocaseglob nullglob

if [[ ${#files[@]} -eq 0 ]]; then
    echo "nenhum vídeo encontrado em $WALLPAPER_DIR"
    exit 0
fi

# --- Resumo + confirmação ---------------------------------------------------
echo "Diretório: $WALLPAPER_DIR"
echo "Alvo:      ${TARGET_W}x${TARGET_H} @ ${TARGET_FPS}fps, H.264, sem áudio"
echo "Encontrados ${#files[@]} arquivo(s):"
for f in "${files[@]}"; do
    printf '  • %s\n' "${f##*/}"
done
echo
read -rp "Sobrescrever os originais? [y/N] " confirm
[[ "$confirm" =~ ^[yYsS]$ ]] || { echo "cancelado."; exit 0; }
echo

# --- Loop principal ---------------------------------------------------------
done_count=0
skipped=0
failed=0

for file in "${files[@]}"; do
    name="${file##*/}"
    printf '── %s\n' "$name"

    # Lê width, height e fps via ffprobe
    if ! info=$(ffprobe -v error -select_streams v:0 \
                    -show_entries stream=width,height,r_frame_rate \
                    -of csv=p=0 "$file" 2>/dev/null); then
        echo "   ✗ não foi possível ler o arquivo"
        ((++failed)); continue
    fi

    IFS=',' read -r w h fps_frac <<< "$info"
    # r_frame_rate vem como "60/1" ou "30000/1001" — converte pra inteiro
    fps=$(awk -F/ 'BEGIN{r=0} $2>0 { r=$1/$2 } END{ printf "%d", r+0.5 }' \
              <<< "$fps_frac")

    printf '   atual: %sx%s @ %sfps\n' "$w" "$h" "$fps"

    # Pula se já está dentro do alvo
    if (( w <= TARGET_W && h <= TARGET_H && fps <= TARGET_FPS )); then
        echo "   já otimizado, pulando"
        ((++skipped)); continue
    fi

    tmp="${file}.optimizing.mp4"

    if ffmpeg -y -hide_banner -loglevel error -stats \
            -i "$file" \
            -vf "scale='min(iw,${TARGET_W})':'min(ih,${TARGET_H})':force_original_aspect_ratio=decrease:force_divisible_by=2,fps=${TARGET_FPS}" \
            -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p \
            -an -movflags +faststart \
            "$tmp" </dev/null; then
        mv -f "$tmp" "$file"
        echo "   ✓ pronto"
        ((++done_count))
    else
        rm -f "$tmp"
        echo "   ✗ ffmpeg falhou"
        ((++failed))
    fi
done

echo
printf 'concluído — processados: %d, pulados: %d, falhas: %d\n' \
    "$done_count" "$skipped" "$failed"

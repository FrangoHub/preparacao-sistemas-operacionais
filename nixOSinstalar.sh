#!/usr/bin/env bash
# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS — VERSÃO NIXOS
# ============================================================
# Baseado no script original (Ubuntu/Debian) adaptado para NixOS.
#
# O que muda em relação ao original:
#   - APT/dpkg  → nix-env -iA nixpkgs.<pkg>
#   - Snap      → substituído por tentativa via nixpkgs
#   - chsh      → usermod (imperativo, volátil a rebuilds)
#   - Terminal  → xdg-terminal-exec + variáveis de ambiente
#   - batcat    → no NixOS o binário é `bat`
#   - Oh My Zsh → instalação manual (Home Manager é o ideal)
# ============================================================

set -o pipefail

# ---------- cores ----------
RESET='\033[0m'; BOLD='\033[1m'
GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
BLUE='\033[34m'; CYAN='\033[36m'

info()    { echo -e "${BLUE}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warning() { echo -e "${YELLOW}[AVISO]${RESET} $*"; }
error()   { echo -e "${RED}[ERRO]${RESET} $*"; }
title()   { echo; echo -e "${CYAN}${BOLD}============================================================${RESET}";
            echo -e "${CYAN}${BOLD}$*${RESET}";
            echo -e "${CYAN}${BOLD}============================================================${RESET}"; echo; }

# ---------- verificar Bash ----------
if [ -z "${BASH_VERSION:-}" ]; then
    error "Execute com Bash: bash script.sh"
    exit 1
fi

# ---------- não executar como root ----------
if [ "$(id -u)" -eq 0 ]; then
    error "Não execute como root. Use um usuário normal com sudo."
    exit 1
fi

# ---------- detectar NixOS ----------
if [ ! -e /etc/NIXOS ]; then
    error "Este script é destinado ao NixOS. /etc/NIXOS não encontrado."
    exit 1
fi

# ---------- variáveis ----------
USUARIO_ATUAL="$(id -un)"
HOME_USUARIO="$HOME"
LOG_DIRETORIO="/var/log/preparacao_sistemas_operacionais"
DATA_EXECUCAO="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIRETORIO/$DATA_EXECUCAO.log"

MARCADOR_ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
MARCADOR_ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
MARCADOR_ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"
MARCADOR_ETAPA4="$HOME_USUARIO/.sistemas_operacionais_etapa4"

ZSHRC="$HOME_USUARIO/.zshrc"
FISH_CONFIG="$HOME_USUARIO/.config/fish/config.fish"
FISH_PLUGINS="$HOME_USUARIO/.config/fish/fish_plugins"

TERMINAL_GRAFICO=""
SHELL_PADRAO=""

# ---------- /dev/tty ----------
if [ ! -r /dev/tty ]; then
    error "É necessário um terminal interativo (/dev/tty)."
    exit 1
fi

# ---------- sudo ----------
title "AUTENTICAÇÃO DO SUDO"
info "Será necessário sudo para criar logs e, se possível, alterar o shell."
if ! sudo -v </dev/tty; then
    error "Falha na autenticação com sudo."
    exit 1
fi
success "Sudo autenticado."

# ---------- log ----------
if [ ! -d "$LOG_DIRETORIO" ]; then
    if ! sudo mkdir -p "$LOG_DIRETORIO"; then
        warning "Não foi possível criar $LOG_DIRETORIO. Usando log no home."
        LOG_DIRETORIO="$HOME_USUARIO"
        LOG_FILE="$HOME_USUARIO/preparacao_nixos_$DATA_EXECUCAO.log"
    fi
fi

if ! sudo touch "$LOG_FILE"; then
    warning "Não foi possível criar log em $LOG_FILE. Usando $HOME_USUARIO."
    LOG_FILE="$HOME_USUARIO/preparacao_nixos_$DATA_EXECUCAO.log"
    touch "$LOG_FILE"
else
    sudo chown "$USUARIO_ATUAL:$USUARIO_ATUAL" "$LOG_FILE" 2>/dev/null || true
    chmod 640 "$LOG_FILE" 2>/dev/null || true
fi

registrar() { echo "$*" | tee -a "$LOG_FILE"; }
registrar ""; registrar "============================================================"
registrar "PREPARAÇÃO NIXOS — $USUARIO_ATUAL — $(date)"
registrar "Log: $LOG_FILE"
registrar "============================================================"; registrar ""

success "Log: $LOG_FILE"

# ---------- funções Nix ----------
nix_instalar() {
    local pkg="$1"
    if command -v "$pkg" >/dev/null 2>&1; then
        info "$pkg já está disponível."
        return 0
    fi
    info "Instalando $pkg via nix-env..."
    if nix-env -iA "nixpkgs.$pkg" 2>&1 | tee -a "$LOG_FILE"; then
        success "$pkg instalado."
        return 0
    else
        error "Falha ao instalar $pkg."
        return 1
    fi
}

confirmar_reexecucao() {
    local numero="$1"; local desc="$2"; local marcador="$3"; local resp
    if [ ! -f "$marcador" ]; then
        read -r -p "Deseja executar a Etapa $numero ($desc)? [S/n]: " resp </dev/tty
        case "$resp" in ""|S|s|SIM|sim|Sim) return 0;; *) return 1;; esac
    fi
    success "Etapa $numero já concluída anteriormente."
    read -r -p "Deseja executar novamente? [s/N]: " resp </dev/tty
    case "$resp" in S|s|SIM|sim|Sim) return 0;; *) return 1;; esac
}

# ============================================================
# ETAPA 1 — Zsh + Oh My Zsh
# ============================================================
executar_etapa1() {
    title "ETAPA 1 — ZSH + OH MY ZSH"
    if ! confirmar_reexecucao 1 "Zsh + Oh My Zsh" "$MARCADOR_ETAPA1"; then
        warning "Etapa 1 ignorada."; return 0
    fi

    nix_instalar zsh   || return 1
    nix_instalar curl  || return 1
    nix_instalar git   || return 1
    nix_instalar nano  || return 1

    if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then
        success "Oh My Zsh já existe."
    else
        info "Instalando Oh My Zsh..."
        if RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            2>&1 | tee -a "$LOG_FILE"; then
            success "Oh My Zsh instalado."
        else
            error "Falha ao instalar Oh My Zsh."; return 1
        fi
    fi

    [ -f "$ZSHRC" ] && [ ! -f "$ZSHRC.etapa1.backup" ] && cp "$ZSHRC" "$ZSHRC.etapa1.backup" && success "Backup do .zshrc criado."
    touch "$ZSHRC"
    if grep -q '^ZSH_THEME=' "$ZSHRC"; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"
    else
        echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"
    fi
    success "Tema Agnoster configurado."

    warning "No NixOS, a forma recomendada é usar Home Manager:"
    warning "  programs.zsh.ohMyZsh.enable = true;"

    touch "$MARCADOR_ETAPA1"
    success "Etapa 1 concluída."
}

# ============================================================
# ETAPA 2 — Aplicativos (sem Snap)
# ============================================================
executar_etapa2() {
    title "ETAPA 2 — APLICATIVOS (SEM SNAP)"
    if ! confirmar_reexecucao 2 "Aplicativos" "$MARCADOR_ETAPA2"; then
        warning "Etapa 2 ignorada."; return 0
    fi

    nix_instalar emacs       || true
    nix_instalar figlet      || true
    nix_instalar lolcat      || true
    nix_instalar ksudoku     || true
    nix_instalar terminator  || true
    nix_instalar neovim      || true   # substitui nvim via Snap

    if [ ! -d "$HOME_USUARIO/figlet-fonts" ]; then
        info "Clonando figlet-fonts..."
        if git clone https://github.com/xero/figlet-fonts.git "$HOME_USUARIO/figlet-fonts" 2>&1 | tee -a "$LOG_FILE"; then
            success "figlet-fonts instalado."
        else
            warning "Não foi possível clonar figlet-fonts."
        fi
    else
        success "figlet-fonts já existe."
    fi

    FIGLET_LINHA='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'
    if ! grep -Fqx "$FIGLET_LINHA" "$ZSHRC" 2>/dev/null; then
        echo "$FIGLET_LINHA" >> "$ZSHRC"
        success "Banner Figlet adicionado ao .zshrc."
    fi

    mkdir -p "$HOME_USUARIO/config"
    if [ -d "$HOME_USUARIO/config/nvim/.git" ]; then
        success "Kickstart.nvim já existe."
    elif [ -e "$HOME_USUARIO/config/nvim" ]; then
        warning "$HOME_USUARIO/config/nvim já existe e não é repositório Git. Não será sobrescrito."
    else
        info "Clonando Kickstart.nvim..."
        if git clone https://github.com/nvim-lua/kickstart.nvim.git "$HOME_USUARIO/config/nvim" 2>&1 | tee -a "$LOG_FILE"; then
            success "Kickstart.nvim instalado."
        else
            error "Falha ao clonar Kickstart.nvim."; return 1
        fi
    fi

    nix_instalar cool-retro-term || true

    if nix-env -qaP 'nixpkgs.mari0' >/dev/null 2>&1; then
        nix_instalar mari0 || true
    else
        warning "mari0 não está disponível no nixpkgs desta versão. Ignorando."
    fi

    touch "$MARCADOR_ETAPA2"
    success "Etapa 2 concluída."
}

# ============================================================
# ETAPA 3 — Ferramentas finais
# ============================================================
executar_etapa3() {
    title "ETAPA 3 — FERRAMENTAS FINAIS"
    if ! confirmar_reexecucao 3 "Ferramentas" "$MARCADOR_ETAPA3"; then
        warning "Etapa 3 ignorada."; return 0
    fi

    nix_instalar neofetch || true
    nix_instalar jq       || true
    nix_instalar bat      || true

    if command -v bat >/dev/null 2>&1; then
        if ! grep -Fqx 'alias cat="bat"' "$ZSHRC" 2>/dev/null; then
            echo 'alias cat="bat"' >> "$ZSHRC"
            success 'Alias cat → bat adicionado ao .zshrc.'
        fi
    elif command -v batcat >/dev/null 2>&1; then
        if ! grep -Fqx 'alias cat="batcat"' "$ZSHRC" 2>/dev/null; then
            echo 'alias cat="batcat"' >> "$ZSHRC"
            success 'Alias cat → batcat adicionado ao .zshrc.'
        fi
    fi

    touch "$MARCADOR_ETAPA3"
    success "Etapa 3 concluída."
}

# ============================================================
# ETAPA 4 — Ghostty + Fish + Tide
# ============================================================
executar_etapa4() {
    title "ETAPA 4 — GHOSTTY + FISH + TIDE"
    if ! confirmar_reexecucao 4 "Ghostty + Fish + Tide" "$MARCADOR_ETAPA4"; then
        warning "Etapa 4 ignorada."; return 0
    fi

    nix_instalar curl || true
    nix_instalar fish || true
    nix_instalar ghostty || {
        warning "Ghostty não pôde ser instalado via nix-env. Tente manualmente: nix-env -iA nixpkgs.ghostty"
    }

    if fish -c 'type -q fisher' >/dev/null 2>&1; then
        success "Fisher já instalado."
    else
        info "Instalando Fisher..."
        if fish -c \
            'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; fisher install jorgebucaran/fisher' \
            </dev/null 2>&1 | tee -a "$LOG_FILE"; then
            success "Fisher instalado."
        else
            warning "Falha ao instalar Fisher."
        fi
    fi

    if fish -c 'type -q tide' >/dev/null 2>&1; then
        success "Tide já instalado."
    else
        info "Instalando Tide v6..."
        if fish -c 'fisher install IlanCosman/tide@v6' </dev/null 2>&1 | tee -a "$LOG_FILE"; then
            success "Tide instalado."
        else
            warning "Falha ao instalar Tide."
        fi
    fi

    if command -v bat >/dev/null 2>&1; then
        mkdir -p "$HOME_USUARIO/.config/fish"
        touch "$FISH_CONFIG"
        if ! grep -q '^function cat$' "$FISH_CONFIG" 2>/dev/null; then
            cat >> "$FISH_CONFIG" <<'EOF'

# cat usando bat
function cat
    bat $argv
end
EOF
            success 'Função cat → bat adicionada ao Fish.'
        fi
    fi

    touch "$MARCADOR_ETAPA4"
    success "Etapa 4 concluída."
}

# ============================================================
# PERSONALIZAR GHOSTTY
# ============================================================
personalizar_ghostty() {
    local resp
    local dir="$HOME_USUARIO/.imagemghostty"
    local img="$HOME_USUARIO/.imagemghostty/1295199.jpg"
    local cfg_dir="$HOME_USUARIO/.config/ghostty"
    local cfg="$cfg_dir/config"
    local url="https://images.alphacoders.com/129/thumb-1920-1295199.jpg"

    echo; read -r -p "Aplicar personalização ao Ghostty (imagem + fonte)? [s/N]: " resp </dev/tty
    case "$resp" in S|s|SIM|sim|Sim) ;; *) info "Ignorado."; return 0;; esac

    mkdir -p "$dir" "$cfg_dir" || return 1

    if [ ! -s "$img" ]; then
        info "Baixando imagem..."
        if ! curl -fL --retry 2 --connect-timeout 15 "$url" -o "$img.part" 2>&1 | tee -a "$LOG_FILE"; then
            rm -f "$img.part"; error "Download falhou."; return 1
        fi
        if ! file "$img.part" | grep -qiE 'image|JPEG'; then
            rm -f "$img.part"; error "Arquivo não é imagem válida."; return 1
        fi
        mv "$img.part" "$img"; success "Imagem salva em $img"
    else
        info "Imagem já existe."
    fi

    if ! fc-list 2>/dev/null | grep -qi 'JetBrains Mono'; then
        info "Instalando JetBrains Mono Nerd Font..."
        local font_dir="$HOME_USUARIO/.local/share/fonts"
        mkdir -p "$font_dir"
        local zip="$HOME_USUARIO/.cache/JetBrainsMono.zip"
        mkdir -p "$(dirname "$zip")"
        if curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$zip" 2>&1 | tee -a "$LOG_FILE"; then
            if command -v unzip >/dev/null 2>&1; then
                unzip -o "$zip" -d "$font_dir" 2>&1 | tee -a "$LOG_FILE"
                fc-cache -f 2>&1 | tee -a "$LOG_FILE"
                success "JetBrains Mono Nerd Font instalada em $font_dir"
            else
                warning "unzip não encontrado; instale com nix-env -iA nixpkgs.unzip e extraia $zip manualmente."
            fi
        else
            warning "Não foi possível baixar JetBrains Mono; o Ghostty usará fonte substituta."
        fi
    fi

    touch "$cfg" || return 1
    local tmp; tmp="$(mktemp)" || return 1
    if [ -f "$cfg" ]; then
        awk '
            /^# BEGIN PREPARACAO_SO_GHOSTTY_THEME$/ {skip=1; next}
            /^# END PREPARACAO_SO_GHOSTTY_THEME$/ {skip=0; next}
            !skip {print}
        ' "$cfg" > "$tmp"
    fi

    cat >> "$tmp" <<EOF

# BEGIN PREPARACAO_SO_GHOSTTY_THEME
background-image = $img
background = 101018
background-image-fit = cover
background-opacity = 1
background-blur = 10
background-image-opacity = 0.35
font-size = 12
font-family = JetBrains Mono
font-thicken = true
gtk-single-instance = true
# END PREPARACAO_SO_GHOSTTY_THEME
EOF

    if mv "$tmp" "$cfg"; then
        success "Configuração do Ghostty salva em $cfg"
    else
        rm -f "$tmp"; error "Falha ao salvar configuração."; return 1
    fi

    if pgrep -x ghostty >/dev/null 2>&1; then
        info "Recarregando Ghostty..."
        if pkill -SIGUSR2 -x ghostty 2>/dev/null; then
            success "Sinal de recarga enviado."
        else
            warning "Falha ao recarregar. Feche e abra manualmente."
        fi
    else
        info "Ghostty não está em execução; configuração aplicada na próxima abertura."
    fi
}

# ============================================================
# ALTERAR SHELL (IMPERATIVO — via usermod)
# ============================================================
alterar_shell_imperativo() {
    local shell_nome="$1"
    local shell_path
    shell_path="$(command -v "$shell_nome" 2>/dev/null)"

    if [ -z "$shell_path" ]; then
        error "Shell $shell_nome não encontrado."
        return 1
    fi

    info "Alterando shell padrão para $shell_nome via usermod..."

    if sudo usermod -s "$shell_path" "$USUARIO_ATUAL" 2>&1 | tee -a "$LOG_FILE"; then
        success "Shell alterado para $shell_nome nesta sessão."
        warning "ATENÇÃO: esta alteração é volátil. O próximo 'nixos-rebuild switch' pode revertê-la."
        warning "Para tornar permanente, edite /etc/nixos/configuration.nix:"
        warning "  users.users.$USUARIO_ATUAL.shell = pkgs.$shell_nome;"
        return 0
    else
        error "Falha ao alterar o shell com usermod."
        warning "Verifique se 'users.mutableUsers = true' está definido no configuration.nix."
        return 1
    fi
}

# ============================================================
# ALTERAR TERMINAL (IMPERATIVO — via xdg-terminal-exec e variáveis)
# ============================================================
alterar_terminal_imperativo() {
    local terminal_bin="$1"
    local terminal_path
    terminal_path="$(command -v "$terminal_bin" 2>/dev/null)"

    if [ -z "$terminal_path" ]; then
        error "Terminal $terminal_bin não encontrado."
        return 1
    fi

    info "Definindo $terminal_bin como terminal padrão..."

    # 1. Exporta variáveis para a sessão atual
    export TERMINAL="$terminal_bin"
    export XDG_TERMINAL="$terminal_path"
    success "Variáveis TERMINAL e XDG_TERMINAL definidas para a sessão atual."

    # 2. Persiste em ~/.profile para novas sessões de login
    if ! grep -q "export TERMINAL=\"$terminal_bin\"" "$HOME_USUARIO/.profile" 2>/dev/null; then
        {
            echo ""
            echo "# Terminal padrão definido pelo script de preparação"
            echo "export TERMINAL=\"$terminal_bin\""
            echo "export XDG_TERMINAL=\"$terminal_path\""
        } >> "$HOME_USUARIO/.profile"
        success "Variáveis adicionadas a ~/.profile."
    else
        info "Variáveis já presentes em ~/.profile."
    fi

    # 3. Tenta configurar via xdg-terminal-exec, se disponível
    if command -v xdg-terminal-exec >/dev/null 2>&1; then
        info "xdg-terminal-exec encontrado. Configurando..."
        # Cria/atualiza o arquivo de configuração do xdg-terminal-exec
        local xdg_conf_dir="$HOME_USUARIO/.config"
        local xdg_conf="$xdg_conf_dir/xdg-terminal-exec.conf"
        mkdir -p "$xdg_conf_dir"
        if ! grep -qx "default=$terminal_bin" "$xdg_conf" 2>/dev/null; then
            echo "default=$terminal_bin" >> "$xdg_conf"
            success "xdg-terminal-exec configurado para $terminal_bin."
        else
            info "xdg-terminal-exec já configurado."
        fi
    else
        warning "xdg-terminal-exec não encontrado no PATH."
        warning "Instale com: nix-env -iA nixpkgs.xdg-terminal-exec"
        warning "Ou configure declarativamente no configuration.nix:"
        warning "  xdg.terminal-exec = { enable = true; settings.default = [ \"$terminal_bin.desktop\" ]; };"
    fi

    warning "Para configuração persistente em todo o sistema, use xdg.terminal-exec no configuration.nix."
    return 0
}

# ============================================================
# ESCOLHER TERMINAL GRÁFICO
# ============================================================
escolher_terminal() {
    title "ESCOLHA DO TERMINAL GRÁFICO"
    echo "1) Terminal padrão do sistema"
    echo "2) Terminator"
    echo "3) Ghostty"
    local esc
    while true; do
        read -r -p "Digite 1, 2 ou 3: " esc </dev/tty
        case "$esc" in
            1) TERMINAL_GRAFICO="padrão do sistema"; return 0;;
            2)
                if ! command -v terminator >/dev/null 2>&1; then
                    error "Terminator não instalado."; continue
                fi
                TERMINAL_GRAFICO="terminator"
                alterar_terminal_imperativo "terminator"
                return 0;;
            3)
                if ! command -v ghostty >/dev/null 2>&1; then
                    error "Ghostty não instalado."; continue
                fi
                TERMINAL_GRAFICO="ghostty"
                personalizar_ghostty || true
                alterar_terminal_imperativo "ghostty"
                return 0;;
            *) warning "Opção inválida.";;
        esac
    done
}

# ============================================================
# ESCOLHER SHELL PADRÃO
# ============================================================
escolher_shell() {
    title "ESCOLHA DO SHELL PADRÃO"
    echo "1) Zsh"
    echo "2) Fish"
    local esc
    while true; do
        read -r -p "Digite 1 ou 2: " esc </dev/tty
        case "$esc" in
            1)
                if ! command -v zsh >/dev/null 2>&1; then error "Zsh não instalado."; continue; fi
                SHELL_PADRAO="zsh"; break;;
            2)
                if ! command -v fish >/dev/null 2>&1; then error "Fish não instalado."; continue; fi
                SHELL_PADRAO="fish"; break;;
            *) warning "Opção inválida.";;
        esac
    done

    alterar_shell_imperativo "$SHELL_PADRAO"
}

# ============================================================
# EXECUÇÃO PRINCIPAL
# ============================================================
executar_etapa1
executar_etapa2
executar_etapa3
executar_etapa4

if command -v fish >/dev/null 2>&1 && fish -c 'type -q tide' >/dev/null 2>&1; then
    read -r -p "Reconfigurar Tide? [s/N]: " resp </dev/tty
    case "$resp" in S|s|SIM|sim|Sim)
        fish -c 'tide configure' </dev/tty || warning "Configuração do Tide cancelada."
    ;; esac
fi

escolher_terminal
escolher_shell

# Resumo final
title "PREPARAÇÃO CONCLUÍDA"
echo "Distribuição: NixOS $(nixos-version 2>/dev/null || echo '')"
echo "Terminal gráfico: ${TERMINAL_GRAFICO:-não definido}"
echo "Shell padrão: ${SHELL_PADRAO:-não definido}"
echo "Log: $LOG_FILE"
echo
warning "As alterações de shell e terminal são voláteis. Para persistir, edite /etc/nixos/configuration.nix."
success "Script finalizado."

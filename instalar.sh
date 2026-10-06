#!/bin/bash

# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS
# ============================================================
#
# Compatível com:
#   Ubuntu
#   Debian
#   Linux Mint
#   Pop!_OS
#
# ETAPA 1 - Zsh + Oh My Zsh
# ETAPA 2 - Aplicativos + Snap + Neovim
# ETAPA 3 - Ferramentas finais
# ETAPA 4 - Nerd Font Meslo + Ghostty + Fish + Tide
#
# NO FINAL:
#
# Terminal gráfico:
#   1) Terminal padrão do sistema
#   2) Terminator
#   3) Ghostty
#
# Shell:
#   1) Zsh
#   2) Fish
#
# ============================================================


# ============================================================
# CONFIGURAÇÕES
# ============================================================

set -o pipefail


# ============================================================
# CORES
# ============================================================

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
CYAN='\033[36m'


# ============================================================
# FUNÇÕES DE MENSAGEM
# ============================================================

info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

warning() {
    echo -e "${YELLOW}[AVISO]${RESET} $*"
}

error() {
    echo -e "${RED}[ERRO]${RESET} $*"
}

title() {
    echo
    echo -e "${CYAN}${BOLD}============================================================${RESET}"
    echo -e "${CYAN}${BOLD}$*${RESET}"
    echo -e "${CYAN}${BOLD}============================================================${RESET}"
    echo
}


# ============================================================
# VERIFICAR BASH
# ============================================================

if [ -z "${BASH_VERSION:-}" ]; then

    error "Este script precisa ser executado com Bash."

    echo
    echo "Execute usando:"
    echo
    echo "  curl -fsSL URL | bash"
    echo
    echo "ou:"
    echo
    echo "  bash preparacao_sistemas_operacionais.sh"
    echo

    exit 1

fi


# ============================================================
# NÃO EXECUTAR COMO ROOT
# ============================================================

if [ "$(id -u)" -eq 0 ]; then

    error "Não execute este script como root."

    echo
    echo "Execute como seu usuário normal."
    echo

    exit 1

fi


# ============================================================
# VARIÁVEIS
# ============================================================

USUARIO_ATUAL="$(id -un)"
HOME_USUARIO="$HOME"

LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"

MARCADOR_ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
MARCADOR_ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
MARCADOR_ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"
MARCADOR_ETAPA4="$HOME_USUARIO/.sistemas_operacionais_etapa4"

ZSHRC="$HOME_USUARIO/.zshrc"
FISH_CONFIG="$HOME_USUARIO/.config/fish/config.fish"


# ============================================================
# VERIFICAR /dev/tty
# ============================================================

if [ ! -r /dev/tty ]; then

    error "Não foi possível acessar /dev/tty."
    error "O script precisa ser executado em um terminal."

    exit 1

fi


# ============================================================
# LOG
# ============================================================

touch "$LOG_FILE" 2>/dev/null

if [ $? -ne 0 ]; then

    error "Não foi possível criar o arquivo de log:"
    error "$LOG_FILE"

    exit 1

fi


registrar() {
    echo "$*" | tee -a "$LOG_FILE"
}


registrar ""
registrar "============================================================"
registrar "PREPARAÇÃO DE SISTEMAS OPERACIONAIS"
registrar "Usuário: $USUARIO_ATUAL"
registrar "Data: $(date)"
registrar "============================================================"
registrar ""


# ============================================================
# IDENTIFICAR DISTRIBUIÇÃO
# ============================================================

if [ ! -f /etc/os-release ]; then

    error "Não foi possível encontrar /etc/os-release."

    exit 1

fi


# shellcheck disable=SC1091
source /etc/os-release


DISTRO_ID="${ID:-}"
DISTRO_ID_LIKE="${ID_LIKE:-}"


case "$DISTRO_ID" in

    ubuntu)

        DISTRIBUICAO="Ubuntu"

        ;;

    debian)

        DISTRIBUICAO="Debian"

        ;;

    linuxmint)

        DISTRIBUICAO="Linux Mint"

        ;;

    pop)

        DISTRIBUICAO="Pop!_OS"

        ;;

    *)

        if echo "$DISTRO_ID_LIKE" | grep -Eq 'debian|ubuntu'; then

            DISTRIBUICAO="${PRETTY_NAME:-$DISTRO_ID}"

            warning "Distribuição baseada em Debian/Ubuntu detectada:"
            warning "$DISTRIBUICAO"

        else

            error "Distribuição não suportada:"
            error "${PRETTY_NAME:-$DISTRO_ID}"

            exit 1

        fi

        ;;

esac


# ============================================================
# INFORMAÇÕES INICIAIS
# ============================================================

title "PREPARAÇÃO DE SISTEMAS OPERACIONAIS"

info "Distribuição: ${PRETTY_NAME:-$DISTRIBUICAO}"
info "Usuário: $USUARIO_ATUAL"
info "Home: $HOME_USUARIO"
info "Arquitetura: $(dpkg --print-architecture)"
info "Log: $LOG_FILE"

echo


# ============================================================
# VERIFICAR COMANDOS BÁSICOS
# ============================================================

for comando in apt-get dpkg sudo; do

    if ! command -v "$comando" >/dev/null 2>&1; then

        error "Comando obrigatório não encontrado: $comando"

        exit 1

    fi

done


# ============================================================
# AUTENTICAÇÃO DO SUDO
# ============================================================

title "AUTENTICAÇÃO DO SUDO"

info "O script precisa de privilégios administrativos."
info "Digite sua senha quando o sudo solicitar."
info "A senha não será armazenada pelo script."

echo


if ! sudo -v </dev/tty; then

    error "Não foi possível autenticar com sudo."

    exit 1

fi


success "Sudo autenticado."


# ============================================================
# ATUALIZAR CREDENCIAL DO SUDO
# ============================================================

atualizar_sudo() {

    sudo -v </dev/tty

}


# ============================================================
# VERIFICAR PACOTE
# ============================================================

pacote_instalado() {

    local pacote="$1"

    dpkg-query \
        -W \
        -f='${Status}' \
        "$pacote" \
        2>/dev/null \
        | grep -q "install ok installed"

}


# ============================================================
# INSTALAR PACOTE
# ============================================================

instalar_pacote() {

    local pacote="$1"


    if pacote_instalado "$pacote"; then

        info "$pacote já está instalado."

        return 0

    fi


    info "Instalando $pacote..."


    atualizar_sudo


    if sudo apt-get install -y "$pacote" \
        2>&1 | tee -a "$LOG_FILE"; then


        if pacote_instalado "$pacote"; then

            success "$pacote instalado."

            return 0

        else

            error "$pacote não foi encontrado após a instalação."

            return 1

        fi


    else

        error "Falha ao instalar $pacote."

        return 1

    fi

}


# ============================================================
# ATUALIZAR REPOSITÓRIOS
# ============================================================

atualizar_repositorios() {

    info "Atualizando repositórios APT..."


    atualizar_sudo


    if sudo apt-get update \
        2>&1 | tee -a "$LOG_FILE"; then

        success "Repositórios atualizados."

        return 0

    else

        error "Falha ao atualizar os repositórios."

        return 1

    fi

}


# ============================================================
# VERIFICAR COMANDO
# ============================================================

verificar_comando() {

    local comando="$1"


    if command -v "$comando" >/dev/null 2>&1; then

        success "Comando encontrado: $comando"

        return 0

    else

        warning "Comando não encontrado: $comando"

        return 1

    fi

}


# ============================================================
# CONFIRMAR ETAPA
# ============================================================

confirmar_etapa() {

    local numero="$1"
    local descricao="$2"
    local resposta


    echo
    echo -e "${BOLD}Etapa $numero - $descricao${RESET}"
    echo


    while true; do

        read -r \
            -p "Deseja executar esta etapa? [S/n]: " \
            resposta \
            </dev/tty


        case "$resposta" in

            "")

                return 0

                ;;

            S|s|SIM|sim|Sim)

                return 0

                ;;

            N|n|NAO|nao|Nao|NÃO|não)

                return 1

                ;;

            *)

                warning "Digite S para sim ou N para não."

                ;;

        esac

    done

}


# ============================================================
# CONFIRMAR REEXECUÇÃO DA ETAPA
# ============================================================

confirmar_reexecucao_etapa() {

    local numero="$1"
    local descricao="$2"
    local marcador="$3"
    local resposta


    # --------------------------------------------------------
    # ETAPA AINDA NÃO FOI EXECUTADA
    # --------------------------------------------------------

    if [ ! -f "$marcador" ]; then

        confirmar_etapa "$numero" "$descricao"

        return $?

    fi


    # --------------------------------------------------------
    # ETAPA JÁ FOI EXECUTADA
    # --------------------------------------------------------

    echo
    echo -e "${BOLD}Etapa $numero - $descricao${RESET}"
    echo

    success "Esta etapa já foi concluída anteriormente."

    echo


    while true; do

        read -r \
            -p "Deseja executar esta etapa novamente? [s/N]: " \
            resposta \
            </dev/tty


        case "$resposta" in

            S|s|SIM|sim|Sim)

                return 0

                ;;

            ""|N|n|NAO|nao|Nao|NÃO|não)

                return 1

                ;;

            *)

                warning "Digite S para sim ou N para não."

                ;;

        esac

    done

}


# ============================================================
# ADICIONAR LINHA AO ZSHRC
# ============================================================

adicionar_zshrc() {

    local linha="$1"


    touch "$ZSHRC"


    if ! grep -Fqx "$linha" "$ZSHRC" 2>/dev/null; then

        echo "$linha" >> "$ZSHRC"

        info "Adicionado ao .zshrc: $linha"

    fi

}


# ============================================================
# ADICIONAR LINHA AO FISH
# ============================================================

adicionar_fish() {

    local linha="$1"


    mkdir -p "$HOME_USUARIO/.config/fish"


    touch "$FISH_CONFIG"


    if ! grep -Fqx "$linha" "$FISH_CONFIG" 2>/dev/null; then

        echo "$linha" >> "$FISH_CONFIG"

        info "Adicionado ao config.fish: $linha"

    fi

}


# ============================================================
# ETAPA 1
# ============================================================

executar_etapa1() {

    title "ETAPA 1 - ZSH E OH MY ZSH"


    if ! confirmar_reexecucao_etapa \
        1 \
        "Zsh + Oh My Zsh" \
        "$MARCADOR_ETAPA1"; then

        warning "Etapa 1 ignorada."

        return 0

    fi


    atualizar_repositorios || return 1


    instalar_pacote zsh || return 1
    instalar_pacote curl || return 1
    instalar_pacote git || return 1
    instalar_pacote fonts-powerline || return 1
    instalar_pacote nano || return 1


    # --------------------------------------------------------
    # OH MY ZSH
    # --------------------------------------------------------

    if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

        success "Oh My Zsh já está instalado."

    else

        info "Instalando Oh My Zsh..."


        if RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Oh My Zsh instalado."

        else

            error "Falha ao instalar Oh My Zsh."

            return 1

        fi

    fi


    # --------------------------------------------------------
    # BACKUP
    # --------------------------------------------------------

    if [ -f "$ZSHRC" ] &&
       [ ! -f "$ZSHRC.etapa1.backup" ]; then

        cp "$ZSHRC" "$ZSHRC.etapa1.backup"

        success "Backup do .zshrc criado."

    fi


    # --------------------------------------------------------
    # ZSHRC
    # --------------------------------------------------------

    touch "$ZSHRC"


    if grep -q '^ZSH_THEME=' "$ZSHRC"; then

        sed -i \
            's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
            "$ZSHRC"

    else

        echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

    fi


    success "Tema Agnoster configurado."


    # --------------------------------------------------------
    # VERIFICAÇÕES
    # --------------------------------------------------------

    verificar_comando zsh
    verificar_comando curl
    verificar_comando git


    touch "$MARCADOR_ETAPA1"


    success "Etapa 1 concluída."

}


# ============================================================
# ETAPA 2
# ============================================================

executar_etapa2() {

    title "ETAPA 2 - APLICATIVOS, SNAP E NEOVIM"


    if ! confirmar_reexecucao_etapa \
        2 \
        "Aplicativos + Snap + Neovim" \
        "$MARCADOR_ETAPA2"; then

        warning "Etapa 2 ignorada."

        return 0

    fi


    # --------------------------------------------------------
    # LINUX MINT / SNAP
    # --------------------------------------------------------

    if [ "$DISTRO_ID" = "linuxmint" ]; then

        if [ -f "/etc/apt/preferences.d/nosnap.pref" ]; then

            warning "Linux Mint detectado."
            warning "Removendo bloqueio do Snap."


            atualizar_sudo


            sudo cp \
                "/etc/apt/preferences.d/nosnap.pref" \
                "/etc/apt/preferences.d/nosnap.pref.backup" \
                2>&1 | tee -a "$LOG_FILE"


            sudo rm \
                "/etc/apt/preferences.d/nosnap.pref" \
                2>&1 | tee -a "$LOG_FILE"


            success "Bloqueio do Snap removido."


            atualizar_repositorios || return 1

        fi

    fi


    atualizar_repositorios || return 1


    # --------------------------------------------------------
    # PACOTES APT
    # --------------------------------------------------------

    instalar_pacote emacs || return 1
    instalar_pacote figlet || return 1
    instalar_pacote lolcat || return 1
    instalar_pacote ksudoku || return 1
    instalar_pacote terminator || return 1
    instalar_pacote snapd || return 1
    instalar_pacote git || return 1


    # --------------------------------------------------------
    # FIGLET FONTS
    # --------------------------------------------------------

    if [ -d "$HOME_USUARIO/figlet-fonts" ]; then

        success "figlet-fonts já está presente."

    else

        info "Baixando figlet-fonts..."


        if git clone \
            https://github.com/xero/figlet-fonts.git \
            "$HOME_USUARIO/figlet-fonts" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "figlet-fonts instalado."

        else

            warning "Não foi possível baixar figlet-fonts."

        fi

    fi


    # --------------------------------------------------------
    # FIGLET NO ZSHRC
    # --------------------------------------------------------

    FIGLET_LINHA='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'


    if ! grep -Fqx "$FIGLET_LINHA" "$ZSHRC" 2>/dev/null; then

        echo "$FIGLET_LINHA" >> "$ZSHRC"

        success "Banner do Figlet adicionado ao .zshrc."

    fi


    # --------------------------------------------------------
    # SNAPD
    # --------------------------------------------------------

    if command -v snap >/dev/null 2>&1; then

        info "Configurando snapd..."


        atualizar_sudo


        sudo systemctl enable --now snapd.socket \
            2>&1 | tee -a "$LOG_FILE"


        sleep 3

    else

        error "snap não está disponível."

        return 1

    fi


    # ========================================================
    # NEOVIM
    # ========================================================

    title "INSTALANDO NEOVIM + KICKSTART.NVIM"


    # --------------------------------------------------------
    # INSTALAR NEOVIM
    # --------------------------------------------------------

    if snap list nvim >/dev/null 2>&1; then

        success "Neovim já está instalado."

    else

        info "Instalando Neovim pelo Snap..."


        atualizar_sudo


        if sudo snap install nvim --classic \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Neovim instalado."

        else

            error "Falha ao instalar Neovim."

            return 1

        fi

    fi


    # --------------------------------------------------------
    # KICKSTART.NVIM
    # --------------------------------------------------------

    mkdir -p "$HOME_USUARIO/config"


    if [ -d "$HOME_USUARIO/config/nvim/.git" ]; then

        success "Kickstart.nvim já está instalado."

        info "Local: $HOME_USUARIO/config/nvim"

    elif [ -e "$HOME_USUARIO/config/nvim" ]; then

        warning "O diretório $HOME_USUARIO/config/nvim já existe."

        warning "Ele não parece ser um repositório Git."

        warning "O script não irá sobrescrever esse diretório."

    else

        info "Clonando Kickstart.nvim..."


        if git clone \
            https://github.com/nvim-lua/kickstart.nvim.git \
            "$HOME_USUARIO/config/nvim" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Kickstart.nvim instalado."

        else

            error "Falha ao clonar Kickstart.nvim."

            return 1

        fi

    fi


    # --------------------------------------------------------
    # COOL RETRO TERM
    # --------------------------------------------------------

    if snap list cool-retro-term >/dev/null 2>&1; then

        success "cool-retro-term já está instalado."

    else

        info "Instalando cool-retro-term..."


        atualizar_sudo


        if sudo snap install cool-retro-term --classic \
            2>&1 | tee -a "$LOG_FILE"; then

            success "cool-retro-term instalado."

        else

            warning "Não foi possível instalar cool-retro-term."

        fi

    fi


    # --------------------------------------------------------
    # MARIO
    # --------------------------------------------------------

    if snap list mari0 >/dev/null 2>&1; then

        success "mari0 já está instalado."

    else

        info "Instalando mari0..."


        atualizar_sudo


        if sudo snap install mari0 \
            2>&1 | tee -a "$LOG_FILE"; then

            success "mari0 instalado."

        else

            warning "Não foi possível instalar mari0."

        fi

    fi


    # --------------------------------------------------------
    # VERIFICAÇÕES
    # --------------------------------------------------------

    verificar_comando emacs
    verificar_comando figlet
    verificar_comando lolcat
    verificar_comando terminator
    verificar_comando snap


    if command -v nvim >/dev/null 2>&1; then

        success "Neovim verificado."

    elif [ -x /snap/bin/nvim ]; then

        success "Neovim verificado em /snap/bin/nvim."

    else

        warning "Neovim não pôde ser verificado."

    fi


    if [ -d "$HOME_USUARIO/config/nvim/.git" ]; then

        success "Kickstart.nvim verificado."

    else

        warning "Kickstart.nvim não pôde ser verificado."

    fi


    touch "$MARCADOR_ETAPA2"


    success "Etapa 2 concluída."

}


# ============================================================
# ETAPA 3
# ============================================================

executar_etapa3() {

    title "ETAPA 3 - FERRAMENTAS"


    if ! confirmar_reexecucao_etapa \
        3 \
        "Ferramentas finais" \
        "$MARCADOR_ETAPA3"; then

        warning "Etapa 3 ignorada."

        return 0

    fi


    atualizar_repositorios || return 1


    instalar_pacote neofetch || return 1
    instalar_pacote jq || return 1
    instalar_pacote bat || return 1


    # --------------------------------------------------------
    # ALIAS CAT NO ZSH
    # --------------------------------------------------------

    if command -v batcat >/dev/null 2>&1; then

        adicionar_zshrc 'alias cat="batcat"'

        success 'Alias "cat" -> "batcat" configurado no Zsh.'

    fi


    # --------------------------------------------------------
    # VERIFICAÇÕES
    # --------------------------------------------------------

    verificar_comando neofetch
    verificar_comando jq
    verificar_comando batcat


    touch "$MARCADOR_ETAPA3"


    success "Etapa 3 concluída."

}


# ============================================================
# ETAPA 4
# ============================================================

executar_etapa4() {

    title "ETAPA 4 - GHOSTTY + FISH + TIDE"


    if ! confirmar_reexecucao_etapa \
        4 \
        "Ghostty + Fish + Tide" \
        "$MARCADOR_ETAPA4"; then

        warning "Etapa 4 ignorada."

        return 0

    fi


    atualizar_repositorios || return 1


    instalar_pacote curl || return 1
    instalar_pacote fish || return 1


    # ========================================================
    # NERD FONT MESLO
    # ========================================================

    title "INSTALANDO NERD FONT MESLO"


    DIRETORIO_FONTES="$HOME_USUARIO/.local/share/fonts/NerdFonts"


    MESLO_INSTALADA=0


    # --------------------------------------------------------
    # PROCURAR MESLO
    # --------------------------------------------------------

    if find \
        "$HOME_USUARIO/.local/share/fonts" \
        "$HOME_USUARIO/.fonts" \
        /usr/local/share/fonts \
        /usr/share/fonts \
        -type f \
        \( -iname 'Meslo*.ttf' -o -iname 'Meslo*.otf' \) \
        2>/dev/null | grep -q .; then

        MESLO_INSTALADA=1

        success "Meslo Nerd Font já está instalada."

    fi


    # --------------------------------------------------------
    # INSTALAR MESLO
    # --------------------------------------------------------

    if [ "$MESLO_INSTALADA" -eq 0 ]; then

        info "Baixando Meslo Nerd Font..."


        ARQUIVO_MESLO="$HOME_USUARIO/.cache/preparacao_sistemas_operacionais/Meslo.zip"


        mkdir -p "$(dirname "$ARQUIVO_MESLO")"
        mkdir -p "$DIRETORIO_FONTES"


        if curl -fL \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip \
            -o "$ARQUIVO_MESLO" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Meslo Nerd Font baixada."

        else

            error "Não foi possível baixar a Meslo Nerd Font."

            return 1

        fi


        # ----------------------------------------------------
        # VERIFICAR UNZIP
        # ----------------------------------------------------

        if ! command -v unzip >/dev/null 2>&1; then

            info "Instalando unzip..."

            instalar_pacote unzip || return 1

        fi


        # ----------------------------------------------------
        # EXTRAIR
        # ----------------------------------------------------

        info "Extraindo Meslo Nerd Font..."


        if unzip \
            -o \
            "$ARQUIVO_MESLO" \
            -d "$DIRETORIO_FONTES" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Meslo Nerd Font extraída."

        else

            error "Não foi possível extrair a Meslo Nerd Font."

            return 1

        fi

    fi


    # --------------------------------------------------------
    # ATUALIZAR CACHE DAS FONTES
    # --------------------------------------------------------

    if command -v fc-cache >/dev/null 2>&1; then

        info "Atualizando cache das fontes..."


        if fc-cache -f \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Cache das fontes atualizado."

        else

            warning "Não foi possível atualizar completamente o cache das fontes."

        fi

    else

        warning "fc-cache não está disponível."

    fi


    # --------------------------------------------------------
    # VERIFICAÇÃO REAL DA MESLO
    # --------------------------------------------------------

    if command -v fc-list >/dev/null 2>&1; then

        if fc-list 2>/dev/null | grep -i "Meslo" >/dev/null; then

            success "Meslo Nerd Font detectada pelo sistema."

        else

            warning "A Meslo não foi detectada pelo fc-list."

        fi

    else

        warning "O comando fc-list não está disponível."

    fi


    # ========================================================
    # GHOSTTY
    # ========================================================

    title "INSTALANDO GHOSTTY"


    if ! command -v snap >/dev/null 2>&1; then

        error "Snap não está instalado."
        error "Execute a Etapa 2 antes da Etapa 4."

        return 1

    fi


    if snap list ghostty >/dev/null 2>&1; then

        success "Ghostty já está instalado."

    else

        info "Instalando Ghostty pelo Snap..."


        atualizar_sudo


        if sudo snap install ghostty --classic \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Ghostty instalado."

        else

            error "Falha ao instalar Ghostty."

            return 1

        fi

    fi


    # ========================================================
    # FISH
    # ========================================================

    title "CONFIGURANDO FISH"


    if command -v fish >/dev/null 2>&1; then

        success "Fish instalado."

    else

        instalar_pacote fish || return 1

    fi


    # --------------------------------------------------------
    # ALIAS CAT NO FISH
    # --------------------------------------------------------

    if command -v batcat >/dev/null 2>&1; then

        adicionar_fish 'alias cat="batcat"'

        success 'Alias "cat" -> "batcat" configurado no Fish.'

    else

        warning "batcat não está instalado."
        warning "Execute a Etapa 3 antes da Etapa 4."

    fi


    # ========================================================
    # FISHER
    # ========================================================

    title "INSTALANDO FISHER"


    if fish -c 'type -q fisher' >/dev/null 2>&1; then

        success "Fisher já está instalado."

    else

        info "Instalando Fisher..."


        if fish -c \
            'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source; fisher install jorgebucaran/fisher' \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Fisher instalado."

        else

            error "Falha ao instalar Fisher."

            return 1

        fi

    fi


    # ========================================================
    # TIDE
    # ========================================================

    title "INSTALANDO TIDE"


    if fish -c 'type -q tide' >/dev/null 2>&1; then

        success "Tide já está instalado."

    else

        info "Instalando Tide v6..."


        if fish -c \
            'fisher install IlanCosman/tide@v6' \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Tide instalado."

        else

            error "Falha ao instalar Tide."

            return 1

        fi

    fi


    # ========================================================
    # FISHER UPDATE
    # ========================================================

    info "Atualizando plugins do Fish..."


    fish -c 'fisher update' \
        2>&1 | tee -a "$LOG_FILE" || \
        warning "Não foi possível atualizar todos os plugins."


    # ========================================================
    # VERIFICAÇÕES
    # ========================================================

    verificar_comando fish


    if snap list ghostty >/dev/null 2>&1; then

        success "Ghostty verificado."

    else

        warning "Ghostty não pôde ser verificado."

    fi


    if fish -c 'type -q fisher' >/dev/null 2>&1; then

        success "Fisher verificado."

    else

        warning "Fisher não pôde ser verificado."

    fi


    if fish -c 'type -q tide' >/dev/null 2>&1; then

        success "Tide verificado."

    else

        warning "Tide não pôde ser verificado."

    fi


    if [ -f "$FISH_CONFIG" ] &&
       grep -Fqx 'alias cat="batcat"' "$FISH_CONFIG" 2>/dev/null; then

        success 'Alias "cat" -> "batcat" verificado no Fish.'

    else

        warning 'Alias "cat" -> "batcat" não foi encontrado no Fish.'

    fi


    touch "$MARCADOR_ETAPA4"


    success "Etapa 4 concluída."

}


# ============================================================
# RECONFIGURAR TIDE
# ============================================================

perguntar_reconfigurar_tide() {

    local resposta


    # --------------------------------------------------------
    # VERIFICAR FISH
    # --------------------------------------------------------

    if ! command -v fish >/dev/null 2>&1; then

        return 0

    fi


    # --------------------------------------------------------
    # VERIFICAR TIDE
    # --------------------------------------------------------

    if ! fish -c 'type -q tide' >/dev/null 2>&1; then

        return 0

    fi


    title "RECONFIGURAÇÃO DO TIDE"


    echo "O Tide já está instalado no Fish."
    echo
    echo "Você pode executar novamente a configuração interativa"
    echo "do Tide para alterar a aparência e o comportamento do prompt."
    echo


    while true; do

        read -r \
            -p "Deseja reconfigurar o Fish usando 'tide configure'? [s/N]: " \
            resposta \
            </dev/tty


        case "$resposta" in

            S|s|SIM|sim|Sim)

                echo

                info "Iniciando a configuração do Tide..."

                echo


                if fish -c 'tide configure' </dev/tty; then

                    success "Configuração do Tide concluída."

                else

                    warning "Configuração do Tide cancelada ou encerrada com erro."

                fi


                return 0

                ;;


            ""|N|n|NAO|nao|Nao|NÃO|não)

                info "Reconfiguração do Tide ignorada."

                return 0

                ;;


            *)

                warning "Digite S para sim ou N para não."

                ;;

        esac

    done

}


# ============================================================
# CONFIGURAR TERMINAL GRÁFICO
# ============================================================

configurar_terminal_grafico() {

    local terminal="$1"
    local comando=""
    local configurado=0


    case "$terminal" in

        terminator)

            comando="terminator"

            ;;


        ghostty)

            comando="ghostty"

            ;;


        *)

            error "Terminal gráfico inválido."

            return 1

            ;;

    esac


    title "CONFIGURANDO TERMINAL GRÁFICO"


    info "Terminal escolhido: $terminal"


    # ========================================================
    # GNOME / UBUNTU
    # ========================================================

    if command -v gsettings >/dev/null 2>&1; then

        if gsettings list-schemas 2>/dev/null \
            | grep -qx 'org.gnome.desktop.default-applications.terminal'; then


            if gsettings set \
                org.gnome.desktop.default-applications.terminal \
                exec \
                "$comando" \
                2>&1 | tee -a "$LOG_FILE"; then

                success "Terminal configurado pelo GNOME."

                configurado=1

            fi

        fi


        # ====================================================
        # CINNAMON / LINUX MINT
        # ====================================================

        if gsettings list-schemas 2>/dev/null \
            | grep -qx 'org.cinnamon.desktop.default-applications.terminal'; then


            if gsettings set \
                org.cinnamon.desktop.default-applications.terminal \
                exec \
                "$comando" \
                2>&1 | tee -a "$LOG_FILE"; then

                success "Terminal configurado pelo Cinnamon."

                configurado=1

            fi

        fi

    fi


    # ========================================================
    # XFCE
    # ========================================================

    if [ "$configurado" -eq 0 ] &&
       command -v xfconf-query >/dev/null 2>&1; then


        if xfconf-query \
            -c xfce4-session \
            -p /general/TerminalEmulator \
            -s "$comando" \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Terminal configurado pelo XFCE."

            configurado=1

        fi

    fi


    # ========================================================
    # X-TERMINAL-EMULATOR
    # ========================================================

    if command -v update-alternatives >/dev/null 2>&1; then

        caminho_terminal=""


        case "$terminal" in

            terminator)

                caminho_terminal="$(command -v terminator 2>/dev/null || true)"

                ;;


            ghostty)

                if command -v ghostty >/dev/null 2>&1; then

                    caminho_terminal="$(command -v ghostty)"

                elif [ -x /snap/bin/ghostty ]; then

                    caminho_terminal="/snap/bin/ghostty"

                fi

                ;;

        esac


        if [ -n "$caminho_terminal" ] &&
           [ -x "$caminho_terminal" ]; then


            atualizar_sudo


            sudo update-alternatives \
                --install \
                /usr/bin/x-terminal-emulator \
                x-terminal-emulator \
                "$caminho_terminal" \
                50 \
                2>&1 | tee -a "$LOG_FILE" || true


            sudo update-alternatives \
                --set \
                x-terminal-emulator \
                "$caminho_terminal" \
                2>&1 | tee -a "$LOG_FILE" || true


            success "x-terminal-emulator configurado."

        fi

    fi


    if [ "$configurado" -eq 1 ]; then

        success "Terminal gráfico padrão: $terminal"

    else

        warning "O ambiente gráfico não possui uma configuração automática reconhecida."
        warning "O terminal foi instalado, mas pode ser necessário defini-lo manualmente."

    fi

}


# ============================================================
# RESTAURAR TERMINAL GRÁFICO PADRÃO
# ============================================================

restaurar_terminal_grafico_padrao() {

    title "RESTAURANDO TERMINAL GRÁFICO PADRÃO"


    local restaurado=0


    # GNOME / UBUNTU
    if command -v gsettings >/dev/null 2>&1; then

        if gsettings list-schemas 2>/dev/null \
            | grep -qx 'org.gnome.desktop.default-applications.terminal'; then

            info "Restaurando configuração padrão do GNOME..."

            if gsettings reset \
                org.gnome.desktop.default-applications.terminal \
                exec \
                2>&1 | tee -a "$LOG_FILE"; then

                success "Configuração do terminal do GNOME restaurada."

                restaurado=1

            fi

        fi


        # CINNAMON / LINUX MINT
        if gsettings list-schemas 2>/dev/null \
            | grep -qx 'org.cinnamon.desktop.default-applications.terminal'; then

            info "Restaurando configuração padrão do Cinnamon..."

            if gsettings reset \
                org.cinnamon.desktop.default-applications.terminal \
                exec \
                2>&1 | tee -a "$LOG_FILE"; then

                success "Configuração do terminal do Cinnamon restaurada."

                restaurado=1

            fi

        fi

    fi


    # XFCE
    if command -v xfconf-query >/dev/null 2>&1; then

        info "Tentando restaurar configuração do XFCE..."

        if xfconf-query \
            -c xfce4-session \
            -p /general/TerminalEmulator \
            -r \
            2>&1 | tee -a "$LOG_FILE"; then

            success "Configuração do XFCE restaurada."

            restaurado=1

        fi

    fi


    # X-TERMINAL-EMULATOR
    if command -v update-alternatives >/dev/null 2>&1; then

        info "Restaurando x-terminal-emulator para modo automático..."

        atualizar_sudo

        if sudo update-alternatives \
            --auto x-terminal-emulator \
            2>&1 | tee -a "$LOG_FILE"; then

            success "x-terminal-emulator restaurado para modo automático."

            restaurado=1

        else

            warning "Não foi possível restaurar x-terminal-emulator."

        fi

    fi


    TERMINAL_GRAFICO="padrão do sistema"


    if [ "$restaurado" -eq 1 ]; then

        success "Terminal gráfico restaurado para o padrão do sistema."

    else

        warning "Não foi encontrada uma configuração automática para restaurar."
        warning "O sistema manterá sua configuração atual."

    fi

}


# ============================================================
# ESCOLHER TERMINAL GRÁFICO
# ============================================================

escolher_terminal_grafico() {

    local escolha

    title "ESCOLHA DO TERMINAL GRÁFICO PADRÃO"

    echo "Escolha qual aplicativo será utilizado como terminal gráfico:"
    echo
    echo "  1) Terminal padrão do sistema"
    echo "  2) Terminator"
    echo "  3) Ghostty"
    echo

    while true; do

        read -r \
            -p "Digite 1, 2 ou 3: " \
            escolha \
            </dev/tty

        case "$escolha" in

            1)

                restaurar_terminal_grafico_padrao

                return 0

                ;;

            2)

                if ! command -v terminator >/dev/null 2>&1; then

                    error "Terminator não está instalado."
                    warning "Execute a Etapa 2 antes de escolhê-lo."

                    continue

                fi

                TERMINAL_GRAFICO="terminator"

                configurar_terminal_grafico "terminator"

                return 0

                ;;

            3)

                if command -v ghostty >/dev/null 2>&1; then

                    TERMINAL_GRAFICO="ghostty"

                elif [ -x /snap/bin/ghostty ]; then

                    TERMINAL_GRAFICO="ghostty"

                else

                    error "Ghostty não está instalado."
                    warning "Execute a Etapa 4 antes de escolhê-lo."

                    continue

                fi

                configurar_terminal_grafico "ghostty"

                return 0

                ;;

            *)

                warning "Escolha inválida."

                ;;

        esac

    done

}


# ============================================================
# ALTERAR SHELL PADRÃO
# ============================================================

alterar_shell_padrao() {

    local shell_nome="$1"
    local shell_caminho=""


    case "$shell_nome" in

        zsh)

            shell_caminho="$(command -v zsh 2>/dev/null || true)"

            ;;

        fish)

            shell_caminho="$(command -v fish 2>/dev/null || true)"

            ;;

        *)

            error "Shell inválido."

            return 1

            ;;

    esac


    if [ -z "$shell_caminho" ]; then

        error "O shell $shell_nome não está instalado."

        return 1

    fi


    title "ALTERANDO SHELL PADRÃO"

    info "Shell escolhido: $shell_nome"
    info "Caminho: $shell_caminho"


    # /etc/shells
    if ! grep -Fxq "$shell_caminho" /etc/shells 2>/dev/null; then

        info "Adicionando shell ao /etc/shells..."

        atualizar_sudo

        if ! printf '%s\n' "$shell_caminho" \
            | sudo tee -a /etc/shells >/dev/null; then

            error "Não foi possível adicionar o shell."

            return 1

        fi

    fi


    # CHSH
    atualizar_sudo


    if sudo chsh \
        -s "$shell_caminho" \
        "$USUARIO_ATUAL" \
        2>&1 | tee -a "$LOG_FILE"; then

        success "Shell padrão alterado para $shell_nome."

    else

        error "Não foi possível alterar o shell padrão."

        return 1

    fi


    # VERIFICAR
    shell_atual="$(getent passwd "$USUARIO_ATUAL" | cut -d: -f7)"


    if [ "$shell_atual" = "$shell_caminho" ]; then

        success "Shell confirmado:"
        success "$shell_atual"

    else

        warning "Não foi possível confirmar o shell."
        warning "Shell encontrado: $shell_atual"

    fi

}


# ============================================================
# ESCOLHER SHELL
# ============================================================

escolher_shell() {

    local escolha


    title "ESCOLHA DO SHELL PADRÃO"


    echo "Escolha qual shell será utilizado por padrão:"
    echo
    echo "  1) Zsh"
    echo "  2) Fish"
    echo


    while true; do

        read -r \
            -p "Digite 1 ou 2: " \
            escolha \
            </dev/tty


        case "$escolha" in

            1)

                if ! command -v zsh >/dev/null 2>&1; then

                    error "Zsh não está instalado."
                    warning "Execute a Etapa 1 antes de escolhê-lo."

                    continue

                fi


                SHELL_PADRAO="zsh"


                break

                ;;


            2)

                if ! command -v fish >/dev/null 2>&1; then

                    error "Fish não está instalado."
                    warning "Execute a Etapa 4 antes de escolhê-lo."

                    continue

                fi


                SHELL_PADRAO="fish"


                break

                ;;


            *)

                warning "Escolha inválida."

                ;;

        esac

    done


    alterar_shell_padrao "$SHELL_PADRAO"

}


# ============================================================
# EXECUTAR ETAPAS
# ============================================================

executar_etapa1
executar_etapa2
executar_etapa3
executar_etapa4


# ============================================================
# PERGUNTAR SOBRE RECONFIGURAÇÃO DO TIDE
# ============================================================

perguntar_reconfigurar_tide


# ============================================================
# ESCOLHA DO TERMINAL GRÁFICO
# ============================================================

escolher_terminal_grafico


# ============================================================
# ESCOLHA DO SHELL
# ============================================================

escolher_shell


# ============================================================
# RESUMO FINAL
# ============================================================

title "PREPARAÇÃO CONCLUÍDA"


echo

success "Configuração final:"

echo

echo "  Distribuição:"
echo "    ${PRETTY_NAME:-$DISTRIBUICAO}"

echo

echo "  Terminal gráfico:"
echo "    ${TERMINAL_GRAFICO:-não definido}"

echo

echo "  Shell padrão:"
echo "    ${SHELL_PADRAO:-não definido}"

echo

echo "  Log:"
echo "    $LOG_FILE"

echo

echo "  Marcadores:"
echo "    $MARCADOR_ETAPA1"
echo "    $MARCADOR_ETAPA2"
echo "    $MARCADOR_ETAPA3"
echo "    $MARCADOR_ETAPA4"

echo

warning "A alteração do shell entra em vigor em uma nova sessão."

echo
echo "Feche o terminal atual e abra um novo terminal."
echo

echo "Configurações possíveis:"
echo
echo "  Ghostty + Fish"
echo "  Ghostty + Zsh"
echo "  Terminator + Fish"
echo "  Terminator + Zsh"
echo "  Terminal padrão do sistema + Fish"
echo "  Terminal padrão do sistema + Zsh"
echo

success "Script finalizado."


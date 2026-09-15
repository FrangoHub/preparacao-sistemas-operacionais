#!/bin/bash

# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS
# ============================================================
#
# Este script automatiza a preparação de um ambiente Linux
# para a disciplina de Sistemas Operacionais.
#
# Compatível com sistemas baseados em Debian/Ubuntu que
# utilizam APT/DPKG, como:
#
#   - Ubuntu
#   - Debian
#   - Linux Mint
#   - Pop!_OS
#
# O script possui três etapas:
#
#   Etapa 1 - Zsh e Oh My Zsh
#   Etapa 2 - Aplicativos e Snap
#   Etapa 3 - Ferramentas finais
#
# Características:
#
#   - Confirmação antes de cada etapa
#   - Registro da execução em arquivo de log
#   - Verificação de componentes já instalados
#   - Reinstalação automática de componentes ausentes
#   - Marcadores das etapas apenas para informação
#   - Compatibilidade com execução via curl | bash
#   - Tratamento especial do Snap no Linux Mint
#
# ============================================================


# ============================================================
# CONFIGURAÇÕES
# ============================================================

set -o pipefail


# ============================================================
# CORES
# ============================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'


# ============================================================
# FUNÇÕES DE MENSAGEM
# ============================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1"
}


# ============================================================
# FUNÇÃO PARA TÍTULOS
# ============================================================

title() {
    echo
    echo "============================================================"
    printf "%28s\n" "$1"
    echo "============================================================"
    echo
}


# ============================================================
# VERIFICAÇÃO DE ROOT
# ============================================================

if [ "$(id -u)" -eq 0 ]; then
    error "Este script não deve ser executado como root."
    error "Execute o script como usuário normal."
    exit 1
fi


# ============================================================
# IDENTIFICAÇÃO DO SISTEMA
# ============================================================

if [ ! -f /etc/os-release ]; then
    error "Não foi possível identificar o sistema operacional."
    exit 1
fi

source /etc/os-release


# ============================================================
# VERIFICAÇÃO DA DISTRIBUIÇÃO
# ============================================================

case "${ID:-}" in

    ubuntu|debian|linuxmint|pop)
        success "Sistema compatível: ${PRETTY_NAME:-$ID}"
        ;;

    *)
        warning "O sistema '${ID:-desconhecido}' não foi identificado como compatível."
        warning "O script foi desenvolvido para Ubuntu, Debian, Linux Mint e Pop!_OS."

        if [ ! -r /dev/tty ]; then
            error "Terminal interativo não disponível."
            exit 1
        fi

        read -r -p "Deseja continuar mesmo assim? [s/N]: " RESPOSTA </dev/tty

        if [[ ! "$RESPOSTA" =~ ^[Ss]$ ]]; then
            info "Execução cancelada."
            exit 0
        fi
        ;;

esac


# ============================================================
# VERIFICAÇÃO DAS FERRAMENTAS BÁSICAS
# ============================================================

if ! command -v apt-get >/dev/null 2>&1; then
    error "apt-get não foi encontrado."
    exit 1
fi

if ! command -v dpkg >/dev/null 2>&1; then
    error "dpkg não foi encontrado."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo não foi encontrado."
    exit 1
fi


# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"
HOME_USUARIO="$HOME"

info "Usuário: $USER"
info "Diretório pessoal: $HOME_USUARIO"
info "Arquitetura: $ARQUITETURA"
info "Distribuição: ${PRETTY_NAME:-$ID}"


# ============================================================
# ARQUIVOS DO SCRIPT
# ============================================================

LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"

ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"

ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# LOG
# ============================================================

touch "$LOG_FILE" 2>/dev/null

if [ $? -ne 0 ]; then
    error "Não foi possível criar o arquivo de log."
    exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1

info "Log: $LOG_FILE"


# ============================================================
# ARRAYS PARA O RESUMO FINAL
# ============================================================

PACOTES_INSTALADOS=()
PACOTES_JA_INSTALADOS=()
PACOTES_FALHARAM=()


# ============================================================
# PACOTES DE CADA ETAPA
# ============================================================

PACOTES_ETAPA1=(
    "zsh"
    "curl"
    "git"
    "fonts-powerline"
    "nano"
)

PACOTES_ETAPA2=(
    "emacs"
    "figlet"
    "lolcat"
    "ksudoku"
    "terminator"
    "snapd"
)

PACOTES_ETAPA3=(
    "neofetch"
    "jq"
    "bat"
)


# ============================================================
# VERIFICAÇÃO DO SUDO
# ============================================================

info "Verificando acesso ao sudo..."

if sudo -v; then
    success "Acesso ao sudo confirmado."
else
    error "Não foi possível utilizar sudo."
    exit 1
fi


# ============================================================
# FUNÇÃO: verificar se um pacote está instalado
# ============================================================

pacote_instalado() {
    local PACOTE="$1"

    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then
        return 0
    fi

    return 1
}


# ============================================================
# FUNÇÃO: instalar pacote
# ============================================================

instalar_pacote() {
    local PACOTE="$1"

    echo

    if pacote_instalado "$PACOTE"; then
        success "$PACOTE já está instalado."
        PACOTES_JA_INSTALADOS+=("$PACOTE")
        return 0
    fi

    info "$PACOTE não está instalado."
    info "Instalando $PACOTE..."

    if sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACOTE"; then

        if pacote_instalado "$PACOTE"; then
            success "$PACOTE instalado com sucesso."
            PACOTES_INSTALADOS+=("$PACOTE")
            return 0
        fi

        error "O APT terminou, mas $PACOTE não foi detectado como instalado."

    else

        error "Falha ao instalar o pacote $PACOTE."

    fi

    PACOTES_FALHARAM+=("$PACOTE")

    return 1
}


# ============================================================
# FUNÇÃO: verificar comando
# ============================================================

verificar_comando() {
    local COMANDO="$1"
    local CAMINHO

    CAMINHO="$(command -v "$COMANDO" 2>/dev/null || true)"

    if [ -n "$CAMINHO" ]; then
        success "$COMANDO encontrado: $CAMINHO"
    else
        warning "$COMANDO não foi encontrado no PATH."
    fi
}


# ============================================================
# FUNÇÃO: confirmar etapa
# ============================================================

confirmar_etapa() {
    local NUMERO="$1"
    local RESPOSTA=""

    echo

    if [ ! -r /dev/tty ]; then
        warning "Terminal interativo não está disponível."
        return 1
    fi

    read -r -p \
        "Deseja continuar com a Etapa $NUMERO? [S/n]: " \
        RESPOSTA </dev/tty

    if [ -z "$RESPOSTA" ]; then
        return 0
    fi

    if [[ "$RESPOSTA" =~ ^[Ss]$ ]]; then
        return 0
    fi

    return 1
}


# ============================================================
# ETAPA 1
# ============================================================

title "ETAPA 1 - ZSH E OH MY ZSH"

if [ -f "$ETAPA1" ]; then
    success "A Etapa 1 já foi executada anteriormente."
    info "Os componentes serão verificados novamente."
else
    info "A Etapa 1 ainda não foi executada."
fi


if confirmar_etapa 1; then

    # --------------------------------------------------------
    # Atualização dos repositórios
    # --------------------------------------------------------

    info "Atualizando os repositórios APT..."

    if sudo apt-get update; then
        success "Repositórios atualizados."
    else
        warning "Não foi possível atualizar todos os repositórios."
    fi


    # --------------------------------------------------------
    # Instalação dos pacotes
    # --------------------------------------------------------

    for PACOTE in "${PACOTES_ETAPA1[@]}"; do
        instalar_pacote "$PACOTE" || true
    done


    # --------------------------------------------------------
    # Oh My Zsh
    # --------------------------------------------------------

    if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

        success "Oh My Zsh já está instalado."

    else

        info "Oh My Zsh não foi encontrado."
        info "Instalando Oh My Zsh..."

        if command -v curl >/dev/null 2>&1; then

            if RUNZSH=no CHSH=no sh -c \
                "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then

                success "Oh My Zsh instalado com sucesso."

            else

                error "Falha ao instalar o Oh My Zsh."

            fi

        else

            error "curl não está disponível."

        fi
    fi


    # --------------------------------------------------------
    # .zshrc
    # --------------------------------------------------------

    if [ -f "$ZSHRC" ]; then

        if [ ! -f "$ZSHRC.etapa1.backup" ]; then

            if cp "$ZSHRC" "$ZSHRC.etapa1.backup"; then
                success "Backup do .zshrc criado."
            else
                warning "Não foi possível criar o backup do .zshrc."
            fi

        else

            success "Backup do .zshrc já existe."

        fi

    else

        touch "$ZSHRC"
        success ".zshrc criado."

    fi


    # --------------------------------------------------------
    # Tema Agnoster
    # --------------------------------------------------------

    if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then

        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

    else

        echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

    fi

    success "Tema Agnoster configurado."


    # --------------------------------------------------------
    # Zsh como shell padrão
    # --------------------------------------------------------

    ZSH_PATH="$(command -v zsh 2>/dev/null || true)"

    if [ -n "$ZSH_PATH" ]; then

        SHELL_ATUAL="$(getent passwd "$USER" | cut -d: -f7)"

        if [ "$SHELL_ATUAL" = "$ZSH_PATH" ]; then

            success "Zsh já é o shell padrão."

        else

            info "Configurando Zsh como shell padrão..."

            if chsh -s "$ZSH_PATH"; then
                success "Zsh configurado como shell padrão."
            else
                warning "Não foi possível alterar o shell padrão."
            fi

        fi

    else

        warning "Zsh não foi encontrado."

    fi


    # --------------------------------------------------------
    # Verificações
    # --------------------------------------------------------

    verificar_comando zsh
    verificar_comando curl
    verificar_comando git


    # --------------------------------------------------------
    # Marcador
    # --------------------------------------------------------

    touch "$ETAPA1"

    success "Etapa 1 concluída."

else

    warning "Etapa 1 ignorada pelo usuário."

fi


# ============================================================
# ETAPA 2
# ============================================================

title "ETAPA 2 - APLICATIVOS E SNAP"

if [ -f "$ETAPA2" ]; then
    success "A Etapa 2 já foi executada anteriormente."
    info "Os componentes serão verificados novamente."
else
    info "A Etapa 2 ainda não foi executada."
fi


if confirmar_etapa 2; then


    # --------------------------------------------------------
    # Linux Mint - desbloqueio do Snap
    # --------------------------------------------------------

    if [ "${ID:-}" = "linuxmint" ]; then

        NOSNAP_PREF="/etc/apt/preferences.d/nosnap.pref"

        if [ -f "$NOSNAP_PREF" ]; then

            info "Bloqueio do Snap detectado no Linux Mint."

            if [ ! -f "${NOSNAP_PREF}.backup" ]; then

                if sudo cp "$NOSNAP_PREF" "${NOSNAP_PREF}.backup"; then
                    success "Backup do bloqueio do Snap criado."
                else
                    warning "Não foi possível criar o backup."
                fi

            fi

            if sudo rm -f "$NOSNAP_PREF"; then
                success "Bloqueio do Snap removido."
            else
                warning "Não foi possível remover o bloqueio do Snap."
            fi

            info "Atualizando os repositórios após liberar o Snap..."

            if sudo apt-get update; then
                success "Repositórios atualizados."
            else
                warning "Não foi possível atualizar os repositórios."
            fi

        else

            success "Nenhum bloqueio nosnap.pref foi encontrado."

        fi

    fi


    # --------------------------------------------------------
    # Pacotes da Etapa 2
    # --------------------------------------------------------

    for PACOTE in "${PACOTES_ETAPA2[@]}"; do
        instalar_pacote "$PACOTE" || true
    done


    # --------------------------------------------------------
    # Fontes do Figlet
    # --------------------------------------------------------

    FIGLET_FONTS="$HOME_USUARIO/figlet-fonts"

    if [ -d "$FIGLET_FONTS/.git" ]; then

        success "figlet-fonts já está instalado."

    elif [ ! -e "$FIGLET_FONTS" ]; then

        info "Baixando fontes adicionais do Figlet..."

        if command -v git >/dev/null 2>&1; then

            if git clone \
                https://github.com/xero/figlet-fonts.git \
                "$FIGLET_FONTS"; then

                success "Fontes do Figlet instaladas."

            else

                warning "Não foi possível baixar as fontes do Figlet."

            fi

        else

            warning "Git não está disponível."

        fi

    else

        warning "$FIGLET_FONTS já existe, mas não é um repositório Git."

    fi


    # --------------------------------------------------------
    # Configuração do Figlet
    # --------------------------------------------------------

    FIGLET_CONFIG='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'

    if grep -Fq "$FIGLET_CONFIG" "$ZSHRC" 2>/dev/null; then

        success "Configuração do Figlet já está no .zshrc."

    else

        echo >> "$ZSHRC"
        echo "# Mensagem personalizada para o ambiente da disciplina" >> "$ZSHRC"
        echo "$FIGLET_CONFIG" >> "$ZSHRC"

        success "Configuração do Figlet adicionada ao .zshrc."

    fi


    # --------------------------------------------------------
    # Snapd
    # --------------------------------------------------------

    if pacote_instalado snapd; then

        success "snapd está instalado."

        if command -v systemctl >/dev/null 2>&1; then

            if sudo systemctl enable --now snapd.socket; then
                success "snapd.socket ativado."
            else
                warning "Não foi possível ativar snapd.socket."
            fi

        fi

        hash -r


        # ----------------------------------------------------
        # Aguarda o comando snap
        # ----------------------------------------------------

        for TENTATIVA in 1 2 3 4 5 6 7 8 9 10; do

            if command -v snap >/dev/null 2>&1; then
                break
            fi

            sleep 1
            hash -r

        done


        if command -v snap >/dev/null 2>&1; then
            success "Comando snap encontrado: $(command -v snap)"
        else
            warning "snapd está instalado, mas snap não foi encontrado no PATH."
        fi

    else

        warning "snapd não está instalado."
        warning "As instalações via Snap serão ignoradas."

    fi


    # --------------------------------------------------------
    # cool-retro-term
    # --------------------------------------------------------

    if command -v snap >/dev/null 2>&1; then

        if snap list cool-retro-term >/dev/null 2>&1; then

            success "cool-retro-term já está instalado."

        else

            info "Instalando cool-retro-term via Snap..."

            if sudo snap install cool-retro-term --classic; then
                success "cool-retro-term instalado."
            else
                warning "Não foi possível instalar cool-retro-term."
            fi

        fi

    fi


    # --------------------------------------------------------
    # mari0
    # --------------------------------------------------------

    if command -v snap >/dev/null 2>&1; then

        if snap list mari0 >/dev/null 2>&1; then

            success "mari0 já está instalado."

        else

            info "Instalando mari0 via Snap..."

            if sudo snap install mari0; then
                success "mari0 instalado."
            else
                warning "Não foi possível instalar mari0."
            fi

        fi

    fi


    # --------------------------------------------------------
    # Verificações
    # --------------------------------------------------------

    verificar_comando emacs
    verificar_comando figlet
    verificar_comando lolcat
    verificar_comando terminator

    if pacote_instalado snapd; then
        verificar_comando snap
    fi


    # --------------------------------------------------------
    # Marcador
    # --------------------------------------------------------

    touch "$ETAPA2"

    success "Etapa 2 concluída."

else

    warning "Etapa 2 ignorada pelo usuário."

fi


# ============================================================
# ETAPA 3
# ============================================================

title "ETAPA 3 - FERRAMENTAS FINAIS"

if [ -f "$ETAPA3" ]; then
    success "A Etapa 3 já foi executada anteriormente."
    info "Os componentes serão verificados novamente."
else
    info "A Etapa 3 ainda não foi executada."
fi


if confirmar_etapa 3; then


    # --------------------------------------------------------
    # Pacotes da Etapa 3
    # --------------------------------------------------------

    for PACOTE in "${PACOTES_ETAPA3[@]}"; do
        instalar_pacote "$PACOTE" || true
    done


    # --------------------------------------------------------
    # Verificação do bat
    #
    # Pacote: bat
    # Executável: batcat
    # --------------------------------------------------------

    if pacote_instalado bat; then

        success "Pacote bat está instalado."

        if command -v batcat >/dev/null 2>&1; then

            success "Comando batcat encontrado: $(command -v batcat)"

            if grep -Fq 'alias cat="batcat"' "$ZSHRC" 2>/dev/null; then

                success "Alias cat=\"batcat\" já está configurado."

            else

                echo >> "$ZSHRC"
                echo "# Alias para utilizar batcat através do comando cat" >> "$ZSHRC"
                echo 'alias cat="batcat"' >> "$ZSHRC"

                success "Alias cat=\"batcat\" adicionado ao .zshrc."

            fi

        else

            warning "O pacote bat está instalado, mas batcat não foi encontrado."

        fi

    else

        warning "O pacote bat não está instalado."

    fi


    # --------------------------------------------------------
    # Verificação do jq
    # --------------------------------------------------------

    if pacote_instalado jq; then

        success "Pacote jq está instalado."

        verificar_comando jq

    else

        warning "O pacote jq não está instalado."

    fi


    # --------------------------------------------------------
    # Verificação do neofetch
    # --------------------------------------------------------

    if pacote_instalado neofetch; then

        success "Pacote neofetch está instalado."

        verificar_comando neofetch

    else

        warning "O pacote neofetch não está instalado."

    fi


    # --------------------------------------------------------
    # Marcador
    # --------------------------------------------------------

    touch "$ETAPA3"

    success "Etapa 3 concluída."

else

    warning "Etapa 3 ignorada pelo usuário."

fi


# ============================================================
# RESUMO FINAL
# ============================================================

title "RESUMO DA EXECUÇÃO"


# ------------------------------------------------------------
# Pacotes instalados
# ------------------------------------------------------------

if [ "${#PACOTES_INSTALADOS[@]}" -gt 0 ]; then

    info "Pacotes instalados nesta execução:"

    for PACOTE in "${PACOTES_INSTALADOS[@]}"; do
        echo "  - $PACOTE"
    done

else

    info "Nenhum pacote novo foi instalado."

fi


# ------------------------------------------------------------
# Pacotes que já estavam instalados
# ------------------------------------------------------------

if [ "${#PACOTES_JA_INSTALADOS[@]}" -gt 0 ]; then

    echo
    info "Pacotes que já estavam instalados:"

    for PACOTE in "${PACOTES_JA_INSTALADOS[@]}"; do
        echo "  - $PACOTE"
    done

fi


# ------------------------------------------------------------
# Pacotes que falharam
# ------------------------------------------------------------

if [ "${#PACOTES_FALHARAM[@]}" -gt 0 ]; then

    echo
    error "Pacotes que apresentaram falha:"

    for PACOTE in "${PACOTES_FALHARAM[@]}"; do
        echo "  - $PACOTE"
    done

else

    echo
    success "Nenhum pacote apresentou falha."

fi


# ============================================================
# INFORMAÇÕES SOBRE O ZSH
# ============================================================

echo

info "O Zsh foi configurado como shell padrão."

echo

info "Para aplicar a alteração, feche este terminal e abra um novo."

echo

info "O novo terminal deverá iniciar automaticamente no Zsh."

echo

info "Para verificar o shell atual, execute:"

echo
echo '    echo "$SHELL"'
echo

info "O resultado esperado é:"
echo
echo "    /usr/bin/zsh"


# ============================================================
# LOG
# ============================================================

echo
info "Log completo da execução:"
echo
echo "    $LOG_FILE"


# ============================================================
# FINALIZAÇÃO
# ============================================================

echo
echo "============================================================"
echo "              PREPARAÇÃO CONCLUÍDA"
echo "============================================================"
echo

success "Script finalizado."

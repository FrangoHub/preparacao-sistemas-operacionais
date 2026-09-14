#!/bin/bash

# ============================================================
# PREPARAÇÃO DO SISTEMA OPERACIONAL
# Compatível com distribuições baseadas em Debian/Ubuntu
# ============================================================

set -e

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

title() {
  echo
  echo "============================================================"
  echo "                         $1"
  echo "============================================================"
  echo
}

# ============================================================
# TRATAMENTO DE ERROS
# ============================================================

trap 'error "Ocorreu um erro na linha $#!/bin/bash

# ============================================================
# PREPARAÇÃO DO SISTEMA OPERACIONAL
# Compatível com distribuições baseadas em Debian/Ubuntu
# ============================================================

set -e

# ============================================================
# CORES
# ============================================================

BLUE='\033[0
34m'
GREEN='\033[0
32m'
YELLOW='\033[1
33m'
RED='\033[0
31m'
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

title() {
    echo
    echo "============================================================"
    echo "                         $1"
    echo "============================================================"
    echo
}

# ============================================================
# TRATAMENTO DE ERROS
# ============================================================

trap 'error "Ocorreu um erro na linha $LINENO. A instalação foi interrompida."' ERR

# ============================================================
# VERIFICAR ROOT
# ============================================================

if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root."
    error "Execute como usuário normal."
    exit 1
fi

# ============================================================
# VERIFICAR DISTRIBUIÇÃO
# ============================================================

if [ ! -f /etc/os-release ]; then
    error "Não foi possível identificar a distribuição."
    exit 1
fi

source /etc/os-release

# ============================================================
# VERIFICAR APT/DPKG
# ============================================================

if ! command -v apt-get >/dev/null 2>&1; then
    error "Este sistema não possui apt-get."
    error "O script foi desenvolvido para distribuições baseadas em Debian/Ubuntu."
    exit 1
fi

if ! command -v dpkg >/dev/null 2>&1; then
    error "Este sistema não possui dpkg."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "O comando sudo não foi encontrado."
    exit 1
fi

# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"

echo
echo "Distribuição : ${PRETTY_NAME:-Desconhecida}"
echo "ID           : ${ID:-Desconhecido}"
echo "Arquitetura  : $ARQUITETURA"
echo

# ============================================================
# VERIFICAR SUDO
# ============================================================

info "Verificando permissões administrativas..."

sudo -v

success "Permissões administrativas confirmadas."

# ============================================================
# LOG
# ============================================================

LOG_FILE="$HOME/preparacao_sistemas_operacionais.log"

exec > >(tee -a "$LOG_FILE") 2>&1

info "Log da instalação:"
echo "$LOG_FILE"

# ============================================================
# MARCADORES
# ============================================================

ETAPA1="$HOME/.sistemas_operacionais_etapa1"
ETAPA2="$HOME/.sistemas_operacionais_etapa2"
ETAPA3="$HOME/.sistemas_operacionais_etapa3"

ZSHRC="$HOME/.zshrc"

# ============================================================
# PACOTES
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
# FUNÇÃO: VERIFICAR SE PACOTE ESTÁ DISPONÍVEL
# ============================================================

pacote_disponivel() {

    local PACOTE="$1"

    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0
    fi

    if apt-cache show "$PACOTE" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# ============================================================
# FUNÇÃO: VERIFICAR PACOTES DA ETAPA
# ============================================================

verificar_pacotes_etapa() {

    local PACOTES=("$@")
    local FALTANDO=()
    local PACOTE

    echo
    echo "Verificando disponibilidade dos pacotes..."
    echo

    for PACOTE in "${PACOTES[@]}"; do

        if pacote_disponivel "$PACOTE"; then

            success "$PACOTE"

        else

            error "$PACOTE — não encontrado nos repositórios."

            FALTANDO+=("$PACOTE")

        fi

    done

    echo

    if [ "${#FALTANDO[@]}" -gt 0 ]; then

        error "Existem pacotes necessários que não estão disponíveis."
        echo
        echo "Pacotes ausentes:"

        for PACOTE in "${FALTANDO[@]}"; do
            echo "  ✗ $PACOTE"
        done

        echo

        warning "A etapa não será executada para evitar uma instalação incompleta."

        return 1
    fi

    success "Todos os pacotes necessários estão disponíveis."

    return 0
}

# ============================================================
# FUNÇÃO: INSTALAR PACOTE
# ============================================================

instalar_pacote() {

    local PACOTE="$1"

    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        success "$PACOTE já está instalado."

    else

        info "Instalando $PACOTE..."

        sudo apt-get install -y "$PACOTE"

        success "$PACOTE instalado."

    fi
}

# ============================================================
# FUNÇÃO: VERIFICAR COMANDO
# ============================================================

verificar_comando() {

    local COMANDO="$1"

    if command -v "$COMANDO" >/dev/null 2>&1; then

        success "$COMANDO encontrado."

    else

        warning "$COMANDO não foi encontrado."

    fi
}

# ============================================================
# FUNÇÃO: CONFIRMAÇÃO
# ============================================================
#
# IMPORTANTE:
# O </dev/tty permite que o read funcione mesmo quando o script
# é executado assim:
#
# curl ... | bash
#
# ============================================================

confirmar_etapa() {

    local NUMERO="$1"

    local resposta

    echo

    read -r -p "Deseja continuar com a Etapa $NUMERO? [S/n]: " resposta </dev/tty

    # Enter = SIM
    if [[ -z "$resposta" || "$resposta" =~ ^[Ss]$ ]]; then

        return 0

    fi

    return 1
}

# ============================================================
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"

info "Atualizando os repositórios APT..."

sudo apt-get update

success "Repositórios atualizados."

# ============================================================
# ETAPA 1
# ============================================================

if [ -f "$ETAPA1" ]; then

    success "Etapa 1 já foi concluída anteriormente."

else

    title "ETAPA 1"

    echo "A Etapa 1 irá configurar:"
    echo
    echo "  • Zsh"
    echo "  • Oh My Zsh"
    echo "  • Fontes Powerline"
    echo "  • Tema Agnoster"
    echo "  • Zsh como shell padrão"
    echo

    info "Verificando pacotes da Etapa 1..."

    if ! verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"; then
        exit 1
    fi

    if ! confirmar_etapa 1; then

        info "Etapa 1 cancelada."

        exit 0

    fi

    # ========================================================
    # INSTALAÇÃO
    # ========================================================

    instalar_pacote "zsh"
    instalar_pacote "curl"
    instalar_pacote "git"
    instalar_pacote "fonts-powerline"
    instalar_pacote "nano"

    # ========================================================
    # VERIFICAR ZSH
    # ========================================================

    ZSH_PATH="$(command -v zsh)"

    if [ -z "$ZSH_PATH" ]; then

        error "Zsh não foi encontrado após a instalação."

        exit 1

    fi

    success "Zsh encontrado em: $ZSH_PATH"

    # ========================================================
    # BACKUP DO ZSHRC
    # ========================================================

    if [ -f "$ZSHRC" ] && [ ! -f "$ZSHRC.etapa1.backup" ]; then

        cp "$ZSHRC" "$ZSHRC.etapa1.backup"

        success "Backup do .zshrc criado."

    fi

    # ========================================================
    # OH MY ZSH
    # ========================================================

    if [ -d "$HOME/.oh-my-zsh" ]; then

        success "Oh My Zsh já está instalado."

    else

        info "Instalando Oh My Zsh..."

        RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

        success "Oh My Zsh instalado."

    fi

    # ========================================================
    # CONFIGURAR TEMA AGNOSTER
    # ========================================================

    if [ -f "$ZSHRC" ]; then

        if grep -q '^ZSH_THEME=' "$ZSHRC"; then

            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

        else

            echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

        fi

        success "Tema Agnoster configurado."

    fi

    # ========================================================
    # DEFINIR ZSH COMO SHELL PADRÃO
    # ========================================================

    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then

        success "Zsh já é o shell padrão."

    else

        info "Definindo Zsh como shell padrão..."

        chsh -s "$ZSH_PATH"

        success "Zsh definido como shell padrão."

    fi

    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA1"

    success "Etapa 1 concluída."

fi

# ============================================================
# ETAPA 2
# ============================================================

if [ -f "$ETAPA2" ]; then

    success "Etapa 2 já foi concluída anteriormente."

else

    if [ ! -f "$ETAPA1" ]; then

        warning "A Etapa 2 depende da conclusão da Etapa 1."

        exit 1

    fi

    title "ETAPA 2"

    echo "A Etapa 2 irá instalar:"
    echo
    echo "  • Emacs"
    echo "  • Figlet"
    echo "  • Figlet Fonts"
    echo "  • Lolcat"
    echo "  • KSudoku"
    echo "  • Terminator"
    echo "  • Snapd"
    echo "  • Cool Retro Term"
    echo "  • Mari0"
    echo

    info "Verificando pacotes da Etapa 2..."

    if ! verificar_pacotes_etapa "${PACOTES_ETAPA2[@]}"; then
        exit 1
    fi

    if ! confirmar_etapa 2; then

        info "Etapa 2 cancelada."

        exit 0

    fi

    # ========================================================
    # INSTALAÇÃO DOS PACOTES
    # ========================================================

    instalar_pacote "emacs"
    instalar_pacote "figlet"
    instalar_pacote "lolcat"
    instalar_pacote "ksudoku"
    instalar_pacote "terminator"
    instalar_pacote "snapd"

    # ========================================================
    # FIGLET FONTS
    # ========================================================

    FIGLET_FONTS="$HOME/figlet-fonts"

    if [ -d "$FIGLET_FONTS/.git" ]; then

        success "Figlet Fonts já está instalado."

    elif [ -d "$FIGLET_FONTS" ]; then

        warning "$FIGLET_FONTS já existe, mas não é um repositório Git."

    else

        info "Baixando Figlet Fonts..."

        git clone \
            https://github.com/xero/figlet-fonts.git \
            "$FIGLET_FONTS"

        success "Figlet Fonts instalado."

    fi

    # ========================================================
    # VERIFICAR FONTE 3D
    # ========================================================

    if [ -f "$FIGLET_FONTS/3d.flf" ]; then

        success "Fonte 3d.flf encontrada."

    else

        warning "A fonte 3d.flf não foi encontrada."

    fi

    # ========================================================
    # CONFIGURAR OH MY ZSH / FIGLET / LOLCAT
    # ========================================================

    FIGLET_COMMAND='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'

    if [ -f "$ZSHRC" ]; then

        if grep -Fqx "$FIGLET_COMMAND" "$ZSHRC"; then

            success "Mensagem OHMYZSH já está configurada."

        else

            echo >> "$ZSHRC"
            echo "$FIGLET_COMMAND" >> "$ZSHRC"

            success "Mensagem OHMYZSH adicionada ao .zshrc."

        fi

    fi

    # ========================================================
    # SNAPD
    # ========================================================

    info "Configurando Snapd..."

    sudo systemctl enable --now snapd.socket 2>/dev/null || true

    sleep 3

    if command -v snap >/dev/null 2>&1; then

        success "Snap encontrado."

    else

        warning "O comando snap ainda não foi encontrado."

    fi

    # ========================================================
    # COOL RETRO TERM
    # ========================================================

    if command -v snap >/dev/null 2>&1; then

        if snap list cool-retro-term >/dev/null 2>&1; then

            success "Cool Retro Term já está instalado."

        else

            info "Instalando Cool Retro Term..."

            sudo snap install cool-retro-term --classic

            success "Cool Retro Term instalado."

        fi

    else

        warning "Não foi possível instalar Cool Retro Term porque o Snap não está disponível."

    fi

    # ========================================================
    # MARI0
    # ========================================================

    if command -v snap >/dev/null 2>&1; then

        if snap list mari0 >/dev/null 2>&1; then

            success "Mari0 já está instalado."

        else

            info "Instalando Mari0..."

            sudo snap install mari0

            success "Mari0 instalado."

        fi

    else

        warning "Não foi possível instalar Mari0 porque o Snap não está disponível."

    fi

    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA2"

    success "Etapa 2 concluída."

fi

# ============================================================
# ETAPA 3
# ============================================================

if [ -f "$ETAPA3" ]; then

    success "Etapa 3 já foi concluída anteriormente."

else

    if [ ! -f "$ETAPA2" ]; then

        warning "A Etapa 3 depende da conclusão da Etapa 2."

        exit 1

    fi

    title "ETAPA 3"

    echo "A Etapa 3 irá instalar:"
    echo
    echo "  • Neofetch"
    echo "  • jq"
    echo "  • bat"
    echo "  • Alias cat = batcat"
    echo

    info "Verificando pacotes da Etapa 3..."

    if ! verificar_pacotes_etapa "${PACOTES_ETAPA3[@]}"; then
        exit 1
    fi

    if ! confirmar_etapa 3; then

        info "Etapa 3 cancelada."

        exit 0

    fi

    # ========================================================
    # INSTALAÇÃO
    # ========================================================

    instalar_pacote "neofetch"
    instalar_pacote "jq"
    instalar_pacote "bat"

    # ========================================================
    # VERIFICAR BATCAT
    # ========================================================

    if command -v batcat >/dev/null 2>&1; then

        success "batcat encontrado."

    else

        warning "batcat não foi encontrado."

    fi

    # ========================================================
    # BACKUP DO ZSHRC
    # ========================================================

    if [ -f "$ZSHRC" ] && [ ! -f "$ZSHRC.etapa3.backup" ]; then

        cp "$ZSHRC" "$ZSHRC.etapa3.backup"

        success "Backup do .zshrc da Etapa 3 criado."

    fi

    # ========================================================
    # ALIAS CAT
    # ========================================================

    if [ -f "$ZSHRC" ]; then

        if grep -Fqx 'alias cat="batcat"' "$ZSHRC"; then

            success 'Alias cat="batcat" já está configurado.'

        else

            echo 'alias cat="batcat"' >> "$ZSHRC"

            success 'Alias cat="batcat" adicionado ao .zshrc.'

        fi

    fi

    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA3"

    success "Etapa 3 concluída."

fi

# ============================================================
# FINALIZAÇÃO
# ============================================================

title "PREPARAÇÃO CONCLUÍDA"

success "Todas as etapas concluídas."

echo
echo "Marcadores:"
echo "  • Etapa 1: $ETAPA1"
echo "  • Etapa 2: $ETAPA2"
echo "  • Etapa 3: $ETAPA3"
echo
echo "Log:"
echo "  $LOG_FILE"
echo
echo "Backups:"
echo "  • $ZSHRC.etapa1.backup"
echo "  • $ZSHRC.etapa3.backup"
echo

info "Para aplicar as alterações do Zsh nesta sessão, execute:"
echo
echo "  source ~/.zshrc"
echo

warning "Caso o shell padrão tenha sido alterado para Zsh, pode ser necessário sair da sessão e entrar novamente."

echo
success "Fim do script."LINENO. A instalação foi interrompida."' ERR

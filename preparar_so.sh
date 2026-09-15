#!/bin/bash

set -e

# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS
# ============================================================
#
# Este script automatiza a preparação de um ambiente Linux
# para a disciplina de Sistemas Operacionais.
#
# O script foi desenvolvido para distribuições baseadas em
# Debian que utilizam APT/DPKG, como:
#
#   - Ubuntu
#   - Debian
#   - Linux Mint
#   - Pop!_OS
#
# O script possui 3 etapas:
#
#   ETAPA 1
#       Zsh, Oh My Zsh, Git, Curl, Nano e Powerline.
#
#   ETAPA 2
#       Emacs, Figlet, Lolcat, Ksudoku, Terminator e Snap.
#
#   ETAPA 3
#       Neofetch, JQ, Bat e configuração do alias cat.
#
# IMPORTANTE:
#   Os arquivos de marcador NÃO impedem a execução das etapas.
#   Eles servem apenas para informar que uma etapa já foi
#   executada anteriormente.
#
# Dessa forma, se um programa for removido posteriormente,
# o script poderá instalá-lo novamente.
#
# O script também foi preparado para ser executado através de:
#
#   curl -fsSL URL | bash
#
# ============================================================


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
    printf "%28s\n" "$1"
    echo "============================================================"
    echo
}


# ============================================================
# VERIFICAÇÃO DO USUÁRIO
# ============================================================
#
# O script não deve ser executado diretamente como root.
#
# Isso é importante porque várias configurações, como:
#
#   - .zshrc
#   - Oh My Zsh
#   - aliases
#
# pertencem ao usuário que está executando o script.
#
# Quando for necessário realizar uma operação administrativa,
# o script utilizará sudo.
# ============================================================

if [ "$(id -u)" -eq 0 ]; then
    error "Não execute este script como root."
    error "Execute como usuário normal."
    exit 1
fi


# ============================================================
# IDENTIFICAÇÃO DO SISTEMA OPERACIONAL
# ============================================================

if [ ! -r /etc/os-release ]; then
    error "Não foi possível identificar o sistema operacional."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release


# ============================================================
# VERIFICAÇÃO DA DISTRIBUIÇÃO
# ============================================================

case "${ID:-}" in
    ubuntu|debian|linuxmint|pop)
        success "Sistema operacional compatível detectado: ${PRETTY_NAME:-$ID}"
        ;;
    *)
        warning "Distribuição detectada: ${PRETTY_NAME:-desconhecida}"
        warning "Esta distribuição não está oficialmente listada como suportada."
        ;;
esac


# ============================================================
# VERIFICAÇÃO DO APT
# ============================================================

if ! command -v apt-get >/dev/null 2>&1; then
    error "O comando apt-get não foi encontrado."
    error "Este script necessita de uma distribuição baseada em APT."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO DPKG
# ============================================================

if ! command -v dpkg >/dev/null 2>&1; then
    error "O comando dpkg não foi encontrado."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO SUDO
# ============================================================

if ! command -v sudo >/dev/null 2>&1; then
    error "O comando sudo não foi encontrado."
    error "Instale o sudo antes de executar este script."
    exit 1
fi


# ============================================================
# INFORMAÇÕES DO USUÁRIO
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"
HOME_USUARIO="$HOME"

LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"

ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"

ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# PACOTES DAS ETAPAS
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
# INÍCIO DO LOG
# ============================================================

touch "$LOG_FILE"

exec > >(tee -a "$LOG_FILE") 2>&1


# ============================================================
# INFORMAÇÕES INICIAIS
# ============================================================

title "PREPARAÇÃO DO SISTEMA OPERACIONAL"

info "Usuário: $USER"
info "Home: $HOME_USUARIO"
info "Arquitetura: $ARQUITETURA"
info "Sistema: ${PRETTY_NAME:-desconhecido}"
info "Log: $LOG_FILE"

echo


# ============================================================
# AUTENTICAÇÃO DO SUDO
# ============================================================

info "Verificando acesso administrativo..."

sudo -v

success "Acesso administrativo confirmado."


# ============================================================
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"

info "Atualizando os repositórios do sistema..."

sudo apt-get update

success "Repositórios atualizados."


# ============================================================
# FUNÇÃO:
# pacote_instalado
# ============================================================
#
# Verifica se um pacote está realmente instalado.
#
# Utilizamos dpkg-query porque apenas verificar se o comando
# existe não é suficiente para determinar se um pacote Debian
# está instalado.
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
# FUNÇÃO:
# instalar_pacote
# ============================================================
#
# Esta é a parte mais importante do script.
#
# Cada pacote é analisado individualmente.
#
# Se já estiver instalado:
#
#       não faz nada.
#
# Se não estiver instalado:
#
#       executa apt-get install.
#
# Isso permite que o script seja executado várias vezes e
# também permite reparar programas que foram removidos depois
# da execução anterior.
# ============================================================

instalar_pacote() {
    local PACOTE="$1"

    echo

    if pacote_instalado "$PACOTE"; then
        success "$PACOTE já está instalado."
        return 0
    fi

    info "$PACOTE não está instalado."
    info "Instalando $PACOTE..."

    if sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACOTE"; then

        if pacote_instalado "$PACOTE"; then
            success "$PACOTE instalado com sucesso."
        else
            error "O APT terminou, mas $PACOTE não foi identificado como instalado."
            return 1
        fi

    else
        error "Falha ao instalar o pacote $PACOTE."
        return 1
    fi
}


# ============================================================
# FUNÇÃO:
# verificar_comando
# ============================================================
#
# Verifica se determinado programa está disponível no PATH.
#
# A função não encerra o script caso o comando não exista.
# Isso é importante porque o set -e poderia encerrar o script
# antes de podermos continuar o processo de instalação/reparo.
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

    return 0
}


# ============================================================
# FUNÇÃO:
# confirmar_etapa
# ============================================================
#
# Solicita confirmação antes de executar cada etapa.
#
# /dev/tty é utilizado para que o read continue funcionando
# mesmo quando o script é executado desta forma:
#
# curl ... | bash
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

title "ETAPA 1 - ZSH E FERRAMENTAS BÁSICAS"

if [ -f "$ETAPA1" ]; then
    success "A Etapa 1 já foi executada anteriormente."
    info "Os componentes serão verificados novamente."
else
    info "A Etapa 1 ainda não foi executada."
fi


if confirmar_etapa 1; then

    echo

    info "Verificando e instalando os pacotes da Etapa 1..."

    for PACOTE in "${PACOTES_ETAPA1[@]}"; do
        instalar_pacote "$PACOTE"
    done


    # ========================================================
    # OH MY ZSH
    # ========================================================

    echo

    if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

        success "Oh My Zsh já está instalado."

    else

        info "Oh My Zsh não está instalado."
        info "Instalando Oh My Zsh..."

        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

        success "Oh My Zsh instalado."

    fi


    # ========================================================
    # ARQUIVO .zshrc
    # ========================================================

    if [ ! -f "$ZSHRC" ]; then

        info "Arquivo .zshrc não encontrado."
        info "Criando $ZSHRC..."

        touch "$ZSHRC"

        success ".zshrc criado."

    else

        success ".zshrc encontrado."

    fi


    # ========================================================
    # BACKUP DO .zshrc
    # ========================================================

    if [ ! -f "${ZSHRC}.etapa1.backup" ]; then

        cp "$ZSHRC" "${ZSHRC}.etapa1.backup"

        success "Backup do .zshrc criado."

    else

        success "Backup do .zshrc já existe."

    fi


    # ========================================================
    # CONFIGURAÇÃO DO TEMA AGNOSTER
    # ========================================================

    if grep -q '^ZSH_THEME=' "$ZSHRC"; then

        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

    else

        echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

    fi

    success "Tema Agnoster configurado."


    # ========================================================
    # DEFINIR ZSH COMO SHELL PADRÃO
    # ========================================================

    if command -v zsh >/dev/null 2>&1; then

        ZSH_PATH="$(command -v zsh)"

        CURRENT_SHELL="$(getent passwd "$USER" \
            | awk -F: '{print $7}')"

        if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then

            info "Configurando Zsh como shell padrão..."

            chsh -s "$ZSH_PATH"

            success "Zsh definido como shell padrão."

        else

            success "Zsh já é o shell padrão."

        fi

    fi


    # ========================================================
    # VERIFICAÇÃO
    # ========================================================

    echo

    info "Verificando componentes da Etapa 1..."

    verificar_comando zsh
    verificar_comando curl
    verificar_comando git
    verificar_comando nano


    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA1"

    success "Etapa 1 concluída."

else

    warning "Etapa 1 cancelada pelo usuário."

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


    # ========================================================
    # CORREÇÃO DO SNAP NO LINUX MINT
    # ========================================================
    #
    # O Linux Mint possui um arquivo chamado nosnap.pref que
    # impede a instalação do pacote snapd.
    #
    # Removemos temporariamente esse bloqueio e fazemos backup.
    # ========================================================

    if [ "${ID:-}" = "linuxmint" ]; then

        NOSNAP_PREF="/etc/apt/preferences.d/nosnap.pref"

        if [ -f "$NOSNAP_PREF" ]; then

            info "Bloqueio do Snap detectado no Linux Mint."

            if [ ! -f "${NOSNAP_PREF}.backup" ]; then

                sudo cp \
                    "$NOSNAP_PREF" \
                    "${NOSNAP_PREF}.backup"

                success "Backup do bloqueio do Snap criado."

            else

                success "Backup do bloqueio do Snap já existe."

            fi

            sudo rm -f "$NOSNAP_PREF"

            success "Bloqueio do Snap removido."

            info "Atualizando os repositórios após liberar o Snap..."

            sudo apt-get update

            success "Repositórios atualizados."

        fi

    fi


    # ========================================================
    # INSTALAÇÃO DOS PACOTES
    # ========================================================
    #
    # IMPORTANTE:
    #
    # Não usamos mais verificar_pacotes_etapa().
    #
    # Cada pacote é instalado individualmente.
    #
    # Isso significa que se:
    #
    #   snapd
    #
    # for removido, ele será instalado novamente.
    # ========================================================

    echo

    info "Verificando e instalando os pacotes da Etapa 2..."

    for PACOTE in "${PACOTES_ETAPA2[@]}"; do
        instalar_pacote "$PACOTE"
    done


    # ========================================================
    # FIGLET FONTS
    # ========================================================

    FIGLET_FONTS="$HOME_USUARIO/figlet-fonts"

    if [ -d "$FIGLET_FONTS" ]; then

        success "Repositório figlet-fonts já existe."

    else

        info "Repositório figlet-fonts não encontrado."
        info "Clonando repositório..."

        git clone \
            https://github.com/xero/figlet-fonts.git \
            "$FIGLET_FONTS"

        success "Fontes do Figlet instaladas."

    fi


    # ========================================================
    # CONFIGURAÇÃO DO FIGLET NO .zshrc
    # ========================================================

    FIGLET_CONFIG='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'

    if grep -Fq 'figlet "OHMYZSH!"' "$ZSHRC"; then

        success "Configuração do Figlet já está no .zshrc."

    else

        echo >> "$ZSHRC"
        echo "# Configuração do Figlet" >> "$ZSHRC"
        echo "$FIGLET_CONFIG" >> "$ZSHRC"

        success "Configuração do Figlet adicionada ao .zshrc."

    fi


    # ========================================================
    # SNAPD
    # ========================================================

    echo

    info "Configurando o serviço do Snap..."

    if command -v systemctl >/dev/null 2>&1; then

        sudo systemctl enable --now snapd.socket 2>/dev/null || true

    fi

    hash -r

    sleep 3


    # ========================================================
    # VERIFICAR SNAP
    # ========================================================

    if command -v snap >/dev/null 2>&1; then

        success "Comando snap encontrado."

    else

        warning "Comando snap ainda não foi encontrado."
        warning "O serviço snapd pode precisar de alguns segundos para iniciar."

    fi


    # ========================================================
    # COOL RETRO TERM
    # ========================================================

    if command -v snap >/dev/null 2>&1; then

        if snap list cool-retro-term >/dev/null 2>&1; then

            success "cool-retro-term já está instalado."

        else

            info "Instalando cool-retro-term..."

            sudo snap install cool-retro-term --classic

            success "cool-retro-term instalado."

        fi

    fi


    # ========================================================
    # MARI0
    # ========================================================

    if command -v snap >/dev/null 2>&1; then

        if snap list mari0 >/dev/null 2>&1; then

            success "mari0 já está instalado."

        else

            info "Instalando mari0..."

            sudo snap install mari0

            success "mari0 instalado."

        fi

    fi


    # ========================================================
    # VERIFICAÇÃO
    # ========================================================

    echo

    info "Verificando componentes da Etapa 2..."

    verificar_comando emacs
    verificar_comando figlet
    verificar_comando lolcat
    verificar_comando terminator
    verificar_comando snap


    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA2"

    success "Etapa 2 concluída."

else

    warning "Etapa 2 cancelada pelo usuário."

fi


# ============================================================
# ETAPA 3
# ============================================================

title "ETAPA 3 - UTILITÁRIOS"

if [ -f "$ETAPA3" ]; then
    success "A Etapa 3 já foi executada anteriormente."
    info "Os componentes serão verificados novamente."
else
    info "A Etapa 3 ainda não foi executada."
fi


if confirmar_etapa 3; then


    # ========================================================
    # INSTALAÇÃO DOS PACOTES
    # ========================================================
    #
    # Cada pacote é analisado individualmente.
    #
    # Se jq ou bat forem removidos posteriormente, eles serão
    # instalados novamente na próxima execução do script.
    # ========================================================

    echo

    info "Verificando e instalando os pacotes da Etapa 3..."

    for PACOTE in "${PACOTES_ETAPA3[@]}"; do
        instalar_pacote "$PACOTE"
    done


    # ========================================================
    # ATUALIZAR CACHE DOS COMANDOS
    # ========================================================

    hash -r


    # ========================================================
    # BACKUP DO .zshrc
    # ========================================================

    if [ ! -f "${ZSHRC}.etapa3.backup" ]; then

        cp "$ZSHRC" "${ZSHRC}.etapa3.backup"

        success "Backup do .zshrc da Etapa 3 criado."

    else

        success "Backup do .zshrc da Etapa 3 já existe."

    fi


    # ========================================================
    # ALIAS CAT -> BATCAT
    # ========================================================
    #
    # Em Debian/Ubuntu, o executável do pacote bat normalmente
    # se chama batcat.
    #
    # Por isso o alias utiliza:
    #
    #     alias cat="batcat"
    # ========================================================

    if grep -qE '^alias cat=' "$ZSHRC"; then

        sed -i 's/^alias cat=.*/alias cat="batcat"/' "$ZSHRC"

        success "Alias cat atualizado."

    else

        echo >> "$ZSHRC"
        echo '# Alias para substituir cat pelo bat' >> "$ZSHRC"
        echo 'alias cat="batcat"' >> "$ZSHRC"

        success "Alias cat configurado."

    fi


    # ========================================================
    # VERIFICAÇÃO DOS PROGRAMAS
    # ========================================================

    echo

    info "Verificando componentes da Etapa 3..."

    verificar_comando jq
    verificar_comando batcat
    verificar_comando neofetch


    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA3"

    success "Etapa 3 concluída."

else

    warning "Etapa 3 cancelada pelo usuário."

fi


# ============================================================
# FINALIZAÇÃO
# ============================================================

title "PREPARAÇÃO CONCLUÍDA"

success "O script terminou a execução."

echo

info "Marcadores das etapas:"
echo
echo "    $ETAPA1"
echo "    $ETAPA2"
echo "    $ETAPA3"

echo

info "Arquivo de log:"
echo
echo "    $LOG_FILE"

echo

info "Arquivo de configuração do Zsh:"
echo
echo "    $ZSHRC"

echo

# ============================================================
# INFORMAÇÕES SOBRE O ZSH
# ============================================================
#
# Não usamos "source ~/.zshrc" aqui porque o script pode estar
# sendo executado dentro do Bash.
#
# O Oh My Zsh deve ser carregado pelo próprio Zsh.
# ============================================================

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

echo

success "Fim do script."

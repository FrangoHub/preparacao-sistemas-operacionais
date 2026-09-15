#!/bin/bash

# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS
# ============================================================
#
# Este script automatiza a preparação de um ambiente Linux
# para a disciplina de Sistemas Operacionais.
#
# Distribuições alvo:
#
#   - Ubuntu
#   - Debian
#   - Linux Mint
#   - Pop!_OS
#
# O script possui 3 etapas:
#
#   ETAPA 1
#       Zsh
#       Oh My Zsh
#       Curl
#       Git
#       Nano
#       Powerline
#
#   ETAPA 2
#       Emacs
#       Figlet
#       Lolcat
#       Ksudoku
#       Terminator
#       Snapd
#       Cool Retro Term
#       Mari0
#
#   ETAPA 3
#       Neofetch
#       JQ
#       Bat
#
# IMPORTANTE:
#
# Os arquivos de marcador NÃO impedem a execução das etapas.
#
# Eles servem somente para informar que a etapa já foi
# executada anteriormente.
#
# Dessa forma, se um programa for removido depois da primeira
# execução, o script poderá instalá-lo novamente.
#
# O script também pode ser executado através de:
#
#   curl -fsSL URL | bash
#
# ============================================================


# ============================================================
# CONFIGURAÇÕES DO BASH
# ============================================================
#
# Não usamos "set -e".
#
# O motivo é que uma falha individual de um pacote não deve
# interromper toda a execução do script.
#
# Por exemplo:
#
#   jq falhou
#
# Mesmo assim:
#
#   bat
#   neofetch
#
# devem continuar sendo processados.
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

if [ "$(id -u)" -eq 0 ]; then
    error "Não execute este script como root."
    error "Execute o script como usuário normal."
    exit 1
fi


# ============================================================
# IDENTIFICAÇÃO DO SISTEMA
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
        success "Sistema compatível: ${PRETTY_NAME:-$ID}"
        ;;

    *)
        warning "Sistema detectado: ${PRETTY_NAME:-desconhecido}"
        warning "A distribuição não está na lista oficial deste script."
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
# INFORMAÇÕES DO SISTEMA
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"
HOME_USUARIO="$HOME"

LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"

ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"

ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# LISTA DE PACOTES
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
# LISTAS DE RESULTADOS
# ============================================================

PACOTES_INSTALADOS=()
PACOTES_JA_INSTALADOS=()
PACOTES_FALHARAM=()


# ============================================================
# LOG
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
# SUDO
# ============================================================

info "Verificando acesso administrativo..."

if sudo -v; then
    success "Acesso administrativo confirmado."
else
    error "Não foi possível obter acesso administrativo."
    exit 1
fi


# ============================================================
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"

info "Atualizando os repositórios do sistema..."

if sudo apt-get update; then

    success "Repositórios atualizados."

else

    error "Falha ao atualizar os repositórios."

    warning "O script continuará, mas alguns pacotes podem não estar disponíveis."

fi


# ============================================================
# FUNÇÃO:
# pacote_instalado
# ============================================================
#
# Verifica se um pacote Debian está realmente instalado.
# ============================================================

pacote_instalado() {

    local PACOTE="$1"

    if dpkg-query \
        -W \
        -f='${Status}' \
        "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0

    fi

    return 1
}


# ============================================================
# FUNÇÃO:
# pacote_tem_candidato
# ============================================================
#
# Verifica se o APT possui uma versão candidata do pacote.
#
# Isso é especialmente importante no Linux Mint, onde o snapd
# pode aparecer como:
#
#   Candidate: (none)
#
# quando o bloqueio do Snap ainda está ativo.
# ============================================================

pacote_tem_candidato() {

    local PACOTE="$1"
    local CANDIDATO

    CANDIDATO="$(
        apt-cache policy "$PACOTE" 2>/dev/null \
            | awk -F': ' '/Candidate:/ {print $2; exit}'
    )"

    if [ -n "$CANDIDATO" ] && [ "$CANDIDATO" != "(none)" ]; then
        return 0
    fi

    return 1
}


# ============================================================
# FUNÇÃO:
# instalar_pacote
# ============================================================
#
# Instala um pacote individualmente.
#
# Se já estiver instalado:
#
#   não reinstala.
#
# Se estiver ausente:
#
#   tenta instalar.
#
# Se falhar:
#
#   registra o erro e continua.
#
# Isso torna o script capaz de reparar instalações parciais.
# ============================================================

instalar_pacote() {

    local PACOTE="$1"

    echo

    # --------------------------------------------------------
    # Já instalado
    # --------------------------------------------------------

    if pacote_instalado "$PACOTE"; then

        success "$PACOTE já está instalado."

        PACOTES_JA_INSTALADOS+=("$PACOTE")

        return 0

    fi


    info "$PACOTE não está instalado."


    # --------------------------------------------------------
    # Verificação do candidato
    # --------------------------------------------------------

    if ! pacote_tem_candidato "$PACOTE"; then

        error "O APT não possui candidato disponível para: $PACOTE"

        warning "Não foi possível instalar $PACOTE nesta execução."

        PACOTES_FALHARAM+=("$PACOTE")

        return 1

    fi


    # --------------------------------------------------------
    # Instalação
    # --------------------------------------------------------

    info "Instalando $PACOTE..."

    if sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACOTE"; then


        # ----------------------------------------------------
        # Confirmação
        # ----------------------------------------------------

        if pacote_instalado "$PACOTE"; then

            success "$PACOTE instalado com sucesso."

            PACOTES_INSTALADOS+=("$PACOTE")

            return 0

        else

            error "O APT terminou, mas $PACOTE não foi detectado como instalado."

            PACOTES_FALHARAM+=("$PACOTE")

            return 1

        fi

    else

        error "Falha ao instalar o pacote $PACOTE."

        PACOTES_FALHARAM+=("$PACOTE")

        return 1

    fi
}


# ============================================================
# FUNÇÃO:
# verificar_comando
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


    info "Verificando os pacotes da Etapa 1..."


    for PACOTE in "${PACOTES_ETAPA1[@]}"; do

        instalar_pacote "$PACOTE" || true

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

        if RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then

            success "Oh My Zsh instalado."

        else

            error "Falha ao instalar o Oh My Zsh."

        fi

    fi


    # ========================================================
    # .zshrc
    # ========================================================

    if [ ! -f "$ZSHRC" ]; then

        info "Criando $ZSHRC..."

        touch "$ZSHRC"

        success ".zshrc criado."

    else

        success ".zshrc encontrado."

    fi


    # ========================================================
    # BACKUP
    # ========================================================

    if [ ! -f "${ZSHRC}.etapa1.backup" ]; then

        cp "$ZSHRC" "${ZSHRC}.etapa1.backup"

        success "Backup do .zshrc criado."

    else

        success "Backup do .zshrc já existe."

    fi


    # ========================================================
    # AGNOSTER
    # ========================================================

    if grep -q '^ZSH_THEME=' "$ZSHRC"; then

        sed -i \
            's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
            "$ZSHRC"

    else

        echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

    fi

    success "Tema Agnoster configurado."


    # ========================================================
    # ZSH COMO SHELL PADRÃO
    # ========================================================

    if command -v zsh >/dev/null 2>&1; then

        ZSH_PATH="$(command -v zsh)"

        CURRENT_SHELL="$(
            getent passwd "$USER" \
                | awk -F: '{print $7}'
        )"


        if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then

            info "Configurando Zsh como shell padrão..."

            if chsh -s "$ZSH_PATH"; then

                success "Zsh definido como shell padrão."

            else

                error "Não foi possível alterar o shell padrão."

            fi

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


            if sudo apt-get update; then

                success "Repositórios atualizados."

            else

                warning "Não foi possível atualizar os repositórios."

            fi

        else

            success "Nenhum bloqueio nosnap.pref foi encontrado."

        fi

    fi


    # ========================================================
    # INSTALAÇÃO DOS PACOTES
    # ========================================================

    echo

    info "Verificando os pacotes da Etapa 2..."


    for PACOTE in "${PACOTES_ETAPA2[@]}"; do

        instalar_pacote "$PACOTE" || true

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


        if git clone \
            https://github.com/xero/figlet-fonts.git \
            "$FIGLET_FONTS"; then

            success "Fontes do Figlet instaladas."

        else

            error "Falha ao clonar as fontes do Figlet."

        fi

    fi


    # ========================================================
    # CONFIGURAÇÃO DO FIGLET
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

    info "Configurando o serviço snapd..."


    if pacote_instalado snapd; then


        if command -v systemctl >/dev/null 2>&1; then

            if sudo systemctl enable --now snapd.socket; then

                success "snapd.socket ativado."

            else

                warning "Não foi possível ativar snapd.socket."

            fi

        fi


        hash -r


        # ----------------------------------------------------
        # Aguarda o socket
        # ----------------------------------------------------

        for TENTATIVA in 1 2 3 4 5 6 7 8 9 10; do

            if command -v snap >/dev/null 2>&1; then
                break
            fi

            sleep 1
            hash -r

        done


    else

        warning "snapd não está instalado."
        warning "As instalações via Snap serão ignoradas."

    fi


    # ========================================================
    # VERIFICAÇÃO DO SNAP
    # ========================================================

    echo

    if command -v snap >/dev/null 2>&1; then

        success "Comando snap encontrado: $(command -v snap)"

    else

        error "Comando snap não foi encontrado."

    fi


    # ========================================================
    # COOL RETRO TERM
    # ========================================================

    if command -v snap >/dev/null 2>&1; then


        if snap list cool-retro-term >/dev/null 2>&1; then

            success "cool-retro-term já está instalado."

        else

            info "Instalando cool-retro-term..."


            if sudo snap install cool-retro-term --classic; then

                success "cool-retro-term instalado."

            else

                error "Falha ao instalar cool-retro-term."

            fi

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


            if sudo snap install mari0; then

                success "mari0 instalado."

            else

                error "Falha ao instalar mari0."

            fi

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
    # INSTALAÇÃO
    # ========================================================

    echo

    info "Verificando os pacotes da Etapa 3..."


    for PACOTE in "${PACOTES_ETAPA3[@]}"; do

        instalar_pacote "$PACOTE" || true

    done


    # ========================================================
    # ATUALIZA CACHE
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
    # ALIAS CAT
    # ========================================================

    if grep -qE '^alias cat=' "$ZSHRC"; then

        sed -i \
            's/^alias cat=.*/alias cat="batcat"/' \
            "$ZSHRC"

        success "Alias cat atualizado."

    else

        echo >> "$ZSHRC"
        echo "# Alias para substituir cat pelo bat" >> "$ZSHRC"
        echo 'alias cat="batcat"' >> "$ZSHRC"

        success "Alias cat configurado."

    fi


    # ========================================================
    # VERIFICAÇÃO DO JQ
    # ========================================================

    echo

    info "Verificando jq..."

    hash -r


    if command -v jq >/dev/null 2>&1; then

        success "jq encontrado: $(command -v jq)"

    else

        error "jq continua ausente após a instalação."

    fi


    # ========================================================
    # VERIFICAÇÃO DO BAT
    # ========================================================
    #
    # Dependendo da distribuição, o executável pode ser:
    #
    #   bat
    #
    # ou:
    #
    #   batcat
    #
    # O pacote Debian/Ubuntu normalmente utiliza batcat.
    # ========================================================

    echo

    info "Verificando bat..."


    if command -v batcat >/dev/null 2>&1; then

        success "bat encontrado como batcat: $(command -v batcat)"

    elif command -v bat >/dev/null 2>&1; then

        success "bat encontrado: $(command -v bat)"

    else

        error "bat continua ausente após a instalação."

    fi


    # ========================================================
    # VERIFICAÇÃO DO NEOFETCH
    # ========================================================

    echo

    info "Verificando neofetch..."


    if command -v neofetch >/dev/null 2>&1; then

        success "neofetch encontrado: $(command -v neofetch)"

    else

        warning "neofetch não foi encontrado."

    fi


    # ========================================================
    # MARCADOR
    # ========================================================

    touch "$ETAPA3"

    success "Etapa 3 concluída."

else

    warning "Etapa 3 cancelada pelo usuário."

fi


# ============================================================
# RESUMO FINAL
# ============================================================

title "RESUMO DA EXECUÇÃO"


echo

info "Pacotes instalados nesta execução:"

if [ "${#PACOTES_INSTALADOS[@]}" -eq 0 ]; then

    echo "    Nenhum."

else

    for PACOTE in "${PACOTES_INSTALADOS[@]}"; do
        echo "    - $PACOTE"
    done

fi


echo

info "Pacotes que já estavam instalados:"

if [ "${#PACOTES_JA_INSTALADOS[@]}" -eq 0 ]; then

    echo "    Nenhum."

else

    for PACOTE in "${PACOTES_JA_INSTALADOS[@]}"; do
        echo "    - $PACOTE"
    done

fi


echo

info "Pacotes que apresentaram erro:"

if [ "${#PACOTES_FALHARAM[@]}" -eq 0 ]; then

    success "Nenhum pacote apresentou erro."

else

    for PACOTE in "${PACOTES_FALHARAM[@]}"; do
        echo -e "    ${RED}- $PACOTE${NC}"
    done

fi


# ============================================================
# MARCADORES
# ============================================================

echo

info "Marcadores das etapas:"

echo
echo "    $ETAPA1"
echo "    $ETAPA2"
echo "    $ETAPA3"


# ============================================================
# LOG
# ============================================================

echo

info "Arquivo de log:"

echo
echo "    $LOG_FILE"


# ============================================================
# ZSH
# ============================================================

echo

info "Arquivo de configuração do Zsh:"

echo
echo "    $ZSHRC"


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
# FINAL
# ============================================================

echo

if [ "${#PACOTES_FALHARAM[@]}" -eq 0 ]; then

    success "Preparação concluída sem erros de instalação."

else

    warning "A preparação terminou, mas alguns pacotes apresentaram erro."

    warning "Consulte o resumo acima e o arquivo de log."

fi

echo
success "Fim do script."

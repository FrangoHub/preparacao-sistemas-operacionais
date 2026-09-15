#!/bin/bash

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
#   - outras distribuições derivadas do Debian
#
# O script é dividido em 3 etapas:
#
# ETAPA 1:
#   - zsh
#   - curl
#   - git
#   - fonts-powerline
#   - nano
#   - Oh My Zsh
#   - tema Agnoster
#
# ETAPA 2:
#   - emacs
#   - figlet
#   - lolcat
#   - ksudoku
#   - terminator
#   - snapd
#   - Figlet Fonts
#   - Cool Retro Term
#   - Mari0
#
# ETAPA 3:
#   - neofetch
#   - jq
#   - bat
#   - alias cat="batcat"
#
# Recursos:
#   - Confirmação antes de cada etapa
#   - Verificação dos pacotes
#   - Execução através de curl | bash
#   - Marcadores para registrar etapas concluídas
#   - Reinstalação automática de componentes removidos
#   - Arquivo de log
#   - Compatibilidade com diferentes usuários
#   - Não depende de um caminho específico de usuário
#
# ============================================================


# ============================================================
# CONFIGURAÇÃO DO BASH
# ============================================================

# Faz o script parar quando um comando importante retornar
# um código de erro.
set -e


# ============================================================
# CORES DO TERMINAL
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

# O script não deve ser executado diretamente como root.
if [ "$EUID" -eq 0 ]; then

    error "Não execute este script como root."
    error "Execute o script como usuário normal."

    exit 1

fi


# ============================================================
# VERIFICAÇÃO DO SISTEMA OPERACIONAL
# ============================================================

if [ ! -f /etc/os-release ]; then

    error "O arquivo /etc/os-release não foi encontrado."
    error "Não foi possível identificar o sistema operacional."

    exit 1

fi


# Carrega as informações do sistema operacional.
source /etc/os-release


# ============================================================
# VERIFICAÇÃO DO APT
# ============================================================

if ! command -v apt-get >/dev/null 2>&1; then

    error "O comando apt-get não foi encontrado."
    error "Este script foi desenvolvido para sistemas baseados em Debian."

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

    error "O comando sudo não está instalado."

    exit 1

fi


# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"

HOME_USUARIO="$HOME"

LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"


# ============================================================
# MARCADORES DAS ETAPAS
# ============================================================

ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"


# Caminho do arquivo de configuração do Zsh.
ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# INÍCIO DO LOG
# ============================================================

# Mostra a saída no terminal e também salva no arquivo de log.
exec > >(tee -a "$LOG_FILE") 2>&1


# ============================================================
# INFORMAÇÕES INICIAIS
# ============================================================

title "PREPARAÇÃO DO SISTEMA OPERACIONAL"

echo "Sistema operacional : ${PRETTY_NAME:-Desconhecido}"
echo "ID da distribuição  : ${ID:-Desconhecido}"
echo "Arquitetura         : $ARQUITETURA"
echo "Usuário             : $USER"
echo "HOME                : $HOME_USUARIO"
echo "Arquivo de log      : $LOG_FILE"

echo


# ============================================================
# VERIFICAÇÃO DAS PERMISSÕES
# ============================================================

info "Verificando permissões administrativas..."

sudo -v

success "Permissões administrativas confirmadas."


# ============================================================
# LISTA DE PACOTES DA ETAPA 1
# ============================================================

PACOTES_ETAPA1=(
    "zsh"
    "curl"
    "git"
    "fonts-powerline"
    "nano"
)


# ============================================================
# LISTA DE PACOTES DA ETAPA 2
# ============================================================

PACOTES_ETAPA2=(
    "emacs"
    "figlet"
    "lolcat"
    "ksudoku"
    "terminator"
    "snapd"
)


# ============================================================
# LISTA DE PACOTES DA ETAPA 3
# ============================================================

PACOTES_ETAPA3=(
    "neofetch"
    "jq"
    "bat"
)


# ============================================================
# FUNÇÃO: PACOTE INSTALADO
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
# FUNÇÃO: TODOS OS PACOTES INSTALADOS
# ============================================================

# Verifica se todos os pacotes de uma determinada etapa
# continuam instalados.
#
# Essa função é importante porque o marcador da etapa não
# significa que os programas nunca foram removidos.
#
# Exemplo:
#
#   A Etapa 3 foi concluída.
#   Depois o usuário removeu o jq.
#
# O marcador continua existindo, mas esta função detectará
# que o jq está faltando e permitirá executar novamente
# a etapa.

todos_pacotes_instalados() {

    local PACOTES=("$@")
    local PACOTE


    for PACOTE in "${PACOTES[@]}"; do

        if ! pacote_instalado "$PACOTE"; then

            return 1

        fi

    done


    return 0
}


# ============================================================
# FUNÇÃO: PACOTE DISPONÍVEL
# ============================================================

# Verifica se o pacote:
#
#   - já está instalado
# ou
#   - possui um candidato disponível no APT.
#
# Usamos "apt-cache policy" em vez de "apt-cache show"
# porque "apt-cache show" pode encontrar informações de um
# pacote mesmo quando não existe uma versão instalável.

pacote_disponivel() {

    local PACOTE="$1"
    local CANDIDATO


    # ------------------------------------------------
    # VERIFICA SE O PACOTE JÁ ESTÁ INSTALADO
    # ------------------------------------------------

    if pacote_instalado "$PACOTE"; then

        return 0

    fi


    # ------------------------------------------------
    # OBTÉM O CANDIDATO DO APT
    # ------------------------------------------------

    CANDIDATO="$(
        apt-cache policy "$PACOTE" 2>/dev/null \
            | awk -F': ' '/Candidate:/ {print $2; exit}'
    )"


    # ------------------------------------------------
    # VERIFICA SE EXISTE UM CANDIDATO VÁLIDO
    # ------------------------------------------------

    if [ -n "$CANDIDATO" ] && [ "$CANDIDATO" != "(none)" ]; then

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


    # ------------------------------------------------
    # VERIFICA SE JÁ ESTÁ INSTALADO
    # ------------------------------------------------

    if pacote_instalado "$PACOTE"; then

        success "$PACOTE já está instalado."

        return 0

    fi


    # ------------------------------------------------
    # INSTALAÇÃO
    # ------------------------------------------------

    info "Instalando $PACOTE..."


    # Cada pacote utiliza sua própria chamada ao sudo.
    # Isso permite que o script reinstale somente os pacotes
    # que estiverem faltando.

    if sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACOTE"; then


        # ------------------------------------------------
        # CONFIRMAÇÃO DA INSTALAÇÃO
        # ------------------------------------------------

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
# FUNÇÃO: VERIFICAR COMANDO
# ============================================================

# Verifica se determinado programa está disponível no PATH.
#
# Além de verificar a existência, mostra o caminho encontrado.

verificar_comando() {

    local COMANDO="$1"
    local CAMINHO


    CAMINHO="$(command -v "$COMANDO" 2>/dev/null || true)"


    if [ -n "$CAMINHO" ]; then

        success "$COMANDO encontrado: $CAMINHO"

        return 0

    else

        warning "$COMANDO não foi encontrado no PATH."

        return 1

    fi
}


# ============================================================
# FUNÇÃO: CONFIRMAR ETAPA
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
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"

info "Atualizando os repositórios APT..."

sudo apt-get update

success "Repositórios atualizados."


# ============================================================
# ETAPA 1
# ============================================================

title "ETAPA 1 — ZSH E FERRAMENTAS BÁSICAS"


# A etapa só será ignorada se:
#
#   1. O marcador existir
#   2. Todos os pacotes continuarem instalados

if [ -f "$ETAPA1" ] && todos_pacotes_instalados "${PACOTES_ETAPA1[@]}"; then

    success "Etapa 1 já foi concluída e todos os pacotes continuam instalados."
    info "Pulando Etapa 1."

else

    if [ -f "$ETAPA1" ]; then

        warning "A Etapa 1 já possuía um marcador, mas algum componente está faltando."

    fi


    if confirmar_etapa 1; then

        # ------------------------------------------------
        # VERIFICAÇÃO DOS PACOTES
        # ------------------------------------------------

        if verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Verificando e instalando pacotes da Etapa 1..."


            for PACOTE in "${PACOTES_ETAPA1[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # INSTALAÇÃO DO OH MY ZSH
            # ------------------------------------------------

            if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

                success "Oh My Zsh já está instalado."

            else

                info "Instalando Oh My Zsh..."


                RUNZSH=no CHSH=no sh -c \
                    "$(curl -fsSL \
                    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


                success "Oh My Zsh instalado."

            fi


            # ------------------------------------------------
            # GARANTIR QUE O .zshrc EXISTE
            # ------------------------------------------------

            touch "$ZSHRC"


            # ------------------------------------------------
            # BACKUP DO .zshrc
            # ------------------------------------------------

            if [ ! -f "$HOME_USUARIO/.zshrc.etapa1.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa1.backup"

                success "Backup do .zshrc criado."

            else

                success "Backup do .zshrc já existe."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO TEMA AGNOSTER
            # ------------------------------------------------

            if grep -q '^ZSH_THEME=' "$ZSHRC"; then

                sed -i \
                    's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
                    "$ZSHRC"

            else

                echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

            fi


            success "Tema Agnoster configurado."


            # ------------------------------------------------
            # DEFINIR ZSH COMO SHELL PADRÃO
            # ------------------------------------------------

            ZSH_PATH="$(command -v zsh)"


            if [ -z "$ZSH_PATH" ]; then

                error "O executável do Zsh não foi encontrado."

                exit 1

            fi


            CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"


            if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then

                success "Zsh já está configurado como shell padrão."

            elif sudo chsh -s "$ZSH_PATH" "$USER"; then

                success "Zsh definido como shell padrão."

            else

                warning "Não foi possível alterar o shell padrão automaticamente."
                warning "O Zsh foi instalado, mas será necessário configurá-lo manualmente."

            fi


            # ------------------------------------------------
            # VERIFICAÇÃO DOS PROGRAMAS
            # ------------------------------------------------

            hash -r

            verificar_comando "zsh"
            verificar_comando "curl"
            verificar_comando "git"
            verificar_comando "nano"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 1
            # ------------------------------------------------

            touch "$ETAPA1"

            success "Etapa 1 concluída."

        fi

    else

        warning "Etapa 1 cancelada pelo usuário."

    fi

fi


# ============================================================
# ETAPA 2
# ============================================================

title "ETAPA 2 — PROGRAMAS E PERSONALIZAÇÃO"


# A etapa só será ignorada se:
#
#   1. O marcador existir
#   2. Todos os pacotes continuarem instalados

if [ -f "$ETAPA2" ] && todos_pacotes_instalados "${PACOTES_ETAPA2[@]}"; then

    success "Etapa 2 já foi concluída e todos os pacotes continuam instalados."
    info "Pulando Etapa 2."

else

    if [ -f "$ETAPA2" ]; then

        warning "A Etapa 2 já possuía um marcador, mas algum componente está faltando."

    fi


    if confirmar_etapa 2; then


        # ------------------------------------------------
        # PREPARAÇÃO DO SNAPD NO LINUX MINT
        # ------------------------------------------------

        # O Linux Mint bloqueia o Snap através do arquivo:
        #
        # /etc/apt/preferences.d/nosnap.pref
        #
        # Essa alteração é feita somente no Linux Mint.

        if [ "${ID:-}" = "linuxmint" ]; then

            NOSNAP_PREF="/etc/apt/preferences.d/nosnap.pref"


            if [ -f "$NOSNAP_PREF" ]; then

                info "Bloqueio do Snap detectado no Linux Mint."


                # ------------------------------------------------
                # BACKUP DO BLOQUEIO
                # ------------------------------------------------

                if [ ! -f "${NOSNAP_PREF}.backup" ]; then

                    sudo cp "$NOSNAP_PREF" "${NOSNAP_PREF}.backup"

                    success "Backup do bloqueio do Snap criado."

                else

                    success "Backup do bloqueio do Snap já existe."

                fi


                # ------------------------------------------------
                # REMOÇÃO DO BLOQUEIO
                # ------------------------------------------------

                sudo rm "$NOSNAP_PREF"

                success "Bloqueio do Snap removido."


                # ------------------------------------------------
                # ATUALIZAÇÃO DOS REPOSITÓRIOS
                # ------------------------------------------------

                info "Atualizando os repositórios após liberar o Snap..."

                sudo apt-get update

                success "Repositórios atualizados."

            fi

        fi


        # ------------------------------------------------
        # VERIFICAÇÃO DOS PACOTES
        # ------------------------------------------------

        if verificar_pacotes_etapa "${PACOTES_ETAPA2[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Verificando e instalando pacotes da Etapa 2..."


            for PACOTE in "${PACOTES_ETAPA2[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # FIGLET FONTS
            # ------------------------------------------------

            FIGLET_FONTS="$HOME_USUARIO/figlet-fonts"


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


            # ------------------------------------------------
            # CONFIGURAÇÃO DO FIGLET NO ZSH
            # ------------------------------------------------

            FIGLET_COMMAND='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'


            if grep -Fqx "$FIGLET_COMMAND" "$ZSHRC"; then

                success "Mensagem OHMYZSH já está configurada."

            else

                printf '\n%s\n' "$FIGLET_COMMAND" >> "$ZSHRC"

                success "Mensagem OHMYZSH adicionada ao .zshrc."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO SNAPD
            # ------------------------------------------------

            # Habilita o socket do Snap e inicia o serviço.

            sudo systemctl enable --now snapd.socket 2>/dev/null || true


            # Aguarda o Snap terminar sua inicialização.

            sleep 3


            # ------------------------------------------------
            # COOL RETRO TERM
            # ------------------------------------------------

            if command -v snap >/dev/null 2>&1; then


                if snap list cool-retro-term >/dev/null 2>&1; then

                    success "Cool Retro Term já está instalado."

                else

                    info "Instalando Cool Retro Term..."

                    sudo snap install cool-retro-term --classic

                    success "Cool Retro Term instalado."

                fi


            else

                warning "Cool Retro Term não será instalado porque o Snap não está disponível."

            fi


            # ------------------------------------------------
            # MARI0
            # ------------------------------------------------

            if command -v snap >/dev/null 2>&1; then


                if snap list mari0 >/dev/null 2>&1; then

                    success "Mari0 já está instalado."

                else

                    info "Instalando Mari0..."

                    sudo snap install mari0

                    success "Mari0 instalado."

                fi


            else

                warning "Mari0 não será instalado porque o Snap não está disponível."

            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL
            # ------------------------------------------------

            hash -r

            verificar_comando "emacs"
            verificar_comando "figlet"
            verificar_comando "lolcat"
            verificar_comando "terminator"
            verificar_comando "snap"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 2
            # ------------------------------------------------

            touch "$ETAPA2"

            success "Etapa 2 concluída."

        fi

    else

        warning "Etapa 2 cancelada pelo usuário."

    fi

fi


# ============================================================
# ETAPA 3 — UTILITÁRIOS
# ============================================================

title "ETAPA 3 — UTILITÁRIOS"


# A etapa só será ignorada se:
#
#   1. O marcador existir
#   2. Todos os pacotes continuarem instalados

if [ -f "$ETAPA3" ] && todos_pacotes_instalados "${PACOTES_ETAPA3[@]}"; then

    success "Etapa 3 já foi concluída e todos os pacotes continuam instalados."
    info "Pulando Etapa 3."

else

    if [ -f "$ETAPA3" ]; then

        warning "A Etapa 3 já possuía um marcador, mas algum componente está faltando."

    fi


    if confirmar_etapa 3; then


        # ------------------------------------------------
        # VERIFICAÇÃO DOS PACOTES
        # ------------------------------------------------

        if verificar_pacotes_etapa "${PACOTES_ETAPA3[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Verificando e instalando pacotes da Etapa 3..."


            for PACOTE in "${PACOTES_ETAPA3[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # ATUALIZAÇÃO DO CACHE DE COMANDOS
            # ------------------------------------------------

            # Como os programas podem ter sido instalados
            # durante a execução do script, limpamos o cache
            # de comandos do Bash antes da verificação.

            hash -r


            # ------------------------------------------------
            # BACKUP DO .zshrc
            # ------------------------------------------------

            if [ ! -f "$HOME_USUARIO/.zshrc.etapa3.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa3.backup"

                success "Backup do .zshrc da Etapa 3 criado."

            else

                success "Backup do .zshrc da Etapa 3 já existe."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO BAT
            # ------------------------------------------------

            # O pacote Debian/Ubuntu/Mint se chama "bat",
            # mas o executável normalmente se chama "batcat".

            if grep -Fqx 'alias cat="batcat"' "$ZSHRC"; then

                success 'Alias cat="batcat" já está configurado.'

            else

                echo 'alias cat="batcat"' >> "$ZSHRC"

                success 'Alias cat="batcat" adicionado ao .zshrc.'

            fi


            # ------------------------------------------------
            # VERIFICAÇÃO DOS COMANDOS
            # ------------------------------------------------

            # O pacote "jq" instala o executável "jq".
            verificar_comando "jq"


            # O pacote "bat" instala o executável "batcat"
            # nas distribuições Debian e derivadas.
            verificar_comando "batcat"


            # O pacote "neofetch" instala o executável
            # "neofetch".
            verificar_comando "neofetch"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 3
            # ------------------------------------------------

            touch "$ETAPA3"

            success "Etapa 3 concluída."

        fi

    else

        warning "Etapa 3 cancelada pelo usuário."

    fi

fi


# ============================================================
# FINALIZAÇÃO
# ============================================================

title "INSTALAÇÃO FINALIZADA"

success "Todas as etapas foram processadas."


# ============================================================
# ORIENTAÇÃO FINAL SOBRE O ZSH
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


# ============================================================
# INFORMAÇÕES DO LOG
# ============================================================

info "O log desta execução está em:"

echo
echo "    $LOG_FILE"

echo


# ============================================================
# MARCADORES DAS ETAPAS
# ============================================================

info "Marcadores das etapas:"

echo
echo "    $ETAPA1"
echo "    $ETAPA2"
echo "    $ETAPA3"

echo


# ============================================================
# FINAL
# ============================================================

success "Script concluído com sucesso."

exit 0

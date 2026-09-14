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
#   - Marcadores para evitar repetir etapas concluídas
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
#
# Exemplo:
#
#     sudo apt-get install pacote
#
# Se a instalação falhar, o script será interrompido em vez
# de continuar fingindo que tudo funcionou.
set -e


# ============================================================
# CORES DO TERMINAL
# ============================================================

# Azul para mensagens informativas.
BLUE='\033[0;34m'

# Verde para operações concluídas com sucesso.
GREEN='\033[0;32m'

# Amarelo para avisos.
YELLOW='\033[1;33m'

# Vermelho para erros.
RED='\033[0;31m'

# Restaura a cor padrão do terminal.
NC='\033[0m'


# ============================================================
# FUNÇÕES DE MENSAGEM
# ============================================================

# Exibe uma mensagem informativa.
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}


# Exibe uma mensagem de sucesso.
success() {
    echo -e "${GREEN}[OK]${NC} $1"
}


# Exibe uma mensagem de aviso.
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}


# Exibe uma mensagem de erro.
error() {
    echo -e "${RED}[ERRO]${NC} $1"
}


# Exibe um título para separar visualmente cada seção.
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
#
# O motivo é que algumas configurações, como:
#
#   ~/.zshrc
#   ~/.oh-my-zsh
#
# devem pertencer ao usuário que está preparando o sistema,
# e não ao usuário root.
#
# Portanto:
#
#     bash preparar_so.sh
#
# é correto.
#
# Enquanto:
#
#     sudo bash preparar_so.sh
#
# não é recomendado.
if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root."
    error "Execute o script como usuário normal."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO SISTEMA OPERACIONAL
# ============================================================

# O arquivo /etc/os-release contém informações sobre
# a distribuição Linux instalada.
#
# Exemplos:
#
# Ubuntu:
#   ID=ubuntu
#
# Debian:
#   ID=debian
#
# Linux Mint:
#   ID=linuxmint
#
# Pop!_OS:
#   ID=pop
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

# O script utiliza o APT para instalar os programas.
#
# Se apt-get não existir, provavelmente o sistema não é
# compatível com este script.
if ! command -v apt-get >/dev/null 2>&1; then
    error "O comando apt-get não foi encontrado."
    error "Este script foi desenvolvido para sistemas baseados em Debian."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO DPKG
# ============================================================

# O DPKG é o sistema de gerenciamento de pacotes utilizado
# pelo Debian e seus derivados.
if ! command -v dpkg >/dev/null 2>&1; then
    error "O comando dpkg não foi encontrado."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO SUDO
# ============================================================

# O sudo será utilizado somente nos comandos que necessitam
# de privilégios administrativos.
if ! command -v sudo >/dev/null 2>&1; then
    error "O comando sudo não está instalado."
    exit 1
fi


# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

# Descobre a arquitetura do sistema.
#
# Normalmente:
#
#   amd64
#   arm64
#
ARQUITETURA="$(dpkg --print-architecture)"


# Guarda o diretório HOME do usuário.
#
# Não colocamos um caminho fixo como /home/frangogamer,
# pois o script deve funcionar para qualquer usuário.
HOME_USUARIO="$HOME"


# Caminho do arquivo que armazenará o log.
LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"


# ============================================================
# MARCADORES DAS ETAPAS
# ============================================================

# Cada etapa possui um arquivo marcador.
#
# Quando uma etapa termina corretamente, o arquivo é criado.
#
# Em uma execução futura, o script verifica se o arquivo
# existe e pula a etapa.
ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"


# Caminho do arquivo de configuração do Zsh.
ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# INÍCIO DO LOG
# ============================================================

# O comando tee permite mostrar a saída no terminal e,
# simultaneamente, salvar tudo no arquivo de log.
#
# O "-a" faz com que novas execuções sejam adicionadas
# ao final do arquivo, em vez de apagar o conteúdo anterior.
#
# "2>&1" faz com que mensagens de erro também sejam
# direcionadas para o log.
exec > >(tee -a "$LOG_FILE") 2>&1


# ============================================================
# INFORMAÇÕES INICIAIS
# ============================================================

title "PREPARAÇÃO DO SISTEMA OPERACIONAL"


# Mostra o nome completo da distribuição.
echo "Sistema operacional : ${PRETTY_NAME:-Desconhecido}"


# Mostra o identificador da distribuição.
echo "ID da distribuição  : ${ID:-Desconhecido}"


# Mostra a arquitetura.
echo "Arquitetura         : $ARQUITETURA"


# Mostra o usuário que executou o script.
echo "Usuário             : $USER"


# Mostra o diretório HOME.
echo "HOME                : $HOME_USUARIO"


# Mostra o caminho do arquivo de log.
echo "Arquivo de log      : $LOG_FILE"

echo


# ============================================================
# VERIFICAÇÃO DAS PERMISSÕES
# ============================================================

info "Verificando permissões administrativas..."


# Solicita a senha do sudo antecipadamente.
#
# Dessa forma, o usuário não será surpreendido por uma
# solicitação de senha no meio da instalação.
sudo -v


success "Permissões administrativas confirmadas."


# ============================================================
# LISTA DE PACOTES DA ETAPA 1
# ============================================================

# Array contendo todos os pacotes necessários para a
# primeira etapa.
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

# Array contendo os pacotes da segunda etapa.
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

# Array contendo os pacotes da terceira etapa.
PACOTES_ETAPA3=(
    "neofetch"
    "jq"
    "bat"
)


# ============================================================
# FUNÇÃO: PACOTE INSTALADO
# ============================================================

# Verifica se determinado pacote já está instalado.
#
# Retorno:
#
#   0 = instalado
#   1 = não instalado
pacote_instalado() {

    # Primeiro argumento recebido pela função.
    local PACOTE="$1"


    # dpkg-query consulta o banco de dados de pacotes.
    #
    # ${Status} retorna o estado do pacote.
    #
    # grep verifica se o estado é:
    #
    #     install ok installed
    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0
    fi


    return 1
}


# ============================================================
# FUNÇÃO: PACOTE DISPONÍVEL
# ============================================================

# Verifica se um pacote:
#
#   - já está instalado
# ou
#   - está disponível nos repositórios configurados.
pacote_disponivel() {

    local PACOTE="$1"
    local CANDIDATO


    # ------------------------------------------------
    # VERIFICA SE O PACOTE JÁ ESTÁ INSTALADO
    # ------------------------------------------------

    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0

    fi


    # ------------------------------------------------
    # VERIFICA O CANDIDATO DISPONÍVEL NO APT
    # ------------------------------------------------

    # "apt-cache show" não é suficiente para essa
    # verificação, pois pode encontrar informações
    # sobre um pacote mesmo quando o APT não possui
    # uma versão instalável.
    #
    # Por isso verificamos especificamente o campo
    # "Candidate:" do apt-cache policy.

    CANDIDATO="$(
        apt-cache policy "$PACOTE" 2>/dev/null \
            | awk -F': ' '/Candidate:/ {print $2; exit}'
    )"


    # Se existe um candidato válido, o pacote pode
    # ser instalado pelo APT.
    if [ -n "$CANDIDATO" ] && [ "$CANDIDATO" != "(none)" ]; then

        return 0

    fi


    return 1
}


# ============================================================
# FUNÇÃO: VERIFICAR PACOTES DA ETAPA
# ============================================================

# Recebe uma lista de pacotes e verifica se todos estão
# disponíveis.
#
# Exemplo:
#
#     verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"
verificar_pacotes_etapa() {

    # Recebe todos os argumentos da função como um array.
    local PACOTES=("$@")


    # Array que armazenará os pacotes que não foram encontrados.
    local FALTANDO=()


    # Variável usada pelo loop.
    local PACOTE


    echo
    echo "Verificando disponibilidade dos pacotes..."
    echo


    # Percorre todos os pacotes.
    for PACOTE in "${PACOTES[@]}"; do

        # Verifica se o pacote está disponível.
        if pacote_disponivel "$PACOTE"; then

            success "$PACOTE"

        else

            error "$PACOTE — não encontrado nos repositórios."

            # Adiciona o pacote à lista de ausentes.
            FALTANDO+=("$PACOTE")

        fi

    done


    echo


    # ${#FALTANDO[@]} representa a quantidade de itens
    # existentes no array.
    if [ "${#FALTANDO[@]}" -gt 0 ]; then

        error "Existem pacotes necessários que não estão disponíveis."

        echo
        echo "Pacotes ausentes:"


        # Mostra cada pacote ausente.
        for PACOTE in "${FALTANDO[@]}"; do
            echo "  ✗ $PACOTE"
        done


        echo

        warning "A etapa não será executada para evitar uma instalação incompleta."

        return 1
    fi


    # Todos os pacotes foram encontrados.
    success "Todos os pacotes necessários estão disponíveis."

    return 0
}



# ============================================================
# FUNÇÃO: INSTALAR PACOTE
# ============================================================

# Instala um pacote somente se ele ainda não estiver instalado.
#
# O DEBIAN_FRONTEND=noninteractive impede que o APT/DPKG
# abra telas interativas de configuração durante a instalação.
instalar_pacote() {

    # Primeiro argumento recebido pela função.
    local PACOTE="$1"


    # Verifica se o pacote já está instalado.
    if pacote_instalado "$PACOTE"; then

        success "$PACOTE já está instalado."

        return 0

    fi


    # Mostra qual pacote está sendo instalado.
    info "Instalando $PACOTE..."


    # O DEBIAN_FRONTEND é colocado depois do sudo.
    #
    # Dessa forma, a variável é aplicada ao comando que o sudo
    # realmente executará.
    if sudo DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "$PACOTE"; then

        success "$PACOTE instalado."

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
# Exemplo:
#
#     verificar_comando "git"
#
# command -v retorna o caminho do executável se ele existir.
verificar_comando() {

    local COMANDO="$1"


    if command -v "$COMANDO" >/dev/null 2>&1; then

        success "$COMANDO encontrado."

    else

        warning "$COMANDO não foi encontrado."

    fi
}


# ============================================================
# FUNÇÃO: CONFIRMAR ETAPA
# ============================================================

# Pergunta ao usuário se ele deseja executar determinada etapa.
#
# Existe um detalhe importante aqui.
#
# Quando executamos:
#
#     curl URL | bash
#
# o stdin do Bash recebe os dados enviados pelo curl.
#
# Portanto, um simples:
#
#     read
#
# poderia não funcionar corretamente.
#
# Para resolver isso, usamos:
#
#     </dev/tty
#
# Dessa maneira, a pergunta é lida diretamente do terminal.
confirmar_etapa() {

    # Número da etapa recebido como argumento.
    local NUMERO="$1"


    # Variável onde será armazenada a resposta.
    local RESPOSTA=""


    echo


    # Verifica se o terminal está disponível.
    if [ ! -r /dev/tty ]; then

        warning "Terminal interativo não está disponível."

        return 1
    fi


    # Pergunta ao usuário.
    #
    # [S/n] significa:
    #
    # Enter = Sim
    # S/s   = Sim
    # N/n   = Não
    read -r -p \
        "Deseja continuar com a Etapa $NUMERO? [S/n]: " \
        RESPOSTA </dev/tty


    # Se o usuário apertou somente Enter,
    # assumimos que ele deseja continuar.
    if [ -z "$RESPOSTA" ]; then
        return 0
    fi


    # Aceita S ou s.
    if [[ "$RESPOSTA" =~ ^[Ss]$ ]]; then
        return 0
    fi


    # Qualquer outra resposta cancela a etapa.
    return 1
}


# ============================================================
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"


# Antes de instalar os programas, atualizamos a lista
# de pacotes disponível no sistema.
info "Atualizando os repositórios APT..."


sudo apt-get update


success "Repositórios atualizados."


# ============================================================
# ETAPA 1
# ============================================================

title "ETAPA 1 — ZSH E FERRAMENTAS BÁSICAS"


# Verifica se existe o arquivo marcador da Etapa 1.
#
# Se existir, significa que a etapa já foi concluída
# em uma execução anterior.
if [ -f "$ETAPA1" ]; then

    success "Etapa 1 já foi concluída anteriormente."
    info "Pulando Etapa 1."

else

    # Pergunta ao usuário se deseja iniciar a etapa.
    if confirmar_etapa 1; then


        # Verifica todos os pacotes antes de começar.
        if verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Instalando pacotes da Etapa 1..."


            # Percorre todos os pacotes do array.
            for PACOTE in "${PACOTES_ETAPA1[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # INSTALAÇÃO DO OH MY ZSH
            # ------------------------------------------------

            # Verifica se o diretório do Oh My Zsh já existe.
            if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

                success "Oh My Zsh já está instalado."

            else

                info "Instalando Oh My Zsh..."


                # O instalador oficial do Oh My Zsh é baixado
                # através do curl.
                #
                # RUNZSH=no:
                # não inicia o Zsh automaticamente.
                #
                # CHSH=no:
                # não altera o shell padrão automaticamente.
                #
                # Nós configuramos isso manualmente logo depois.
                RUNZSH=no CHSH=no sh -c \
                    "$(curl -fsSL \
                    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


                success "Oh My Zsh instalado."

            fi


            # ------------------------------------------------
            # GARANTIR QUE O .zshrc EXISTE
            # ------------------------------------------------

            # touch cria o arquivo caso ele ainda não exista.
            #
            # Se ele já existir, seu conteúdo permanece intacto.
            touch "$ZSHRC"


            # ------------------------------------------------
            # BACKUP DO .zshrc
            # ------------------------------------------------

            # Antes de alterar o arquivo, criamos uma cópia.
            #
            # O backup só é criado uma vez.
            if [ ! -f "$HOME_USUARIO/.zshrc.etapa1.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa1.backup"

                success "Backup do .zshrc criado."

            else

                success "Backup do .zshrc já existe."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO TEMA AGNOSTER
            # ------------------------------------------------

            # Verifica se já existe uma linha ZSH_THEME.
            if grep -q '^ZSH_THEME=' "$ZSHRC"; then

                # Substitui o tema existente.
                sed -i \
                    's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
                    "$ZSHRC"

            else

                # Caso não exista, adicionamos a configuração.
                echo 'ZSH_THEME="agnoster"' >> "$ZSHRC"

            fi


            success "Tema Agnoster configurado."


            # ------------------------------------------------
            # DEFINIR ZSH COMO SHELL PADRÃO
            # ------------------------------------------------

            # Obtém o caminho do executável do Zsh.
            ZSH_PATH="$(command -v zsh)"


            # Descobre qual shell está configurado atualmente
            # para o usuário.
            CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"


            # Verifica se o Zsh já é o shell padrão.
            if sudo chsh -s "$ZSH_PATH" "$USER"; then
                success "Zsh definido como shell padrão."
            else
                warning "Não foi possível alterar o shell padrão automaticamente."
                warning "O Zsh foi instalado, mas será necessário configurá-lo manualmente."
            fi


            # ------------------------------------------------
            # VERIFICAÇÃO DOS PROGRAMAS
            # ------------------------------------------------

            verificar_comando "zsh"
            verificar_comando "curl"
            verificar_comando "git"
            verificar_comando "nano"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 1
            # ------------------------------------------------

            # O marcador só é criado depois que todos os
            # procedimentos da etapa terminaram.
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


# Verifica se a etapa já foi concluída.
if [ -f "$ETAPA2" ]; then

    success "Etapa 2 já foi concluída anteriormente."
    info "Pulando Etapa 2."

else

# Solicita confirmação.
if confirmar_etapa 2; then


    # ------------------------------------------------
    # PREPARAÇÃO DO SNAPD NO LINUX MINT
    # ------------------------------------------------

    # O Linux Mint bloqueia a instalação do Snap
    # através do arquivo "nosnap.pref".
    #
    # Essa configuração é específica do Linux Mint.
    # Não devemos removê-la em Ubuntu, Debian ou
    # outras distribuições.

    if [ "${ID:-}" = "linuxmint" ]; then

        NOSNAP_PREF="/etc/apt/preferences.d/nosnap.pref"


        # Verifica se o bloqueio do Snap existe.
        if [ -f "$NOSNAP_PREF" ]; then

            info "Bloqueio do Snap detectado no Linux Mint."


            # ------------------------------------------------
            # BACKUP DO BLOQUEIO
            # ------------------------------------------------

            # Fazemos um backup antes de remover o arquivo.
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

    # Agora o APT já está preparado para verificar
    # corretamente a disponibilidade do snapd.
    if verificar_pacotes_etapa "${PACOTES_ETAPA2[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Instalando pacotes da Etapa 2..."


            for PACOTE in "${PACOTES_ETAPA2[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # FIGLET FONTS
            # ------------------------------------------------

            # Define onde o repositório de fontes será colocado.
            FIGLET_FONTS="$HOME_USUARIO/figlet-fonts"


            # Se já for um repositório Git, não precisamos
            # baixar novamente.
            if [ -d "$FIGLET_FONTS/.git" ]; then

                success "Figlet Fonts já está instalado."


            # Se o diretório existe, mas não é Git,
            # não sobrescrevemos seu conteúdo.
            elif [ -d "$FIGLET_FONTS" ]; then

                warning "$FIGLET_FONTS já existe, mas não é um repositório Git."


            else

                info "Baixando Figlet Fonts..."


                # Clona o repositório de fontes.
                git clone \
                    https://github.com/xero/figlet-fonts.git \
                    "$FIGLET_FONTS"


                success "Figlet Fonts instalado."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO FIGLET NO ZSH
            # ------------------------------------------------

            # Comando que será colocado no ~/.zshrc.
            #
            # O Figlet usa a fonte "3d".
            #
            # Depois o texto é enviado para o lolcat.
            FIGLET_COMMAND='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'


            # Verifica se a configuração já existe.
            if grep -Fqx "$FIGLET_COMMAND" "$ZSHRC"; then

                success "Mensagem OHMYZSH já está configurada."

            else

                # Adiciona a configuração ao final do arquivo.
                printf '\n%s\n' "$FIGLET_COMMAND" >> "$ZSHRC"

                success "Mensagem OHMYZSH adicionada ao .zshrc."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO SNAPD
            # ------------------------------------------------

            # Habilita o socket do Snap e o inicia imediatamente.
            #
            # "enable" faz o serviço iniciar junto com o sistema.
            #
            # "--now" faz o serviço iniciar agora.
            #
            # "|| true" impede que uma falha nesse comando
            # encerre todo o script.
            sudo systemctl enable --now snapd.socket 2>/dev/null || true


            # Aguarda alguns segundos para o Snap terminar
            # sua inicialização.
            sleep 3


            # ------------------------------------------------
            # COOL RETRO TERM
            # ------------------------------------------------

            # Verifica se o comando snap existe.
            if command -v snap >/dev/null 2>&1; then


                # Verifica se o Cool Retro Term já está instalado.
                if snap list cool-retro-term >/dev/null 2>&1; then

                    success "Cool Retro Term já está instalado."

                else

                    info "Instalando Cool Retro Term..."


                    # Instala o pacote pelo Snap.
                    sudo snap install cool-retro-term --classic


                    success "Cool Retro Term instalado."

                fi


            else

                # O Snap não está disponível.
                warning "Cool Retro Term não será instalado porque o Snap não está disponível."

            fi


            # ------------------------------------------------
            # MARI0
            # ------------------------------------------------

            # Verifica novamente se o Snap está disponível.
            if command -v snap >/dev/null 2>&1; then


                # Verifica se Mari0 já está instalado.
                if snap list mari0 >/dev/null 2>&1; then

                    success "Mari0 já está instalado."

                else

                    info "Instalando Mari0..."


                    # Instala Mari0 através do Snap.
                    sudo snap install mari0


                    success "Mari0 instalado."

                fi


            else

                warning "Mari0 não será instalado porque o Snap não está disponível."

            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL
            # ------------------------------------------------

            verificar_comando "emacs"
            verificar_comando "figlet"
            verificar_comando "lolcat"
            verificar_comando "terminator"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 2
            # ------------------------------------------------

            # Marca a etapa como concluída.
            touch "$ETAPA2"


            success "Etapa 2 concluída."

        fi

    else

        warning "Etapa 2 cancelada pelo usuário."

    fi

fi


# ============================================================
# ETAPA 3
# ============================================================

title "ETAPA 3 — UTILITÁRIOS"


# Verifica se a Etapa 3 já foi concluída.
if [ -f "$ETAPA3" ]; then

    success "Etapa 3 já foi concluída anteriormente."
    info "Pulando Etapa 3."

else

    # Solicita confirmação.
    if confirmar_etapa 3; then


        # Verifica os pacotes necessários.
        if verificar_pacotes_etapa "${PACOTES_ETAPA3[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Instalando pacotes da Etapa 3..."


            for PACOTE in "${PACOTES_ETAPA3[@]}"; do

                instalar_pacote "$PACOTE"

            done


            # ------------------------------------------------
            # BACKUP DO .zshrc
            # ------------------------------------------------

            # Como a Etapa 3 também modifica o ~/.zshrc,
            # fazemos outro backup.
            if [ ! -f "$HOME_USUARIO/.zshrc.etapa3.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa3.backup"

                success "Backup do .zshrc da Etapa 3 criado."

            else

                success "Backup do .zshrc da Etapa 3 já existe."

            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO BAT
            # ------------------------------------------------

            # No Debian e em várias distribuições derivadas,
            # o executável do pacote "bat" é chamado de
            # "batcat".
            #
            # O alias permite utilizar:
            #
            #     cat arquivo.txt
            #
            # e fazer o sistema utilizar o batcat.
            if grep -Fqx 'alias cat="batcat"' "$ZSHRC"; then

                success 'Alias cat="batcat" já está configurado.'

            else

                echo 'alias cat="batcat"' >> "$ZSHRC"

                success 'Alias cat="batcat" adicionado ao .zshrc.'

            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL
            # ------------------------------------------------

            verificar_comando "jq"
            verificar_comando "batcat"
            verificar_comando "neofetch"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 3
            # ------------------------------------------------

            # Marca a etapa como concluída.
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


# Informa que todas as etapas foram processadas.
success "Todas as etapas foram processadas."


# ============================================================
# INFORMAÇÕES FINAIS
# ============================================================

# O ~/.zshrc foi alterado durante a execução.
#
# Porém, a sessão atual do terminal foi iniciada antes dessas
# alterações.
#
# Por isso, precisamos recarregar o arquivo manualmente.
echo
info "Para aplicar as alterações do Zsh na sessão atual, execute:"
echo
echo "    source ~/.zshrc"
echo


# Mostra o caminho do log.
info "O log desta execução está em:"
echo
echo "    $LOG_FILE"
echo


# Mostra os arquivos utilizados para controlar as etapas.
info "Marcadores das etapas:"
echo
echo "    $ETAPA1"
echo "    $ETAPA2"
echo "    $ETAPA3"
echo


# Mensagem final.
success "Script concluído com sucesso."


# Código de saída 0 significa que o script terminou
# normalmente.
exit 0

```bash
#!/bin/bash

# ============================================================
# PREPARAÇÃO DE SISTEMAS OPERACIONAIS
# ============================================================
#
# Este script foi desenvolvido para automatizar a preparação
# de um ambiente Linux baseado em Debian/Ubuntu.
#
# O script é dividido em 3 etapas:
#
#   ETAPA 1
#   - zsh
#   - curl
#   - git
#   - fonts-powerline
#   - nano
#   - Oh My Zsh
#   - tema Agnoster
#
#   ETAPA 2
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
#   ETAPA 3
#   - neofetch
#   - jq
#   - bat
#   - alias cat="batcat"
#
# Características:
#   - Compatível com distribuições que utilizam APT/DPKG
#   - Verificação dos pacotes antes de cada etapa
#   - Confirmação do usuário antes de executar cada etapa
#   - Pode ser executado através de "curl | bash"
#   - Cria arquivos de controle para evitar repetição
#   - Registra a execução em um arquivo de log
#
# ============================================================


# ============================================================
# CONFIGURAÇÃO DO BASH
# ============================================================

# Faz o script ser encerrado caso algum comando importante
# retorne um código de erro diferente de zero.
#
# Não utilizamos "set -u" nem "set -o pipefail" aqui para
# evitar problemas desnecessários durante a execução remota
# através de "curl | bash".
set -e


# ============================================================
# CORES UTILIZADAS NAS MENSAGENS
# ============================================================

# Código ANSI para azul.
BLUE='\033[0;34m'

# Código ANSI para verde.
GREEN='\033[0;32m'

# Código ANSI para amarelo.
YELLOW='\033[1;33m'

# Código ANSI para vermelho.
RED='\033[0;31m'

# Código ANSI para restaurar a cor original do terminal.
NC='\033[0m'


# ============================================================
# FUNÇÕES DE MENSAGEM
# ============================================================

# Mostra uma mensagem informativa.
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Mostra uma mensagem indicando que algo foi concluído.
success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Mostra um aviso.
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Mostra uma mensagem de erro.
error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Mostra um título para separar visualmente as partes
# do programa no terminal.
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

# O script deve ser executado por um usuário normal.
#
# Não queremos que o usuário execute:
#
#     sudo bash preparar_so.sh
#
# porque o script utiliza "sudo" somente nos comandos que
# realmente precisam de privilégios administrativos.
#
# Além disso, executar tudo como root faria com que arquivos
# como ~/.zshrc e ~/.oh-my-zsh fossem criados no diretório
# /root em vez do diretório do usuário.
if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root."
    error "Execute como usuário normal."
    exit 1
fi


# ============================================================
# VERIFICAÇÃO DO SISTEMA OPERACIONAL
# ============================================================

# O arquivo /etc/os-release contém informações sobre a
# distribuição Linux instalada.
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
#
# O comando "source" transforma as variáveis desse arquivo
# em variáveis disponíveis para o script.
if [ ! -f /etc/os-release ]; then
    error "Não foi possível identificar o sistema operacional."
    exit 1
fi

source /etc/os-release


# Verifica se o gerenciador de pacotes APT está instalado.
#
# Como o objetivo deste projeto é trabalhar com distribuições
# baseadas em Debian, o APT é necessário.
if ! command -v apt-get >/dev/null 2>&1; then
    error "O sistema não possui o apt-get."
    error "Este script foi desenvolvido para sistemas baseados em Debian/Ubuntu."
    exit 1
fi


# Verifica se o DPKG está instalado.
#
# O DPKG é utilizado pelo Debian e seus derivados para
# gerenciar os pacotes .deb.
if ! command -v dpkg >/dev/null 2>&1; then
    error "O sistema não possui o dpkg."
    exit 1
fi


# Verifica se o sudo está instalado.
#
# O sudo será utilizado para executar somente os comandos
# que precisam de privilégios administrativos.
if ! command -v sudo >/dev/null 2>&1; then
    error "O comando sudo não está instalado."
    exit 1
fi


# Obtém a arquitetura do sistema.
#
# Exemplos:
#
#   amd64
#   arm64
#
# Isso é útil principalmente para registrar informações
# do ambiente no log.
ARQUITETURA="$(dpkg --print-architecture)"


# ============================================================
# VARIÁVEIS PRINCIPAIS
# ============================================================

# Diretório pessoal do usuário que executou o script.
#
# Exemplo:
#
#   /home/frangogamer
#
# Usamos $HOME em vez de colocar um caminho fixo para que
# o script funcione para diferentes usuários.
HOME_USUARIO="$HOME"


# Arquivo utilizado para registrar toda a execução do script.
#
# Isso permite verificar posteriormente:
#
#   - quais etapas foram executadas;
#   - quais pacotes foram instalados;
#   - quais erros ocorreram;
#   - quando o script foi executado.
LOG_FILE="$HOME_USUARIO/preparacao_sistemas_operacionais.log"


# Arquivo de controle da Etapa 1.
#
# Quando a etapa termina com sucesso, este arquivo é criado.
#
# Em uma execução futura, o script verifica sua existência
# e não executa novamente a etapa.
ETAPA1="$HOME_USUARIO/.sistemas_operacionais_etapa1"


# Arquivo de controle da Etapa 2.
ETAPA2="$HOME_USUARIO/.sistemas_operacionais_etapa2"


# Arquivo de controle da Etapa 3.
ETAPA3="$HOME_USUARIO/.sistemas_operacionais_etapa3"


# Caminho do arquivo de configuração do Zsh.
ZSHRC="$HOME_USUARIO/.zshrc"


# ============================================================
# INÍCIO DO LOG
# ============================================================

# "tee" permite que a saída continue aparecendo no terminal
# enquanto também é gravada no arquivo de log.
#
# Dessa forma, o usuário consegue acompanhar a instalação
# normalmente e ainda possui um histórico da execução.
exec > >(tee -a "$LOG_FILE") 2>&1


# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

title "PREPARAÇÃO DO SISTEMA OPERACIONAL"

echo "Sistema operacional : ${PRETTY_NAME:-Desconhecido}"
echo "ID da distribuição  : ${ID:-Desconhecido}"
echo "Arquitetura         : $ARQUITETURA"
echo "Usuário             : $USER"
echo "HOME                : $HOME_USUARIO"
echo


# ============================================================
# VERIFICAÇÃO DO SUDO
# ============================================================

# Solicita a senha do usuário antes de começar.
#
# Isso evita que o script pare no meio da instalação esperando
# uma senha do sudo.
info "Verificando permissões administrativas..."

sudo -v

success "Permissões administrativas confirmadas."


# ============================================================
# LISTAS DE PACOTES
# ============================================================

# Pacotes necessários para a Etapa 1.
#
# As listas são mantidas em arrays para facilitar:
#
#   - verificar quais pacotes existem;
#   - instalar os pacotes;
#   - adicionar/remover pacotes futuramente.
PACOTES_ETAPA1=(
    "zsh"
    "curl"
    "git"
    "fonts-powerline"
    "nano"
)


# Pacotes necessários para a Etapa 2.
PACOTES_ETAPA2=(
    "emacs"
    "figlet"
    "lolcat"
    "ksudoku"
    "terminator"
    "snapd"
)


# Pacotes necessários para a Etapa 3.
PACOTES_ETAPA3=(
    "neofetch"
    "jq"
    "bat"
)


# ============================================================
# FUNÇÃO: VERIFICAR SE UM PACOTE ESTÁ INSTALADO
# ============================================================

# Recebe o nome de um pacote como parâmetro.
#
# Exemplo:
#
#     pacote_instalado "git"
#
# Retorna:
#
#     0 -> instalado
#     1 -> não instalado
pacote_instalado() {

    local PACOTE="$1"

    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0
    fi

    return 1
}


# ============================================================
# FUNÇÃO: VERIFICAR SE UM PACOTE ESTÁ DISPONÍVEL
# ============================================================

# Essa função é diferente de "pacote_instalado".
#
# Um pacote pode não estar instalado, mas ainda assim existir
# nos repositórios configurados no sistema.
#
# Exemplo:
#
#     git
#
# pode estar disponível para instalação, mesmo que ainda
# não esteja instalado.
pacote_disponivel() {

    local PACOTE="$1"


    # Primeiro verificamos se o pacote já está instalado.
    #
    # Se estiver instalado, consideramos que ele está disponível.
    if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null \
        | grep -q "install ok installed"; then

        return 0
    fi


    # Caso não esteja instalado, verificamos se o APT conhece
    # esse pacote.
    if apt-cache show "$PACOTE" >/dev/null 2>&1; then
        return 0
    fi


    # Caso nenhuma das verificações tenha funcionado,
    # o pacote não está disponível.
    return 1
}


# ============================================================
# FUNÇÃO: VERIFICAR PACOTES DE UMA ETAPA
# ============================================================

# Antes de começar uma etapa, verificamos todos os pacotes
# necessários.
#
# Isso evita iniciar uma etapa e descobrir somente no meio
# da instalação que determinado pacote não existe nos
# repositórios daquela distribuição.
verificar_pacotes_etapa() {

    # Cria uma variável local contendo todos os argumentos
    # recebidos pela função.
    local PACOTES=("$@")

    # Array que armazenará os pacotes ausentes.
    local FALTANDO=()

    # Variável utilizada no loop.
    local PACOTE


    echo
    echo "Verificando disponibilidade dos pacotes..."
    echo


    # Percorre todos os pacotes recebidos.
    for PACOTE in "${PACOTES[@]}"; do

        # Verifica se o pacote está disponível.
        if pacote_disponivel "$PACOTE"; then

            # Pacote encontrado.
            success "$PACOTE"

        else

            # Pacote não encontrado.
            error "$PACOTE — não encontrado nos repositórios."

            # Adiciona o pacote à lista de ausentes.
            FALTANDO+=("$PACOTE")
        fi

    done


    echo


    # Verifica se o array FALTANDO possui algum elemento.
    if [ "${#FALTANDO[@]}" -gt 0 ]; then

        error "Existem pacotes necessários que não estão disponíveis."
        echo

        echo "Pacotes ausentes:"

        # Mostra todos os pacotes ausentes.
        for PACOTE in "${FALTANDO[@]}"; do
            echo "  ✗ $PACOTE"
        done

        echo

        warning "A etapa não será executada para evitar uma instalação incompleta."

        return 1
    fi


    # Se chegamos aqui, todos os pacotes foram encontrados.
    success "Todos os pacotes necessários estão disponíveis."

    return 0
}


# ============================================================
# FUNÇÃO: INSTALAR UM PACOTE
# ============================================================

# Instala um pacote somente quando ele ainda não está instalado.
#
# Isso torna o script idempotente:
#
# executar novamente não significa reinstalar tudo.
instalar_pacote() {

    local PACOTE="$1"


    # Verifica se o pacote já está instalado.
    if pacote_instalado "$PACOTE"; then

        success "$PACOTE já está instalado."

    else

        # Caso não esteja instalado, utiliza o APT.
        info "Instalando $PACOTE..."

        sudo apt-get install -y "$PACOTE"

        success "$PACOTE instalado."
    fi
}


# ============================================================
# FUNÇÃO: VERIFICAR COMANDO
# ============================================================

# Verifica se um determinado comando está disponível
# no PATH do usuário.
#
# Exemplo:
#
#     verificar_comando "zsh"
#
# O comando "command -v" procura pelo executável.
verificar_comando() {

    local COMANDO="$1"


    if command -v "$COMANDO" >/dev/null 2>&1; then

        success "$COMANDO encontrado."

    else

        warning "$COMANDO não foi encontrado."
    fi
}


# ============================================================
# FUNÇÃO: CONFIRMAR EXECUÇÃO DE UMA ETAPA
# ============================================================

# Pergunta ao usuário se ele deseja executar determinada etapa.
#
# Existe um detalhe importante:
#
# quando o script é executado assim:
#
#     curl ... | bash
#
# o stdin do Bash está sendo utilizado pelo conteúdo enviado
# pelo curl.
#
# Por isso não podemos simplesmente usar:
#
#     read ...
#
# Precisamos ler diretamente do terminal através de /dev/tty.
confirmar_etapa() {

    local NUMERO="$1"
    local RESPOSTA=""


    echo


    # Verifica se existe um terminal disponível.
    if [ ! -r /dev/tty ]; then

        warning "Terminal interativo não está disponível."

        return 1
    fi


    # Lê a resposta diretamente do terminal.
    #
    # [S/n] significa:
    #
    #   Enter -> Sim
    #   S     -> Sim
    #   s     -> Sim
    #   N     -> Não
    #   n     -> Não
    read -r -p \
        "Deseja continuar com a Etapa $NUMERO? [S/n]: " \
        RESPOSTA </dev/tty


    # Se o usuário apenas apertou Enter,
    # consideramos que a resposta é SIM.
    if [ -z "$RESPOSTA" ]; then
        return 0
    fi


    # Aceita S ou s como confirmação.
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

# Atualiza a lista de pacotes disponíveis.
#
# Isso é importante porque o sistema pode estar utilizando
# informações antigas dos repositórios.
info "Atualizando os repositórios APT..."

sudo apt-get update

success "Repositórios atualizados."


# ============================================================
# ETAPA 1
# ============================================================

title "ETAPA 1 — ZSH E FERRAMENTAS BÁSICAS"


# Verifica se a etapa já foi executada anteriormente.
#
# O arquivo marcador é criado somente depois que todos os
# procedimentos da etapa forem concluídos.
if [ -f "$ETAPA1" ]; then

    success "Etapa 1 já foi concluída anteriormente."
    info "Pulando Etapa 1."

else

    # Solicita confirmação antes de executar a etapa.
    if confirmar_etapa 1; then

        # Verifica se todos os pacotes necessários existem.
        if verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"; then


            # ------------------------------------------------
            # INSTALAÇÃO DOS PACOTES
            # ------------------------------------------------

            info "Instalando pacotes da Etapa 1..."

            for PACOTE in "${PACOTES_ETAPA1[@]}"; do
                instalar_pacote "$PACOTE"
            done


            # ------------------------------------------------
            # INSTALAÇÃO DO OH MY ZSH
            # ------------------------------------------------

            # O Oh My Zsh é instalado dentro do diretório
            # ~/.oh-my-zsh.
            #
            # Se o diretório já existir, não fazemos
            # novamente o download.
            if [ -d "$HOME_USUARIO/.oh-my-zsh" ]; then

                success "Oh My Zsh já está instalado."

            else

                info "Instalando Oh My Zsh..."


                # RUNZSH=no
                #
                # Impede que o instalador abra automaticamente
                # uma nova sessão do Zsh.
                #
                # CHSH=no
                #
                # Impede que o instalador altere o shell padrão.
                #
                # Nós mesmos fazemos essa configuração depois,
                # de maneira controlada.
                RUNZSH=no CHSH=no sh -c \
                    "$(curl -fsSL \
                    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


                success "Oh My Zsh instalado."
            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO ZSH
            # ------------------------------------------------

            # O arquivo ~/.zshrc pode não existir em algumas
            # situações.
            #
            # O comando abaixo cria o arquivo vazio caso seja
            # necessário.
            touch "$ZSHRC"


            # ------------------------------------------------
            # BACKUP DO .zshrc
            # ------------------------------------------------

            # Antes de modificar o arquivo, criamos um backup.
            #
            # Isso permite recuperar a configuração original
            # caso seja necessário.
            if [ ! -f "$HOME_USUARIO/.zshrc.etapa1.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa1.backup"

                success "Backup do .zshrc criado."

            else

                success "Backup do .zshrc já existe."
            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO TEMA AGNOSTER
            # ------------------------------------------------

            # Verifica se já existe uma configuração ZSH_THEME.
            if grep -q '^ZSH_THEME=' "$ZSHRC"; then

                # Substitui o tema atual pelo Agnoster.
                sed -i \
                    's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' \
                    "$ZSHRC"

            else

                # Caso não exista configuração de tema,
                # adicionamos uma nova.
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


            # Só executamos chsh caso ainda não seja Zsh.
            if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then

                success "Zsh já é o shell padrão."

            else

                info "Definindo Zsh como shell padrão..."

                chsh -s "$ZSH_PATH"

                success "Zsh definido como shell padrão."
            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL DA ETAPA 1
            # ------------------------------------------------

            verificar_comando "zsh"
            verificar_comando "curl"
            verificar_comando "git"
            verificar_comando "nano"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 1
            # ------------------------------------------------

            # Só criamos o marcador depois que a etapa inteira
            # chegou ao final.
            #
            # Assim, se houver um erro durante a instalação,
            # a etapa não será considerada concluída.
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


# Verifica se a etapa já foi executada.
if [ -f "$ETAPA2" ]; then

    success "Etapa 2 já foi concluída anteriormente."
    info "Pulando Etapa 2."

else

    # Solicita confirmação.
    if confirmar_etapa 2; then

        # Verifica os pacotes antes da instalação.
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

            # Diretório onde os estilos adicionais do Figlet
            # serão armazenados.
            FIGLET_FONTS="$HOME_USUARIO/figlet-fonts"


            # Se o repositório Git já existe, não fazemos
            # novamente o clone.
            if [ -d "$FIGLET_FONTS/.git" ]; then

                success "Figlet Fonts já está instalado."


            # Caso o diretório exista mas não seja um
            # repositório Git, não sobrescrevemos o conteúdo.
            elif [ -d "$FIGLET_FONTS" ]; then

                warning "$FIGLET_FONTS já existe, mas não é um repositório Git."


            else

                info "Baixando Figlet Fonts..."


                # Clona o repositório diretamente para o
                # diretório escolhido.
                git clone \
                    https://github.com/xero/figlet-fonts.git \
                    "$FIGLET_FONTS"


                success "Figlet Fonts instalado."
            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO FIGLET
            # ------------------------------------------------

            # Comando que será colocado no ~/.zshrc.
            #
            # O Figlet escreve "OHMYZSH!" usando a fonte 3d.
            #
            # O resultado é enviado para o lolcat, que adiciona
            # as cores ao texto.
            FIGLET_COMMAND='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'


            # Verifica se o comando já existe no ~/.zshrc.
            #
            # Isso evita adicionar a mesma linha várias vezes
            # quando o script for executado novamente.
            if grep -Fqx "$FIGLET_COMMAND" "$ZSHRC"; then

                success "Mensagem OHMYZSH já está configurada."

            else

                # Adiciona o comando ao final do ~/.zshrc.
                printf '\n%s\n' "$FIGLET_COMMAND" >> "$ZSHRC"

                success "Mensagem OHMYZSH adicionada ao .zshrc."
            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO SNAPD
            # ------------------------------------------------

            # Habilita e inicia o socket do Snap.
            #
            # "enable" faz o serviço iniciar automaticamente
            # com o sistema.
            #
            # "--now" também inicia imediatamente.
            #
            # O "|| true" impede que um problema nesse comando
            # encerre todo o script.
            sudo systemctl enable --now snapd.socket 2>/dev/null || true


            # Dá alguns segundos para o serviço do Snap
            # terminar de inicializar.
            sleep 3


            # ------------------------------------------------
            # COOL RETRO TERM
            # ------------------------------------------------

            # Primeiro verificamos se o comando snap existe.
            if command -v snap >/dev/null 2>&1; then


                # Verifica se o pacote já está instalado.
                if snap list cool-retro-term >/dev/null 2>&1; then

                    success "Cool Retro Term já está instalado."

                else

                    info "Instalando Cool Retro Term..."


                    # Instala o pacote através do Snap.
                    sudo snap install cool-retro-term --classic


                    success "Cool Retro Term instalado."
                fi


            else

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


                    # Instala Mari0 utilizando Snap.
                    sudo snap install mari0


                    success "Mari0 instalado."
                fi


            else

                warning "Mari0 não será instalado porque o Snap não está disponível."
            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL DA ETAPA 2
            # ------------------------------------------------

            verificar_comando "emacs"
            verificar_comando "figlet"
            verificar_comando "lolcat"
            verificar_comando "terminator"


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

        # Verifica se todos os pacotes estão disponíveis.
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

            # Como a Etapa 3 também altera o ~/.zshrc,
            # fazemos outro backup específico.
            if [ ! -f "$HOME_USUARIO/.zshrc.etapa3.backup" ]; then

                cp "$ZSHRC" "$HOME_USUARIO/.zshrc.etapa3.backup"

                success "Backup do .zshrc da Etapa 3 criado."

            else

                success "Backup do .zshrc da Etapa 3 já existe."
            fi


            # ------------------------------------------------
            # CONFIGURAÇÃO DO BAT
            # ------------------------------------------------

            # Em sistemas Debian/Ubuntu, o executável do pacote
            # "bat" normalmente é chamado de "batcat".
            #
            # Para que o usuário possa utilizar simplesmente:
            #
            #     cat arquivo.txt
            #
            # configuramos um alias que redireciona "cat" para
            # o "batcat".
            if grep -Fqx 'alias cat="batcat"' "$ZSHRC"; then

                success 'Alias cat="batcat" já está configurado.'

            else

                echo 'alias cat="batcat"' >> "$ZSHRC"

                success 'Alias cat="batcat" adicionado ao .zshrc.'
            fi


            # ------------------------------------------------
            # VERIFICAÇÃO FINAL DA ETAPA 3
            # ------------------------------------------------

            verificar_comando "jq"
            verificar_comando "batcat"
            verificar_comando "neofetch"


            # ------------------------------------------------
            # MARCADOR DA ETAPA 3
            # ------------------------------------------------

            # Indica que toda a Etapa 3 foi concluída.
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


# Mensagem final indicando que o script chegou ao final.
success "Todas as etapas foram processadas."


# Explica ao usuário que as alterações do ~/.zshrc não são
# aplicadas automaticamente à sessão atual.
#
# Isso acontece porque o shell atual foi iniciado antes das
# alterações.
echo
info "Para aplicar as alterações do Zsh na sessão atual, execute:"
echo
echo "  source ~/.zshrc"
echo


# Mostra onde o log foi salvo.
info "O log desta execução está em:"
echo
echo "  $LOG_FILE"
echo


# Mostra os arquivos utilizados para controlar as etapas.
info "Marcadores das etapas:"
echo
echo "  $ETAPA1"
echo "  $ETAPA2"
echo "  $ETAPA3"
echo


success "Script concluído."
```

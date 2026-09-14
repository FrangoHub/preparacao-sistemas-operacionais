#!/bin/bash

# ============================================================
# PREPARAÇÃO DO AMBIENTE - SISTEMAS OPERACIONAIS
#
# Compatível com distribuições baseadas em Debian que utilizam:
#   - APT
#   - DPKG
#
# Exemplos:
#   - Ubuntu
#   - Debian
#   - Linux Mint
#   - Pop!_OS
#   - elementary OS
#   - Zorin OS
#   - Outras distribuições baseadas em Debian/Ubuntu
#
# ============================================================
#
# ETAPA 1:
#   - Zsh
#   - Oh My Zsh
#   - Tema Agnoster
#   - Fontes Powerline
#
# ETAPA 2:
#   - Emacs
#   - Figlet
#   - Figlet Fonts
#   - Lolcat
#   - Ksudoku
#   - Terminator
#   - Snapd
#   - Cool Retro Term
#   - Mari0
#
# ETAPA 3:
#   - Neofetch
#   - JQ
#   - Bat
#   - Alias cat="batcat"
#
# ============================================================

set -e

# ============================================================
# CORES
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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
# VERIFICAÇÃO DE ROOT
# ============================================================

if [ "$EUID" -eq 0 ]; then

  error "Não execute este script como root."

  echo
  echo "Execute normalmente:"
  echo
  echo "    ./preparar_so.sh"
  echo

  exit 1

fi

# ============================================================
# IDENTIFICAÇÃO DO SISTEMA
# ============================================================

if [ ! -f /etc/os-release ]; then

  error "Não foi possível identificar a distribuição Linux."

  exit 1

fi

source /etc/os-release

# ============================================================
# VERIFICAÇÃO DO DPKG
# ============================================================

if ! command -v dpkg >/dev/null 2>&1; then

  error "O DPKG não foi encontrado."
  error "Este script precisa de uma distribuição baseada em Debian."

  exit 1

fi

# ============================================================
# VERIFICAÇÃO DO APT
# ============================================================

if ! command -v apt-get >/dev/null 2>&1; then

  error "O APT não foi encontrado."
  error "Este script precisa de uma distribuição que utilize APT."

  exit 1

fi

# ============================================================
# VERIFICAÇÃO DO SUDO
# ============================================================

if ! command -v sudo >/dev/null 2>&1; then

  error "O sudo não está instalado."

  exit 1

fi

# ============================================================
# INFORMAÇÕES DO SISTEMA
# ============================================================

ARQUITETURA="$(dpkg --print-architecture)"

title "PREPARAÇÃO DO AMBIENTE"

echo "Distribuição:  ${PRETTY_NAME:-Desconhecida}"
echo "ID:            ${ID:-Desconhecido}"
echo "Versão:        ${VERSION_ID:-Desconhecida}"
echo "Arquitetura:   $ARQUITETURA"
echo "Kernel:        $(uname -r)"
echo "Usuário:       $USER"
echo

success "DPKG encontrado."
success "APT encontrado."
success "Sudo encontrado."

# ============================================================
# AUTENTICAÇÃO DO SUDO
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
# ATUALIZAÇÃO DOS REPOSITÓRIOS
# ============================================================

title "ATUALIZAÇÃO DOS REPOSITÓRIOS"

info "Atualizando os repositórios APT..."

sudo apt-get update

success "Repositórios atualizados."

# ============================================================
# FUNÇÃO PARA VERIFICAR DISPONIBILIDADE DE PACOTE
# ============================================================

pacote_disponivel() {

  PACOTE="$1"

  # Se já estiver instalado, consideramos disponível.
  if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null |
    grep -q "install ok installed"; then

    return 0

  fi

  # Verifica se o APT conhece o pacote.
  if apt-cache show "$PACOTE" >/dev/null 2>&1; then

    return 0

  fi

  return 1
}

# ============================================================
# FUNÇÃO PARA VERIFICAR LISTA DE PACOTES
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
# FUNÇÃO PARA INSTALAR PACOTE
# ============================================================

instalar_pacote() {

  PACOTE="$1"

  if dpkg-query -W -f='${Status}' "$PACOTE" 2>/dev/null |
    grep -q "install ok installed"; then

    success "$PACOTE já está instalado."

  else

    info "Instalando $PACOTE..."

    sudo apt-get install -y "$PACOTE"

    success "$PACOTE instalado."

  fi
}

# ============================================================
# FUNÇÃO PARA VERIFICAR COMANDO
# ============================================================

verificar_comando() {

  COMANDO="$1"

  if command -v "$COMANDO" >/dev/null 2>&1; then

    success "$COMANDO encontrado."

  else

    warning "$COMANDO não foi encontrado."

  fi
}

# ============================================================
# MARCADORES
# ============================================================

ETAPA1="$HOME/.sistemas_operacionais_etapa1"
ETAPA2="$HOME/.sistemas_operacionais_etapa2"
ETAPA3="$HOME/.sistemas_operacionais_etapa3"

ZSHRC="$HOME/.zshrc"

# ============================================================
# ETAPA 1
# ============================================================

title "ETAPA 1"

echo "A Etapa 1 irá configurar:"
echo
echo "  • Zsh"
echo "  • Oh My Zsh"
echo "  • Fontes Powerline"
echo "  • Tema Agnoster"
echo "  • Zsh como shell padrão"
echo

# ============================================================
# VERIFICAÇÃO DA ETAPA 1
# ============================================================

info "Verificando pacotes da Etapa 1..."

PACOTES_ETAPA1=(
  "zsh"
  "curl"
  "git"
  "fonts-powerline"
  "nano"
)

if ! verificar_pacotes_etapa "${PACOTES_ETAPA1[@]}"; then

  error "A Etapa 1 não pode ser executada."

  exit 1

fi

# ============================================================
# CONFIRMAÇÃO
# ============================================================

echo

read -p "Deseja continuar com a Etapa 1? [s/N]: " resposta

if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

  info "Etapa 1 cancelada."

  exit 0

fi

# ============================================================
# INSTALAÇÃO ETAPA 1
# ============================================================

instalar_pacote "zsh"
instalar_pacote "curl"
instalar_pacote "git"
instalar_pacote "fonts-powerline"
instalar_pacote "nano"

# ============================================================
# VERIFICAR ZSH
# ============================================================

ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then

  error "Zsh não foi encontrado após a instalação."

  exit 1

fi

success "Zsh encontrado em: $ZSH_PATH"

# ============================================================
# OH MY ZSH
# ============================================================

if [ -d "$HOME/.oh-my-zsh" ]; then

  success "Oh My Zsh já está instalado."

else

  info "Instalando Oh My Zsh..."

  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  success "Oh My Zsh instalado."

fi

# ============================================================
# ZSHRC
# ============================================================

if [ -f "$ZSHRC" ]; then

  cp "$ZSHRC" "$HOME/.zshrc.etapa1.backup"

  success "Backup do ~/.zshrc criado."

else

  touch "$ZSHRC"

  success "~/.zshrc criado."

fi

# ============================================================
# TEMA AGNOSTER
# ============================================================

info "Configurando o tema Agnoster..."

if grep -q '^ZSH_THEME=' "$ZSHRC"; then

  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

else

  echo 'ZSH_THEME="agnoster"' >>"$ZSHRC"

fi

success "Tema Agnoster configurado."

# ============================================================
# SHELL PADRÃO
# ============================================================

SHELL_ATUAL="$(getent passwd "$USER" | cut -d: -f7)"

if [ "$SHELL_ATUAL" = "$ZSH_PATH" ]; then

  success "Zsh já é o shell padrão."

else

  info "Configurando Zsh como shell padrão..."

  chsh -s "$ZSH_PATH"

  success "Zsh definido como shell padrão."

fi

# ============================================================
# MARCAR ETAPA 1
# ============================================================

touch "$ETAPA1"

success "Etapa 1 concluída."

# ============================================================
# ETAPA 2
# ============================================================

title "ETAPA 2"

# ============================================================
# DEPENDÊNCIA DA ETAPA 1
# ============================================================

if [ ! -f "$ETAPA1" ]; then

  error "A Etapa 1 não foi concluída."
  error "A Etapa 2 não pode ser executada."

  exit 1

fi

success "Etapa 1 confirmada."

# ============================================================
# DESCRIÇÃO
# ============================================================

echo "A Etapa 2 irá instalar:"
echo
echo "  • Emacs"
echo "  • Figlet"
echo "  • Figlet Fonts"
echo "  • Lolcat"
echo "  • Ksudoku"
echo "  • Terminator"
echo "  • Snapd"
echo "  • Cool Retro Term"
echo "  • Mari0"
echo

# ============================================================
# VERIFICAÇÃO DOS PACOTES DA ETAPA 2
# ============================================================

info "Verificando pacotes da Etapa 2..."

PACOTES_ETAPA2=(
  "emacs"
  "figlet"
  "lolcat"
  "ksudoku"
  "terminator"
  "snapd"
)

if ! verificar_pacotes_etapa "${PACOTES_ETAPA2[@]}"; then

  error "A Etapa 2 não pode ser executada."

  exit 1

fi

# ============================================================
# CONFIRMAÇÃO
# ============================================================

echo

read -p "Deseja continuar com a Etapa 2? [s/N]: " resposta

if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

  info "Etapa 2 cancelada."

  exit 0

fi

# ============================================================
# EMACS
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                           EMACS"
echo "------------------------------------------------------------"
echo

instalar_pacote "emacs"

# ============================================================
# FIGLET
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                          FIGLET"
echo "------------------------------------------------------------"
echo

instalar_pacote "figlet"

# ============================================================
# LOLCAT
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                          LOLCAT"
echo "------------------------------------------------------------"
echo

instalar_pacote "lolcat"

# ============================================================
# FIGLET FONTS
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                       FIGLET FONTS"
echo "------------------------------------------------------------"
echo

FIGLET_FONTS="$HOME/figlet-fonts"

if [ -d "$FIGLET_FONTS/.git" ]; then

  success "Figlet Fonts já está instalado."

else

  if [ -d "$FIGLET_FONTS" ]; then

    warning "O diretório $FIGLET_FONTS já existe."

    mv "$FIGLET_FONTS" \
      "${FIGLET_FONTS}.backup.$(date +%Y%m%d%H%M%S)"

    success "Diretório antigo movido para backup."

  fi

  info "Clonando Figlet Fonts..."

  git clone \
    https://github.com/xero/figlet-fonts.git \
    "$FIGLET_FONTS"

  success "Figlet Fonts instalado."

fi

# ============================================================
# VERIFICAR FONTE 3D
# ============================================================

if [ -f "$FIGLET_FONTS/3d.flf" ]; then

  success "Fonte 3d encontrada."

else

  error "A fonte 3d.flf não foi encontrada."

  exit 1

fi

# ============================================================
# BACKUP ZSHRC
# ============================================================

cp "$ZSHRC" "$HOME/.zshrc.etapa2.backup"

success "Backup do ~/.zshrc criado."

# ============================================================
# FIGLET + LOLCAT
# ============================================================

OHMYZSH_CMD='figlet "OHMYZSH!" -f "3d" -d "$HOME/figlet-fonts/" | lolcat'

if grep -Fqx "$OHMYZSH_CMD" "$ZSHRC"; then

  success "Comando OHMYZSH já está no ~/.zshrc."

else

  echo "" >>"$ZSHRC"

  echo "# ============================================================" >>"$ZSHRC"
  echo "# SISTEMAS OPERACIONAIS - FIGLET + LOLCAT" >>"$ZSHRC"
  echo "# ============================================================" >>"$ZSHRC"

  echo "$OHMYZSH_CMD" >>"$ZSHRC"

  success "Comando OHMYZSH adicionado ao ~/.zshrc."

fi

# ============================================================
# KSUDOKU
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                         KSUDOKU"
echo "------------------------------------------------------------"
echo

instalar_pacote "ksudoku"

# ============================================================
# TERMINATOR
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                        TERMINATOR"
echo "------------------------------------------------------------"
echo

# Não usamos PPA aqui.
#
# PPA é específico do Ubuntu e pode causar problemas em
# Debian e outras distribuições baseadas em APT.

instalar_pacote "terminator"

# ============================================================
# SNAPD
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                           SNAPD"
echo "------------------------------------------------------------"
echo

instalar_pacote "snapd"

# ============================================================
# ATIVAR SNAPD
# ============================================================

if command -v snap >/dev/null 2>&1; then

  info "Ativando serviço snapd..."

  sudo systemctl enable --now snapd.socket 2>/dev/null || true

  sleep 3

  success "Snapd configurado."

else

  error "O comando snap não foi encontrado após instalar snapd."

  exit 1

fi

# ============================================================
# COOL RETRO TERM
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                      COOL RETRO TERM"
echo "------------------------------------------------------------"
echo

if snap list cool-retro-term >/dev/null 2>&1; then

  success "Cool Retro Term já está instalado."

else

  info "Instalando Cool Retro Term..."

  sudo snap install cool-retro-term --classic

  success "Cool Retro Term instalado."

fi

# ============================================================
# MARIO0
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                           MARIO0"
echo "------------------------------------------------------------"
echo

if snap list mari0 >/dev/null 2>&1; then

  success "Mari0 já está instalado."

else

  info "Instalando Mari0..."

  sudo snap install mari0

  success "Mari0 instalado."

fi

# ============================================================
# MARCAR ETAPA 2
# ============================================================

touch "$ETAPA2"

success "Etapa 2 concluída."

# ============================================================
# ETAPA 3
# ============================================================

title "ETAPA 3"

# ============================================================
# DEPENDÊNCIA DA ETAPA 2
# ============================================================

if [ ! -f "$ETAPA2" ]; then

  error "A Etapa 2 não foi concluída."
  error "A Etapa 3 não pode ser executada."

  exit 1

fi

success "Etapa 2 confirmada."

# ============================================================
# DESCRIÇÃO
# ============================================================

echo "A Etapa 3 irá instalar:"
echo
echo "  • Neofetch"
echo "  • JQ"
echo "  • Bat"
echo
echo "E adicionará ao ~/.zshrc:"
echo
echo '  alias cat="batcat"'
echo

# ============================================================
# VERIFICAÇÃO DOS PACOTES DA ETAPA 3
# ============================================================

info "Verificando pacotes da Etapa 3..."

PACOTES_ETAPA3=(
  "neofetch"
  "jq"
  "bat"
)

if ! verificar_pacotes_etapa "${PACOTES_ETAPA3[@]}"; then

  error "A Etapa 3 não pode ser executada."

  exit 1

fi

# ============================================================
# CONFIRMAÇÃO
# ============================================================

echo

read -p "Deseja continuar com a Etapa 3? [s/N]: " resposta

if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

  info "Etapa 3 cancelada."

  exit 0

fi

# ============================================================
# NEOFETCH
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                         NEOFETCH"
echo "------------------------------------------------------------"
echo

instalar_pacote "neofetch"

# ============================================================
# JQ
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                            JQ"
echo "------------------------------------------------------------"
echo

instalar_pacote "jq"

# ============================================================
# BAT
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                           BAT"
echo "------------------------------------------------------------"
echo

instalar_pacote "bat"

# ============================================================
# VERIFICAR BATCAT
# ============================================================

if command -v batcat >/dev/null 2>&1; then

  success "batcat encontrado."

else

  error "O pacote bat foi instalado, mas o comando batcat não foi encontrado."

  exit 1

fi

# ============================================================
# ALIAS
# ============================================================

echo
echo "------------------------------------------------------------"
echo "                    CONFIGURANDO ALIAS"
echo "------------------------------------------------------------"
echo

cp "$ZSHRC" "$HOME/.zshrc.etapa3.backup"

success "Backup do ~/.zshrc criado."

ALIAS_CAT='alias cat="batcat"'

if grep -Fqx "$ALIAS_CAT" "$ZSHRC"; then

  success 'Alias cat="batcat" já existe.'

else

  echo "" >>"$ZSHRC"

  echo "# ============================================================" >>"$ZSHRC"
  echo "# SISTEMAS OPERACIONAIS - BAT" >>"$ZSHRC"
  echo "# ============================================================" >>"$ZSHRC"

  echo "$ALIAS_CAT" >>"$ZSHRC"

  success 'Alias cat="batcat" adicionado ao ~/.zshrc.'

fi

# ============================================================
# VERIFICAÇÃO FINAL
# ============================================================

title "VERIFICAÇÃO FINAL DA ETAPA 3"

verificar_comando "neofetch"
verificar_comando "jq"
verificar_comando "batcat"

if grep -Fqx "$ALIAS_CAT" "$ZSHRC"; then

  success 'Alias cat="batcat" configurado.'

else

  warning 'Alias cat="batcat" não encontrado.'

fi

# ============================================================
# MARCAR ETAPA 3
# ============================================================

touch "$ETAPA3"

success "Etapa 3 marcada como concluída."

# ============================================================
# FINAL
# ============================================================

title "PREPARAÇÃO CONCLUÍDA"

success "Etapa 1 concluída."
success "Etapa 2 concluída."
success "Etapa 3 concluída."

echo
echo "============================================================"
echo "                    RECURSOS INSTALADOS"
echo "============================================================"
echo

echo "Etapa 1:"
echo "  ✓ Zsh"
echo "  ✓ Oh My Zsh"
echo "  ✓ Tema Agnoster"
echo "  ✓ Fontes Powerline"

echo
echo "Etapa 2:"
echo "  ✓ Emacs"
echo "  ✓ Figlet"
echo "  ✓ Figlet Fonts"
echo "  ✓ Lolcat"
echo "  ✓ Ksudoku"
echo "  ✓ Terminator"
echo "  ✓ Snapd"
echo "  ✓ Cool Retro Term"
echo "  ✓ Mari0"

echo
echo "Etapa 3:"
echo "  ✓ Neofetch"
echo "  ✓ JQ"
echo "  ✓ Bat"
echo '  ✓ Alias cat="batcat"'

echo
echo "============================================================"
echo "                       CONTROLE"
echo "============================================================"
echo

echo "Marcadores:"
echo
echo "  $ETAPA1"
echo "  $ETAPA2"
echo "  $ETAPA3"

echo
echo "Log:"
echo
echo "  $LOG_FILE"

echo
echo "Backups do ~/.zshrc:"
echo
echo "  $HOME/.zshrc.etapa1.backup"
echo "  $HOME/.zshrc.etapa2.backup"
echo "  $HOME/.zshrc.etapa3.backup"

echo
echo "============================================================"
echo "                         IMPORTANTE"
echo "============================================================"
echo

warning "O shell padrão foi alterado para Zsh."

echo
echo "Para aplicar as alterações imediatamente:"
echo
echo "    source ~/.zshrc"
echo
echo "ou feche a sessão e entre novamente."

echo
success "Todas as etapas foram concluídas!"
echo

exit 0

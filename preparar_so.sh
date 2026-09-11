#!/bin/bash

# ============================================================
# PREPARAÇÃO DO AMBIENTE - SISTEMAS OPERACIONAIS
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
NC='\033[0m'

# ============================================================
# FUNÇÕES
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
# TRATAMENTO DE ERROS
# ============================================================

trap 'error "Ocorreu um erro na linha $LINENO. A instalação foi interrompida."' ERR

# ============================================================
# VERIFICAR ROOT
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
# VERIFICAR SISTEMA OPERACIONAL
# ============================================================

if [ ! -f /etc/os-release ]; then

  error "Não foi possível identificar o sistema operacional."

  exit 1

fi

source /etc/os-release

echo
echo "============================================================"
echo "     PREPARAÇÃO DO AMBIENTE - SISTEMAS OPERACIONAIS"
echo "============================================================"
echo

echo "Sistema:       $PRETTY_NAME"
echo "Arquitetura:   $(dpkg --print-architecture)"
echo "Kernel:        $(uname -r)"
echo "Usuário:       $USER"
echo

# ============================================================
# VERIFICAR UBUNTU
# ============================================================

if [ "$ID" != "ubuntu" ]; then

  warning "Este script foi desenvolvido para Ubuntu."
  warning "Sistema detectado: $PRETTY_NAME"

  echo

  read -p "Deseja continuar mesmo assim? [s/N]: " resposta

  if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

    info "Instalação cancelada."

    exit 0

  fi

fi

# ============================================================
# VERIFICAR APT
# ============================================================

if ! command -v apt >/dev/null 2>&1; then

  error "O gerenciador de pacotes APT não foi encontrado."

  exit 1

fi

success "APT encontrado."

# ============================================================
# LOG
# ============================================================

LOG_FILE="$HOME/preparacao_sistemas_operacionais.log"

exec > >(tee -a "$LOG_FILE") 2>&1

info "Log da instalação:"
echo "$LOG_FILE"

# ============================================================
# FUNÇÃO PARA INSTALAR PACOTES
# ============================================================

instalar_pacote() {

  PACOTE="$1"

  if dpkg -s "$PACOTE" >/dev/null 2>&1; then

    success "$PACOTE já está instalado."

  else

    info "Instalando $PACOTE..."

    sudo apt install -y "$PACOTE"

    success "$PACOTE instalado."

  fi

}

# ============================================================
# ETAPA 1
# ============================================================

ETAPA1="$HOME/.sistemas_operacionais_etapa1"

echo
echo "============================================================"
echo "                         ETAPA 1"
echo "============================================================"
echo

info "Verificando dependências da Etapa 1..."

sudo apt update

success "Repositórios atualizados."

# ------------------------------------------------------------
# INSTALAÇÃO
# ------------------------------------------------------------

instalar_pacote "zsh"
instalar_pacote "curl"
instalar_pacote "git"
instalar_pacote "fonts-powerline"
instalar_pacote "nano"

# ------------------------------------------------------------
# ZSH
# ------------------------------------------------------------

ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then

  error "Zsh não foi encontrado."

  exit 1

fi

success "Zsh encontrado em $ZSH_PATH"

# ------------------------------------------------------------
# OH MY ZSH
# ------------------------------------------------------------

if [ -d "$HOME/.oh-my-zsh" ]; then

  success "Oh My Zsh já está instalado."

else

  info "Instalando Oh My Zsh..."

  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  success "Oh My Zsh instalado."

fi

# ------------------------------------------------------------
# ZSHRC
# ------------------------------------------------------------

ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then

  cp "$ZSHRC" "$HOME/.zshrc.etapa1.backup"

  success "Backup do ~/.zshrc criado."

else

  touch "$ZSHRC"

  success "~/.zshrc criado."

fi

# ------------------------------------------------------------
# AGNOSTER
# ------------------------------------------------------------

info "Configurando tema Agnoster..."

if grep -q '^ZSH_THEME=' "$ZSHRC"; then

  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' "$ZSHRC"

else

  echo 'ZSH_THEME="agnoster"' >>"$ZSHRC"

fi

success "Tema Agnoster configurado."

# ------------------------------------------------------------
# ZSH COMO SHELL PADRÃO
# ------------------------------------------------------------

SHELL_ATUAL="$(getent passwd "$USER" | cut -d: -f7)"

if [ "$SHELL_ATUAL" = "$ZSH_PATH" ]; then

  success "Zsh já é o shell padrão."

else

  info "Configurando Zsh como shell padrão..."

  chsh -s "$ZSH_PATH"

  success "Zsh definido como shell padrão."

fi

# ------------------------------------------------------------
# MARCADOR ETAPA 1
# ------------------------------------------------------------

touch "$ETAPA1"

success "Etapa 1 concluída."

# ============================================================
# ETAPA 2
# ============================================================

ETAPA2="$HOME/.sistemas_operacionais_etapa2"

echo
echo "============================================================"
echo "                         ETAPA 2"
echo "============================================================"
echo

# ------------------------------------------------------------
# VERIFICAR ETAPA 1
# ------------------------------------------------------------

if [ ! -f "$ETAPA1" ]; then

  error "A Etapa 1 não foi concluída."

  echo
  echo "A Etapa 2 não pode ser executada."

  exit 1

fi

success "Etapa 1 confirmada."

# ------------------------------------------------------------
# CONFIRMAÇÃO
# ------------------------------------------------------------

echo
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

read -p "Deseja continuar com a Etapa 2? [s/N]: " resposta

if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

  info "Etapa 2 cancelada."

  exit 0

fi

# ------------------------------------------------------------
# EMACS
# ------------------------------------------------------------

instalar_pacote "emacs"

# ------------------------------------------------------------
# LOLCAT
# ------------------------------------------------------------

instalar_pacote "lolcat"

# ------------------------------------------------------------
# FIGLET
# ------------------------------------------------------------

FIGLET_FILE="figlet_2.2.5-3_amd64.deb"
FIGLET_URL="http://archive.ubuntu.com/ubuntu/pool/universe/f/figlet/$FIGLET_FILE"

if command -v figlet >/dev/null 2>&1; then

  success "Figlet já está instalado."

else

  cd "$HOME"

  if [ ! -f "$HOME/$FIGLET_FILE" ]; then

    info "Baixando Figlet..."

    wget "$FIGLET_URL"

  else

    success "Pacote Figlet já foi baixado."

  fi

  info "Instalando Figlet..."

  sudo dpkg -i "$HOME/$FIGLET_FILE"

  success "Figlet instalado."

fi

# ------------------------------------------------------------
# FIGLET FONTS
# ------------------------------------------------------------

FIGLET_FONTS="$HOME/figlet-fonts"

if [ -d "$FIGLET_FONTS/.git" ]; then

  success "Figlet Fonts já está instalado."

else

  info "Clonando Figlet Fonts..."

  git clone \
    https://github.com/xero/figlet-fonts.git \
    "$FIGLET_FONTS"

  success "Figlet Fonts instalado."

fi

# ------------------------------------------------------------
# ZSHRC - FIGLET + LOLCAT
# ------------------------------------------------------------

cp "$ZSHRC" "$HOME/.zshrc.etapa2.backup"

success "Backup do ~/.zshrc criado."

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

# ------------------------------------------------------------
# TESTAR FONTE 3D
# ------------------------------------------------------------

if [ -f "$FIGLET_FONTS/3d.flf" ]; then

  success "Fonte 3d encontrada."

else

  warning "Fonte 3d não encontrada."

fi

# ------------------------------------------------------------
# KSUDOKU
# ------------------------------------------------------------

instalar_pacote "ksudoku"

# ------------------------------------------------------------
# TERMINATOR
# ------------------------------------------------------------

instalar_pacote "software-properties-common"

if grep -Rqs "ppa.launchpadcontent.net/gnome-terminator" \
  /etc/apt/sources.list \
  /etc/apt/sources.list.d/ 2>/dev/null; then

  success "PPA do Terminator já está configurado."

else

  info "Adicionando PPA do Terminator..."

  sudo add-apt-repository -y ppa:gnome-terminator

  sudo apt update

  success "PPA do Terminator adicionado."

fi

instalar_pacote "terminator"

# ------------------------------------------------------------
# SNAPD
# ------------------------------------------------------------

instalar_pacote "snapd"

info "Ativando serviço snapd..."

sudo systemctl enable --now snapd.socket 2>/dev/null || true

sleep 3

success "Snapd configurado."

# ------------------------------------------------------------
# COOL RETRO TERM
# ------------------------------------------------------------

if snap list cool-retro-term >/dev/null 2>&1; then

  success "Cool Retro Term já está instalado."

else

  info "Instalando Cool Retro Term..."

  sudo snap install cool-retro-term --classic

  success "Cool Retro Term instalado."

fi

# ------------------------------------------------------------
# MARI0
# ------------------------------------------------------------

if snap list mari0 >/dev/null 2>&1; then

  success "Mari0 já está instalado."

else

  info "Instalando Mari0..."

  sudo snap install mari0

  success "Mari0 instalado."

fi

# ------------------------------------------------------------
# MARCADOR ETAPA 2
# ------------------------------------------------------------

touch "$ETAPA2"

success "Etapa 2 concluída."

# ============================================================
# ETAPA 3
# ============================================================

ETAPA3="$HOME/.sistemas_operacionais_etapa3"

echo
echo "============================================================"
echo "                         ETAPA 3"
echo "============================================================"
echo

# ------------------------------------------------------------
# VERIFICAR ETAPA 2
# ------------------------------------------------------------

if [ ! -f "$ETAPA2" ]; then

  error "A Etapa 2 não foi concluída."

  echo
  echo "A Etapa 3 não pode ser executada."
  echo

  exit 1

fi

success "Etapa 2 confirmada."

# ------------------------------------------------------------
# CONFIRMAÇÃO
# ------------------------------------------------------------

echo
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

read -p "Deseja continuar com a Etapa 3? [s/N]: " resposta

if [[ ! "$resposta" =~ ^[Ss]$ ]]; then

  info "Etapa 3 cancelada."

  exit 0

fi

# ------------------------------------------------------------
# INSTALAR NEOFETCH
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "                        NEOFETCH"
echo "------------------------------------------------------------"
echo

instalar_pacote "neofetch"

# ------------------------------------------------------------
# INSTALAR JQ
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "                           JQ"
echo "------------------------------------------------------------"
echo

instalar_pacote "jq"

# ------------------------------------------------------------
# INSTALAR BAT
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "                           BAT"
echo "------------------------------------------------------------"
echo

instalar_pacote "bat"

# ------------------------------------------------------------
# VERIFICAR BATCAT
# ------------------------------------------------------------

if command -v batcat >/dev/null 2>&1; then

  success "batcat encontrado."

else

  error "bat foi instalado, mas o comando batcat não foi encontrado."

  exit 1

fi

# ------------------------------------------------------------
# CONFIGURAR ALIAS CAT
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "                    CONFIGURANDO ALIAS"
echo "------------------------------------------------------------"
echo

# Backup antes de modificar

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
# VERIFICAÇÃO DA ETAPA 3
# ============================================================

echo
echo "============================================================"
echo "                    VERIFICAÇÃO ETAPA 3"
echo "============================================================"
echo

if command -v neofetch >/dev/null 2>&1; then
  success "Neofetch"
else
  warning "Neofetch não encontrado."
fi

if command -v jq >/dev/null 2>&1; then
  success "JQ"
else
  warning "JQ não encontrado."
fi

if command -v batcat >/dev/null 2>&1; then
  success "Bat"
else
  warning "Bat não encontrado."
fi

if grep -Fqx "$ALIAS_CAT" "$ZSHRC"; then
  success 'Alias cat="batcat"'
else
  warning 'Alias cat="batcat" não encontrado.'
fi

# ============================================================
# MARCADOR ETAPA 3
# ============================================================

touch "$ETAPA3"

success "Etapa 3 marcada como concluída."

# ============================================================
# FINALIZAÇÃO
# ============================================================

echo
echo "============================================================"
echo "              PREPARAÇÃO CONCLUÍDA"
echo "============================================================"
echo

success "Etapa 1 concluída."
success "Etapa 2 concluída."
success "Etapa 3 concluída."

echo
echo "Novos recursos da Etapa 3:"
echo
echo "  ✓ Neofetch"
echo "  ✓ JQ"
echo "  ✓ Bat"
echo '  ✓ Alias cat="batcat"'
echo

echo "Arquivos de controle:"
echo
echo "  $ETAPA1"
echo "  $ETAPA2"
echo "  $ETAPA3"
echo

echo "Log:"
echo
echo "  $LOG_FILE"
echo

warning "Se o terminal já estava aberto durante a instalação,"
warning "execute:"
echo
echo "    source ~/.zshrc"
echo
echo "ou feche e abra o terminal novamente."
echo

success "Todas as etapas foram concluídas!"
echo

exit 0

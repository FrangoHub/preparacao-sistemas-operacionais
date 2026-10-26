# Preparação de Sistemas Operacionais

Scripts para automatizar a preparação de computadores **Ubuntu Linux** (e derivados Debian/Ubuntu) utilizados nas aulas da disciplina de **Sistemas Operacionais** na UVV.

O objetivo é reunir em poucos comandos todas as instalações e configurações feitas durante as aulas, evitando que o aluno precise executar dezenas de comandos manualmente.

O projeto cresceu ao longo do tempo e hoje possui **4 scripts** com escopos diferentes. Este README explica **o que cada um faz**, **como instalar** e **em que ele difere dos demais**, para que você escolha o mais adequado ao seu caso.

---

## Sumário

- [Visão geral dos scripts](#visão-geral-dos-scripts)
- [O que os scripts instalam](#o-que-os-scripts-instalam)
- [Script 1 — `instalar.sh`](#script-1--instalarsh-base-3-etapas)
- [Script 2 — `preparar_so.sh`](#script-2--preparar_sosh-4-etapas-ghostty-via-snap)
- [Script 3 — `instalarghostty.deb.sh`](#script-3--instalarghosttydebsh-4-etapas-ghostty-via-deb)
- [Script 4 — `preparacao_sistemas_operacionais_ghostty_personalizado.sh`](#script-4--preparacao_sistemas_operacionais_ghostty_personalizadosh-)
- [Comparação lado a lado](#comparação-lado-a-lado)
- [Qual script escolher?](#qual-script-escolher)
- [Requisitos comuns](#requisitos-comuns-a-todos-os-scripts)
- [Execução correta](#execução-correta--o-que-fazer-e-o-que-não-fazer)
- [Solução de problemas](#solução-de-problemas)
- [Logs e marcadores](#logs-e-marcadores)
- [Histórico](#histórico)
- [Contexto](#contexto)
- [Licença](#licença)

---

## Visão geral dos scripts

| # | Arquivo | Etapas | Ghostty | Personalização do Ghostty | Recarga automática | Pasta da imagem |
|---|---------|--------|---------|---------------------------|--------------------|-----------------|
| 1 | `instalar.sh` | 1, 2, 3 | ❌ | ❌ | ❌ | — |
| 2 | `preparar_so.sh` | 1, 2, 3, 4 | Snap | ❌ | ❌ | — |
| 3 | `instalarghostty.deb.sh` | 1, 2, 3, 4 | `.deb` | ❌ | ❌ | — |
| 4 | `preparacao_sistemas_operacionais_ghostty_personalizado.sh` | 1, 2, 3, 4 | `.deb` | ✅ | ✅ | `~/.imagemghostty/` |

---

## O que os scripts instalam

### Etapa 1 — Zsh + Oh My Zsh

- **Zsh**, **Oh My Zsh**, **fonts-powerline**, **curl**, **git**, **nano**
- Tema **Agnoster**
- Backup do `.zshrc`
- Zsh como shell padrão (via `chsh`)

### Etapa 2 — Aplicativos, Snap e Neovim

- **Emacs**, **Figlet**, **Lolcat**, **Ksudoku**, **Terminator**, **Snapd**
- **figlet-fonts** (clonado do GitHub)
- Banner **Figlet + Lolcat** no `.zshrc`
- **Snapd** habilitado via `systemctl enable --now snapd.socket`
- Tratamento especial do bloqueio do Snap no **Linux Mint** (`/etc/apt/preferences.d/nosnap.pref`)
- **Neovim** (Snap, `--classic`)
- **Kickstart.nvim** (clonado de `nvim-lua/kickstart.nvim`)
- **cool-retro-term** (Snap, `--classic`)
- **mari0** (Snap)

### Etapa 3 — Ferramentas finais

- **Neofetch**, **jq**, **bat**
- Alias `cat="batcat"` no `.zshrc` (o `bat` no Ubuntu chama-se `batcat`)

### Etapa 4 — Ghostty + Fish + Tide

- **Nerd Font Meslo** (baixada de `ryanoasis/nerd-fonts` e instalada em `~/.local/share/fonts/NerdFonts/`)
- **Ghostty** (Snap ou `.deb`, dependendo do script)
- **Fish**, **Fisher** e **Tide v6**
- Função `cat` → `batcat` no Fish
- (Somente no script 4) **Personalização do Ghostty**: imagem de fundo, JetBrains Mono, blur, opacidade e recarga automática

### Escolhas finais (scripts 2, 3 e 4)

- **Terminal gráfico** (padrão do sistema, Terminator ou Ghostty) — configurado via `gsettings`, `xfconf-query` e `update-alternatives`
- **Shell padrão** (Zsh ou Fish) — configurado via `chsh`

---

## Script 1 — `instalar.sh` (Base, 3 etapas)

### O que faz

Instala apenas o **núcleo** do ambiente da disciplina, **sem** terminal gráfico extra e **sem** Fish:

- Etapa 1, 2 e 3 completas (ver [O que os scripts instalam](#o-que-os-scripts-instalam))
- **Não** pergunta no final qual terminal/shell usar — apenas deixa o Zsh como padrão

### Diferenças em relação aos outros scripts

- **Não instala Ghostty** nem qualquer terminal gráfico moderno além do Terminator
- **Não instala Fish** nem Tide
- **Não personaliza** o terminal (sem imagem de fundo, sem Nerd Font)
- **Não pergunta** no final qual terminal/shell usar — apenas deixa o Zsh como padrão
- Log em **`~/preparacao_sistemas_operacionais.log`** (no home, **não** em `/var/log`)
- Usa **arrays Bash** para rastrear pacotes instalados / já instalados / que falharam e gera um **resumo final detalhado**
- **Não cria** diretório em `/var/log`
- **Não usa marcadores ocultos** para controlar etapas já executadas (sempre tenta instalar/verificar de novo)
- **Não valida** se está rodando via `sh` (o script confia que você vai usar `bash`)

### Requisitos

- Ubuntu, Debian, Linux Mint ou Pop!_OS
- Conexão com a internet
- Usuário com acesso a `sudo` (o script **não** deve ser executado como root)
- `curl` disponível (para Oh My Zsh)

### Instalação

```bash
git clone https://github.com/FrangoHub/preparacao-sistemas-operacionais.git
cd preparacao-sistemas-operacionais

chmod +x instalar.sh

./instalar.sh
```

Ou diretamente pela internet:

```bash
curl -fsSL https://raw.githubusercontent.com/FrangoHub/preparacao-sistemas-operacionais/main/instalar.sh | bash
```

---

## Script 2 — `preparar_so.sh` (4 etapas, Ghostty via Snap)

### O que faz

Tudo o que o `instalar.sh` faz, **mais**:

- **Etapa 4** — instala a **Nerd Font Meslo**, o **Ghostty via Snap** (`snap install ghostty --classic`), o **Fish**, o **Fisher** e o **Tide**
- Configura a função `cat` → `batcat` no Fish
- Pergunta, ao final, se você quer reconfigurar o **Tide** (`tide configure`)
- Pergunta qual **terminal gráfico** usar (padrão do sistema, Terminator ou Ghostty)
- Pergunta qual **shell** usar (Zsh ou Fish) e altera via `chsh`

### Diferenças em relação aos outros scripts

- **Ghostty é instalado via Snap**, não via `.deb`. Mais simples, porém a versão Snap pode ficar **desatualizada** e **não é a forma recomendada** pelos mantenedores do Ghostty
- **Não personaliza** o Ghostty (sem imagem de fundo, sem JetBrains Mono, sem `config`)
- **Não recarrega** o Ghostty automaticamente (não envia `SIGUSR2`)
- Log em **`/var/log/preparacao_sistemas_operacionais/`** (diretório do sistema, não no home)
- Usa **marcadores ocultos no home** (`~/.sistemas_operacionais_etapaN`) para saber se cada etapa já foi executada
- **Pergunta confirmação antes de cada etapa** e, se a etapa já foi concluída, pergunta se quer reexecutar
- **Não tem resumo final** com lista de pacotes
- **Não tem** a mensagem amigável “não execute como root” (sai com erro se for root)

### Requisitos

- Ubuntu, Debian, Linux Mint ou Pop!_OS
- Conexão com a internet
- `sudo` e `snap` funcionais (a Etapa 2 instala o snapd e habilita o socket)

### Instalação

```bash
git clone https://github.com/FrangoHub/preparacao-sistemas-operacionais.git
cd preparacao-sistemas-operacionais

chmod +x preparar_so.sh

bash preparar_so.sh
```

> **Sempre execute com `bash`** — nunca com `sh`.

---

## Script 3 — `instalarghostty.deb.sh` (4 etapas, Ghostty via `.deb`)

### O que faz

Tudo o que o `preparar_so.sh` faz, mas trocando o Ghostty Snap por **Ghostty via `.deb`**:

- **Ghostty via `.deb`** (repositório `mkasberg/ghostty-ubuntu`)
- **Remove a versão Snap do Ghostty**, se existir, para evitar conflito
- **Não personaliza** o Ghostty (sem imagem, sem JetBrains Mono) — o objetivo é apenas instalar o terminal gráfico pela via recomendada

### Diferenças em relação aos outros scripts

- **Ghostty via `.deb`** em vez de Snap — versão mais atualizada e alinhada com o projeto oficial
- **Remove** uma eventual instalação Snap antiga do Ghostty antes de instalar
- **Sem personalização do Ghostty** (ao contrário do `preparacao_sistemas_operacionais_ghostty_personalizado.sh`)
- **Sem recarga automática** do Ghostty (não envia `SIGUSR2`)
- Log em **`/var/log/preparacao_sistemas_operacionais/`**
- Usa **marcadores ocultos no home** e **confirmação antes de cada etapa**
- **Inclui todas as correções de sintaxe** que faltavam na versão antiga do projeto (ver [Histórico](#histórico))

### Requisitos

- Ubuntu, Debian, Linux Mint ou Pop!_OS
- Conexão com a internet (baixa um script do GitHub para instalar o `.deb`)
- `sudo`, `dpkg`, `apt-get`

### Instalação

```bash
git clone https://github.com/FrangoHub/preparacao-sistemas-operacionais.git
cd preparacao-sistemas-operacionais

chmod +x instalarghostty.deb.sh

bash instalarghostty.deb.sh
```

---

## Script 4 — `preparacao_sistemas_operacionais_ghostty_personalizado.sh` ⭐

### O que faz

Tudo o que o `instalarghostty.deb.sh` faz, **mais**:

- **Personaliza o Ghostty** com imagem de fundo, fonte **JetBrains Mono**, blur, opacidade e outras opções
- **Imagem de fundo em pasta oculta `~/.imagemghostty/`** — não polui `~/Imagens/` nem aparece no gerenciador de arquivos
- **Recarrega o Ghostty automaticamente** após salvar a configuração, enviando `SIGUSR2` (`pkill -SIGUSR2 -x ghostty`)
- Verifica se o Ghostty está em execução com `pgrep -x ghostty` antes de enviar o sinal
- Se o Ghostty **não estiver rodando**, apenas informa que a configuração será aplicada na próxima abertura
- Mantém um **bloco delimitado** no `~/.config/ghostty/config` (`# BEGIN PREPARACAO_SO_GHOSTTY_THEME` … `# END …`) para que futuras execuções **atualizem** a personalização sem duplicar nem apagar configurações do usuário

### Diferenças em relação aos outros scripts

| Item | `instalarghostty.deb.sh` | `preparacao_..._personalizado.sh` |
|------|--------------------------|-----------------------------------|
| Ghostty `.deb` | ✅ | ✅ |
| Personalização (imagem + fonte) | ❌ | ✅ |
| Pasta da imagem | — | `~/.imagemghostty/` (oculta) |
| Recarga automática | ❌ | ✅ via `SIGUSR2` |
| Atualização idempotente do `config` | — | ✅ bloco gerenciado |
| Feedback após salvar | “Feche e abra o Ghostty” | “Sinal de recarga enviado ao Ghostty” |

Essa é a **versão recomendada** para uso em produção: todas as correções aplicadas, personalização completa e aplicação imediata das mudanças **sem intervenção manual**.

### Requisitos

- Ubuntu, Debian, Linux Mint ou Pop!_OS
- Conexão com a internet
- `sudo`, `dpkg`, `apt-get`, `curl`, `awk`, `pgrep`/`pkill` (todos presentes por padrão em Ubuntu/Debian)
- O **Ghostty ≥ 1.0** deve estar instalado (é instalado por este script)

### Instalação

```bash
git clone https://github.com/FrangoHub/preparacao-sistemas-operacionais.git
cd preparacao-sistemas-operacionais

chmod +x preparacao_sistemas_operacionais_ghostty_personalizado.sh

bash preparacao_sistemas_operacionais_ghostty_personalizado.sh
```

Ou diretamente pela internet (recomendado apenas se você confia na origem):

```bash
curl -fsSL https://raw.githubusercontent.com/FrangoHub/preparacao-sistemas-operacionais/main/preparacao_sistemas_operacionais_ghostty_personalizado.sh | bash
```

### Observações

- A pasta `~/.imagemghostty/` é **criada automaticamente** na primeira execução da personalização
- A recarga via `SIGUSR2` funciona no Ghostty ≥ 1.0; em versões muito antigas, o comportamento pode variar
- Para limpar a personalização depois: `rm -rf ~/.imagemghostty ~/.config/ghostty/config`

---

## Comparação lado a lado

| Recurso | `instalar.sh` | `preparar_so.sh` | `instalarghostty.deb.sh` | `preparacao_..._personalizado.sh` |
|---------|:-:|:-:|:-:|:-:|
| Zsh + Oh My Zsh | ✅ | ✅ | ✅ | ✅ |
| Emacs, Figlet, Lolcat, Terminator | ✅ | ✅ | ✅ | ✅ |
| Neofetch, jq, bat | ✅ | ✅ | ✅ | ✅ |
| Neovim + Kickstart.nvim | ❌ | ✅ | ✅ | ✅ |
| cool-retro-term + mari0 | ✅ | ✅ | ✅ | ✅ |
| Nerd Font Meslo | ❌ | ✅ | ✅ | ✅ |
| Fish + Fisher + Tide | ❌ | ✅ | ✅ | ✅ |
| Ghostty | ❌ | Snap | `.deb` | `.deb` |
| Personalização do Ghostty (imagem + fonte) | ❌ | ❌ | ❌ | ✅ |
| Pasta oculta para a imagem | — | — | — | ✅ |
| Recarga automática do Ghostty (`SIGUSR2`) | — | ❌ | ❌ | ✅ |
| Escolha interativa de terminal e shell | ❌ | ✅ | ✅ | ✅ |
| Confirmação antes de cada etapa | ✅ (parcial) | ✅ | ✅ | ✅ |
| Marcadores de etapa no home | ❌ | ✅ | ✅ | ✅ |
| Arrays com resumo final | ✅ | ❌ | ❌ | ❌ |
| Log em `/var/log/...` | ❌ | ✅ | ✅ | ✅ |
| Log em `~/...` | ✅ | ❌ | ❌ | ❌ |
| Tratamento do bloqueio do Snap no Linux Mint | ✅ | ✅ | ✅ | ✅ |

---

## Qual script escolher?

- **Quero apenas o básico da disciplina (Zsh, apps, ferramentas), sem terminal gráfico extra** → **`instalar.sh`**
- **Quero o ambiente completo, mas prefiro Snap por simplicidade** → **`preparar_so.sh`**
- **Quero o ambiente completo com Ghostty via `.deb` (forma recomendada), mas sem personalização** → **`instalarghostty.deb.sh`**
- **Quero o ambiente completo, com Ghostty via `.deb`, imagem em pasta oculta e recarga automática** → **`preparacao_sistemas_operacionais_ghostty_personalizado.sh`** ⭐

---

## Requisitos comuns a todos os scripts

- **Distribuição**: Ubuntu, Debian, Linux Mint ou Pop!_OS (baseadas em APT/DPKG)
- **Conexão com a internet** durante a execução
- **Usuário com acesso ao `sudo`** — os scripts **não** devem ser executados como `root`
- **Arquitetura compatível** com os pacotes (amd64, arm64, etc.)
- **Terminal interativo** disponível (`/dev/tty` acessível) para as confirmações

---

## Execução correta — o que fazer e o que NÃO fazer

✅ **Formas corretas:**

```bash
bash preparacao_sistemas_operacionais_ghostty_personalizado.sh
./preparacao_sistemas_operacionais_ghostty_personalizado.sh        # se tiver chmod +x
```

❌ **Formas incorretas (causam `success: not found` e `info` do Texinfo sendo chamado):**

```bash
sh preparacao_sistemas_operacionais_ghostty_personalizado.sh       # NUNCA use sh
. preparacao_sistemas_operacionais_ghostty_personalizado.sh        # não use source
```

Se aparecer `success: not found` ou `info: Não existe o item ... de menu no nodo '(dir)Top'`, é sinal de que o script está sendo interpretado pelo **`dash`** (`/bin/sh`), e não pelo Bash. Corrija com:

```bash
# Garanta o shebang
sed -i '1s|.*|#!/usr/bin/env bash|' preparacao_sistemas_operacionais_ghostty_personalizado.sh

# Remova BOM, se houver
sed -i '1s/^\xEF\xBB\xBF//' preparacao_sistemas_operacionais_ghostty_personalizado.sh

# Remova CRLF, se houver
sed -i 's/\r$//' preparacao_sistemas_operacionais_ghostty_personalizado.sh

# Permissão de execução
chmod +x preparacao_sistemas_operacionais_ghostty_personalizado.sh

# Valide a sintaxe
bash -n preparacao_sistemas_operacionais_ghostty_personalizado.sh

# Execute
bash preparacao_sistemas_operacionais_ghostty_personalizado.sh
```

---

## Solução de problemas

### `success: not found`

**Causa:** o script está sendo executado com `sh`/`dash` em vez de `bash`, ou o shebang foi perdido.

**Correção:** rode com `bash script.sh` e garanta que a primeira linha do arquivo é `#!/usr/bin/env bash`.

### `info: Não existe o item '...' de menu no nodo '(dir)Top'`

**Causa:** mesma do erro anterior. Sem a função `info` definida, o Bash cai no binário `/usr/bin/info` (o leitor Texinfo) e passa a mensagem como argumento.

**Correção:** rode com `bash script.sh`.

### `Permission denied`

**Causa:** o arquivo não tem permissão de execução.

**Correção:** `chmod +x script.sh` ou execute com `bash script.sh`.

### `Não foi possível autenticar com sudo`

**Causa:** o usuário não tem `sudo` ou a senha foi digitada errada.

**Correção:** verifique se o usuário pertence ao grupo `sudo` (`groups`) e se o `sudo -v` funciona isoladamente.

### `Ghostty .deb não pôde ser verificado`

**Causa:** o instalador do `mkasberg/ghostty-ubuntu` terminou mas o pacote `ghostty` não aparece no `dpkg`. Pode ocorrer em versões muito antigas do Ubuntu ou em arquiteturas não suportadas.

**Correção:** instale manualmente seguindo o [repositório oficial](https://github.com/mkasberg/ghostty-ubuntu).

### `A Meslo não foi detectada pelo fc-list`

**Causa:** a fonte foi baixada mas o cache do fontconfig não foi atualizado.

**Correção:** rode `fc-cache -f` e verifique com `fc-list | grep -i meslo`.

### `Sinal de recarga enviado ao Ghostty` mas a personalização não aparece

**Causa:** algumas opções (ex.: `background-opacity` no macOS) exigem reiniciar o Ghostty completamente. No Linux a maioria é recarregável, mas vale testar.

**Correção:** feche e abra o Ghostty manualmente.

---

## Logs e marcadores

| Script | Local do log |
|--------|--------------|
| `instalar.sh` | `~/preparacao_sistemas_operacionais.log` |
| `preparar_so.sh` | `/var/log/preparacao_sistemas_operacionais/AAAA-MM-DD_HH-MM-SS.log` |
| `instalarghostty.deb.sh` | `/var/log/preparacao_sistemas_operacionais/AAAA-MM-DD_HH-MM-SS.log` |
| `preparacao_sistemas_operacionais_ghostty_personalizado.sh` | `/var/log/preparacao_sistemas_operacionais/AAAA-MM-DD_HH-MM-SS.log` |

Nos scripts 2, 3 e 4, cada execução gera **um arquivo novo** com data/hora no nome, facilitando auditoria.

### Marcadores de etapa (scripts 2, 3 e 4)

Cada etapa concluída cria um arquivo oculto no home:

```text
~/.sistemas_operacionais_etapa1
~/.sistemas_operacionais_etapa2
~/.sistemas_operacionais_etapa3
~/.sistemas_operacionais_etapa4
```

Na próxima execução, o script pergunta se você quer **reexecutar** a etapa. Para forçar tudo do zero:

```bash
rm ~/.sistemas_operacionais_etapa*
```

### Limpar a personalização do Ghostty

```bash
rm -rf ~/.imagemghostty ~/.config/ghostty/config
```

---

## Histórico

- Uma **versão anterior** do `instalarghostty.deb.sh` continha erros de sintaxe:
  - `else` órfão e `fi` extra na Etapa 2 (bloco do Neovim/Kickstart)
  - Bloco do Kickstart.nvim **duplicado**
  - `"$https://..."` na URL da imagem (variável `$https` inexistente)
  - Padrões `case` com multibyte (`[ãÃ]`), não portáveis

  Ela foi **substituída** pela versão atual, que incorpora todas as correções e é a que este README documenta.

- O `preparacao_sistemas_operacionais_ghostty_personalizado.sh` é a evolução direta do `instalarghostty.deb.sh`, com:
  - Personalização do Ghostty (imagem + fonte)
  - Imagem em pasta oculta `~/.imagemghostty/`
  - Recarga automática via `SIGUSR2`

---

## Contexto

Este projeto foi desenvolvido como parte das atividades da disciplina de **Sistemas Operacionais** da UVV, com o objetivo de automatizar a configuração dos ambientes virtuais Linux utilizados pelos alunos em aula. Ao longo do tempo, os scripts ganharam versões com escopos crescentes, cujas diferenças estão documentadas acima.

---

## Licença

Este projeto é disponibilizado para fins educacionais.

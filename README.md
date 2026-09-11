# Preparação de Sistemas Operacionais

Script desenvolvido para automatizar a preparação de computadores **Ubuntu Linux** utilizados nas aulas da disciplina de **Sistemas Operacionais**.

O objetivo é reunir em um único script as instalações e configurações realizadas durante as aulas, facilitando a preparação dos computadores dos alunos e evitando a necessidade de executar diversos comandos manualmente.

## O que o script faz

O script é dividido em etapas, permitindo que cada conjunto de ferramentas seja instalado na ordem correta.

### Etapa 1 — Zsh e Oh My Zsh

* Instala o **Zsh**
* Instala o **Oh My Zsh**
* Instala fontes **Powerline**
* Configura o tema **Agnoster**
* Define o Zsh como shell padrão
* Realiza backup do `.zshrc`

### Etapa 2 — Ferramentas e aplicativos

* Emacs
* Figlet
* Figlet Fonts
* Lolcat
* Ksudoku
* Terminator
* Snapd
* Cool Retro Term
* Mari0

Também adiciona uma mensagem personalizada com **Figlet + Lolcat** ao `.zshrc`.

### Etapa 3 — Ferramentas do terminal

* Neofetch
* JQ
* Bat
* Alias `cat="batcat"`

## Controle das etapas

Cada etapa possui um arquivo de controle no diretório pessoal do usuário:

```text
~/.sistemas_operacionais_etapa1
~/.sistemas_operacionais_etapa2
~/.sistemas_operacionais_etapa3
```

Isso permite verificar quais etapas já foram concluídas e impede que uma etapa posterior seja executada antes da anterior.

## Requisitos

* Ubuntu Linux
* Conexão com a internet
* Usuário com acesso ao `sudo`
* Arquitetura compatível com os pacotes utilizados

> O script não deve ser executado como `root`, pois ele utiliza o `sudo` quando necessário.

## Instalação

Clone o repositório:

```bash
git clone https://github.com/FrangoHub/preparacao-sistemas-operacionais.git
```

Entre no diretório:

```bash
cd preparacao-sistemas-operacionais
```

Dê permissão de execução ao script:

```bash
chmod +x preparar_so.sh
```

Execute:

```bash
./preparar_so.sh
```

Durante a execução, o script solicitará confirmação antes de iniciar as etapas que possuem instalações adicionais.

## Execução diretamente pela internet

Também é possível baixar e executar o script diretamente do GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/FrangoHub/preparacao-sistemas-operacionais/main/preparar_so.sh | bash
```

## Logs

As operações realizadas pelo script são registradas em:

```text
~/preparacao_sistemas_operacionais.log
```

Esse arquivo pode ser utilizado para verificar o que foi executado e identificar possíveis erros durante a instalação.

## Contexto

Este projeto foi desenvolvido como parte das atividades da disciplina de **Sistemas Operacionais**, com o objetivo de automatizar a configuração dos ambientes Linux utilizados pelos alunos.

## Licença

Este projeto é disponibilizado para fins educacionais.

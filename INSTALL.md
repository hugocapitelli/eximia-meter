# exímIA Meter — Guia de Instalação

Monitor de uso do Claude Code para macOS. Mostra consumo de tokens semanal, por sessão e por projeto direto na menu bar.

## Requisitos

- **macOS 14 (Sonoma)** ou superior
- **Xcode Command Line Tools** (inclui Swift e Git)
- **Claude Code** instalado e com pelo menos uma sessão de uso

## Instalação Rápida (recomendada)

Abra o Terminal e cole:

```bash
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash
```

Isso vai:
1. Verificar seus requisitos (macOS, Swift, Git)
2. Baixar o código-fonte
3. Compilar em modo release
4. Instalar em `/Applications/`
5. Abrir o app automaticamente

O app aparece como um ícone na **menu bar** (canto superior direito da tela).

> **Nota:** a primeira compilação pode levar 1-2 minutos.

## Instalação Manual

Se preferir ter controle total:

```bash
# 1. Clonar o repositório
git clone https://github.com/hugocapitelli/eximia-meter.git
cd eximia-meter

# 2. Compilar
bash build-app.sh release

# 3. Instalar
cp -r "dist/exímIA Meter.app" /Applications/

# 4. Abrir
open "/Applications/exímIA Meter.app"
```

## Pré-requisito: Xcode Command Line Tools

Se você não tem o Swift instalado, rode:

```bash
xcode-select --install
```

Vai aparecer um popup pedindo para instalar. Aceite e aguarde (~5 min).

Para confirmar que está tudo certo:

```bash
swift --version
# Deve mostrar algo como: Swift version 6.x.x
```

## Configuração Inicial

Ao abrir o app pela primeira vez:

1. Clique no ícone na menu bar
2. Vá em **Settings** (ícone de engrenagem)
3. Selecione seu **plano Claude**:
   - **Pro** — limites padrão (~100M tokens/semana)
   - **Max 5x** — 5x mais (~500M tokens/semana)
   - **Max 20x** — 20x mais (~2B tokens/semana)
4. Configure thresholds de alerta se desejar

## Iniciar com o macOS (opcional)

Para que o app abra automaticamente ao ligar o Mac:

1. Abra **Ajustes do Sistema** (System Settings)
2. Vá em **Geral → Itens de Início** (General → Login Items)
3. Clique em **+** e selecione **exímIA Meter** em Aplicativos

## Atualização

O app ainda não tem auto-update. Para atualizar para a versão mais recente:

### Opção 1: Re-rodar o instalador (mais fácil)

```bash
curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash
```

O instalador detecta a instalação existente e substitui automaticamente.

### Opção 2: Atualização manual (se clonou o repo)

```bash
cd eximia-meter
git pull origin main
bash build-app.sh release
cp -r "dist/exímIA Meter.app" /Applications/
```

> Feche o app antes de atualizar. Para fechar: clique no ícone na menu bar → **Quit**.

## Como Funciona

O exímIA Meter **não precisa de API key** e **não faz chamadas de rede**.

Ele monitora arquivos locais que o Claude Code CLI grava automaticamente em `~/.claude/`:

- `stats-cache.json` — estatísticas acumuladas
- `history.jsonl` — histórico de sessões
- `projects/**/*.jsonl` — logs detalhados por sessão

O app atualiza os dados a cada 30 segundos automaticamente.

## Funcionalidades

- **Weekly Usage** — barra de progresso do consumo semanal com countdown para reset
- **Current Session** — consumo da sessão atual
- **Model Distribution** — proporção Opus/Sonnet/Haiku nos últimos 7 dias
- **Per Project** — tokens gastos por projeto (últimos 7 dias)
- **Notificações** — alertas quando uso atinge thresholds configuráveis
- **Launch Terminal** — abrir projeto no terminal com um clique

## Desinstalação

```bash
rm -rf "/Applications/exímIA Meter.app"
```

As configurações ficam salvas em `UserDefaults`. Para limpar tudo:

```bash
defaults delete com.eximia.meter
```

## Problemas Comuns

### "O app não mostra dados"

O Claude Code precisa ter sido usado pelo menos uma vez para gerar os arquivos em `~/.claude/`. Verifique:

```bash
ls ~/.claude/stats-cache.json
# Deve existir se você já usou o Claude Code
```

### "Build falhou"

Certifique-se que o Xcode Command Line Tools está instalado:

```bash
xcode-select --install
```

### "App não aparece na menu bar"

O app roda como menu bar app (sem ícone no Dock). Procure o ícone no canto superior direito da tela, perto do relógio.

### "macOS bloqueia o app"

Se aparecer aviso de segurança: Ajustes do Sistema → Privacidade e Segurança → role para baixo e clique "Abrir Mesmo Assim".

---

Feito com Claude Code.

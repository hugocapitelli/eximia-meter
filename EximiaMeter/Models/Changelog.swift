import Foundation

struct ChangelogVersion {
    let version: String
    let items: [String]
}

enum Changelog {
    static let entries: [ChangelogVersion] = [
        ChangelogVersion(version: "v2.7.0", items: [
            "Menu Bar: indicadores redesenhados — S: 8% 4h40m  W: 23% 5d16h",
            "Menu Bar: labels brancos, valores coloridos, tempo compacto e sutil",
            "Admin Mode: ativação por NSAlert nativo (fix do sheet que não abria)"
        ]),
        ChangelogVersion(version: "v2.6.0", items: [
            "Admin Mode: ativação por código secreto com hash SHA256",
            "Canal de atualização: Stable (main) ou Beta (beta) para admins",
            "Check for Updates e Update Now respeitam o canal selecionado",
            "Admin Mode persiste entre atualizações (UserDefaults)"
        ]),
        ChangelogVersion(version: "v2.5.0", items: [
            "Menu Bar: labels S (sessão) e W (semanal) nos indicadores de uso",
            "Custos: baseado na assinatura real, não API pricing. Mostra economia vs API",
            "Color Picker: paleta rápida de 10 cores + opção de cor personalizada"
        ]),
        ChangelogVersion(version: "v2.4.0", items: [
            "Menu Bar: opção para mostrar indicadores de uso (sessão + semanal) ao lado do logo",
            "Settings: card de estilo da Menu Bar (Logo Only / Logo + Usage)",
            "Indicadores coloridos: verde (<50%), laranja (50-80%), vermelho (>80%)"
        ]),
        ChangelogVersion(version: "v2.3.0", items: [
            "Drag & Drop: arraste projetos para grupos na seção de gerenciamento",
            "Fix: UI atualiza imediatamente ao mudar grupo de um projeto",
            "Grupos com indicador visual de drop target ao arrastar"
        ]),
        ChangelogVersion(version: "v2.2.1", items: [
            "Fix: credenciais lidas via security CLI — elimina prompt de senha do Keychain",
            "Cache layer: leitura inicial sem prompt, 'Permitir Sempre' persiste entre builds"
        ]),
        ChangelogVersion(version: "v2.2.0", items: [
            "Dashboard: carousel de projetos de volta na página principal",
            "Aba Projects: projetos agrupados por grupo com contagem",
            "Cards de projeto adaptam largura ao tamanho do popover escolhido",
            "Settings: gerenciamento de grupos (renomear, excluir)",
            "Settings: botão para resetar cores de todos os projetos",
            "Conteúdo adaptativo: tamanhos maiores mostram mais informações"
        ]),
        ChangelogVersion(version: "v2.1.0", items: [
            "Topbar: navegação entre Dashboard, Projects e Insights no popover",
            "Tamanho do popover configurável: Compact, Normal, Large, Extra Large",
            "Página de Insights nas configurações com analytics detalhados",
            "Notificação macOS push quando atualização disponível",
            "Settings premium: cards com hover glow, ícones com background, badges",
            "Burn rate e projeção semanal na aba Insights do popover"
        ]),
        ChangelogVersion(version: "v2.0.0", items: [
            "Insights: custo estimado (7d), streak de uso, comparativo semanal",
            "Sparkline: gráfico de tokens por dia (7 dias)",
            "Heatmap: atividade por hora (24h grid)",
            "Detecção de pico: alerta quando uso é 2x+ acima da média",
            "Sugestão de modelo: recomenda Sonnet quando Opus domina >60%",
            "Export CSV: exportar dados de uso completos",
            "Cores customizáveis por projeto (color picker)",
            "Resumo semanal: notificação de sumário aos domingos",
            "Idle detection: notificação de boas-vindas após 4h+ sem uso"
        ]),
        ChangelogVersion(version: "v1.7.1", items: [
            "Botão AIOS update visível no card do projeto na home page",
            "Update direto: banner mostra confirmação e atualiza sem abrir Settings",
            "Popup de changelog exibido automaticamente após atualização",
            "Projeção mostra % livre no reset: \"No reset, sobrará X% para uso\""
        ]),
        ChangelogVersion(version: "v1.7.0", items: [
            "Fix: notificações não re-disparam quando idle em 100% (persistência + histerese 5%)",
            "Projeção de uso: burn rate mostra quando vai atingir o limite semanal",
            "Botão AIOS: atualizar aios-core diretamente da lista de projetos",
            "Detecção de renomeação: projetos renomeados são detectados automaticamente"
        ]),
        ChangelogVersion(version: "v1.6.0", items: [
            "Update banner on home page when new version is available",
            "Projects: eye toggle hides/shows on main page (with animation)",
            "Projects: full path displayed, deleted projects auto-pruned",
            "Reconnect button in Account tab when API disconnected",
            "Token expired auto-refreshes from Keychain on each popover open",
            "Check for Updates works inside .app (URLSession, no git needed)",
            "Auto-update now code-signs the bundle (notifications preserved)",
            "Force dark mode on all views (light mode Mac compatibility)"
        ]),
        ChangelogVersion(version: "v1.5.3", items: [
            "Fix: macOS notifications now appear in preview (Settings → Alerts → Test)",
            "Fix: notification permission requested on app start (not conditional)",
            "Fix: UNUserNotificationCenter delegate set immediately on init"
        ]),
        ChangelogVersion(version: "v1.5.2", items: [
            "macOS system notifications (Notification Center banners)",
            "Notifications appear even when app is in foreground",
            "Independent toggles: macOS notifications, in-app popup, sound",
            "Test Notifications: preview fires both system + in-app alerts"
        ]),
        ChangelogVersion(version: "v1.5.1", items: [
            "All 14 macOS system sounds available (Basso, Blow, Bottle, Frog, etc.)",
            "Popup Preview: test warning/critical banners from Settings"
        ]),
        ChangelogVersion(version: "v1.5.0", items: [
            "Notifications: sound toggle, in-app popup toggle, sound picker with preview",
            "Notifications: 5-min cooldown, smart reset when usage drops below threshold",
            "In-app alert banner at top of popover (auto-dismiss 8s)",
            "Settings: hoverable cards with border highlight across all tabs",
            "Alerts: redesigned with notification controls card and sound picker"
        ]),
    ]

    /// Returns only the latest version entry (for post-update popup)
    static var latest: ChangelogVersion? {
        entries.first
    }

    /// Returns entries for a specific version
    static func entry(for version: String) -> ChangelogVersion? {
        entries.first { $0.version == version || $0.version == "v\(version)" }
    }
}

import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class ThemeSettingsControllerArguments {
    let account: Account
    let selectTheme: (Int32) -> Void
    let selectFontSize: (PresentationFontSize) -> Void
    let openWallpaperSettings: () -> Void
    let openAccentColor: (Int32) -> Void
    let openAutoNightTheme: () -> Void
    
    init(account: Account, selectTheme: @escaping (Int32) -> Void, selectFontSize: @escaping (PresentationFontSize) -> Void, openWallpaperSettings: @escaping () -> Void, openAccentColor: @escaping (Int32) -> Void, openAutoNightTheme: @escaping () -> Void) {
        self.account = account
        self.selectTheme = selectTheme
        self.selectFontSize = selectFontSize
        self.openWallpaperSettings = openWallpaperSettings
        self.openAccentColor = openAccentColor
        self.openAutoNightTheme = openAutoNightTheme
    }
}

private enum ThemeSettingsControllerSection: Int32 {
    case chatPreview
    case themeList
    case fontSize
}

private enum ThemeSettingsControllerEntry: ItemListNodeEntry {
    case fontSizeHeader(PresentationTheme, String)
    case fontSize(PresentationTheme, PresentationFontSize)
    case chatPreviewHeader(PresentationTheme, String)
    case chatPreview(PresentationTheme, PresentationTheme, TelegramWallpaper, PresentationFontSize, PresentationStrings, PresentationDateTimeFormat)
    case wallpaper(PresentationTheme, String)
    case accentColor(PresentationTheme, String, Int32)
    case autoNightTheme(PresentationTheme, String, String)
    case themeListHeader(PresentationTheme, String)
    case themeItem(PresentationTheme, String, Bool, Int32)
    
    var section: ItemListSectionId {
        switch self {
            case .chatPreviewHeader, .chatPreview, .wallpaper, .accentColor, .autoNightTheme:
                return ThemeSettingsControllerSection.chatPreview.rawValue
            case .themeListHeader, .themeItem:
                return ThemeSettingsControllerSection.themeList.rawValue
            case .fontSizeHeader, .fontSize:
                return ThemeSettingsControllerSection.fontSize.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .fontSizeHeader:
                return 0
            case .fontSize:
                return 1
            case .chatPreviewHeader:
                return 2
            case .chatPreview:
                return 3
            case .wallpaper:
                return 4
            case .accentColor:
                return 5
            case .autoNightTheme:
                return 6
            case .themeListHeader:
                return 7
            case let .themeItem(_, _, _, index):
                return 8 + index
        }
    }
    
    static func ==(lhs: ThemeSettingsControllerEntry, rhs: ThemeSettingsControllerEntry) -> Bool {
        switch lhs {
            case let .chatPreviewHeader(lhsTheme, lhsText):
                if case let .chatPreviewHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .chatPreview(lhsTheme, lhsComponentTheme, lhsWallpaper, lhsFontSize, lhsStrings, lhsTimeFormat):
                if case let .chatPreview(rhsTheme, rhsComponentTheme, rhsWallpaper, rhsFontSize, rhsStrings, rhsTimeFormat) = rhs, lhsComponentTheme === rhsComponentTheme, lhsTheme === rhsTheme, lhsWallpaper == rhsWallpaper, lhsFontSize == rhsFontSize, lhsStrings === rhsStrings, lhsTimeFormat == rhsTimeFormat {
                    return true
                } else {
                    return false
                }
            case let .wallpaper(lhsTheme, lhsText):
                if case let .wallpaper(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        case let .accentColor(lhsTheme, lhsText, lhsColor):
            if case let .accentColor(rhsTheme, rhsText, rhsColor) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsColor == rhsColor {
                return true
            } else {
                return false
            }
        case let .autoNightTheme(lhsTheme, lhsText, lhsValue):
            if case let .autoNightTheme(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                return true
            } else {
                return false
            }
            case let .themeListHeader(lhsTheme, lhsText):
                if case let .themeListHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .themeItem(lhsTheme, lhsText, lhsValue, lhsIndex):
                if case let .themeItem(rhsTheme, rhsText, rhsValue, rhsIndex) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsIndex == rhsIndex {
                    return true
                } else {
                    return false
                }
            case let .fontSizeHeader(lhsTheme, lhsText):
                if case let .fontSizeHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .fontSize(lhsTheme, lhsFontSize):
                if case let .fontSize(rhsTheme, rhsFontSize) = rhs, lhsTheme === rhsTheme, lhsFontSize == rhsFontSize {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: ThemeSettingsControllerEntry, rhs: ThemeSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: ThemeSettingsControllerArguments) -> ListViewItem {
        switch self {
            case let .fontSizeHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .fontSize(theme, fontSize):
                return ThemeSettingsFontSizeItem(theme: theme, fontSize: fontSize, sectionId: self.section, updated: { value in
                    arguments.selectFontSize(value)
                })
            case let .chatPreviewHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .chatPreview(theme, componentTheme, wallpaper, fontSize, strings, dateTimeFormat):
                return ThemeSettingsChatPreviewItem(account: arguments.account, theme: theme, componentTheme: componentTheme, strings: strings, sectionId: self.section, fontSize: fontSize, wallpaper: wallpaper, dateTimeFormat: dateTimeFormat)
            case let .wallpaper(theme, text):
                return ItemListDisclosureItem(theme: theme, title: text, label: "", sectionId: self.section, style: .blocks, action: {
                    arguments.openWallpaperSettings()
                })
            case let .accentColor(theme, text, color):
                return ItemListDisclosureItem(theme: theme, icon: nil, title: text, label: "", labelStyle: .color(UIColor(rgb: UInt32(bitPattern: color))), sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                    arguments.openAccentColor(color)
                })
            case let .autoNightTheme(theme, text, value):
                return ItemListDisclosureItem(theme: theme, icon: nil, title: text, label: value, labelStyle: .text, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                    arguments.openAutoNightTheme()
                })
            case let .themeListHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .themeItem(theme, title, value, index):
                return ItemListCheckboxItem(theme: theme, title: title, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.selectTheme(index)
                })
        }
    }
}

private func themeSettingsControllerEntries(presentationData: PresentationData, theme: PresentationTheme, themeAccentColor: Int32?, autoNightSettings: AutomaticThemeSwitchSetting, strings: PresentationStrings, wallpaper: TelegramWallpaper, fontSize: PresentationFontSize, dateTimeFormat: PresentationDateTimeFormat) -> [ThemeSettingsControllerEntry] {
    var entries: [ThemeSettingsControllerEntry] = []
    
    entries.append(.fontSizeHeader(presentationData.theme, strings.Appearance_TextSize))
    entries.append(.fontSize(presentationData.theme, fontSize))
    entries.append(.chatPreviewHeader(presentationData.theme, strings.Appearance_Preview))
    entries.append(.chatPreview(presentationData.theme, theme, wallpaper, fontSize, presentationData.strings, dateTimeFormat))
    entries.append(.wallpaper(presentationData.theme, strings.Settings_ChatBackground))
    if theme.name == .builtin(.day) {
        entries.append(.accentColor(presentationData.theme, strings.Appearance_AccentColor, themeAccentColor ?? defaultDayAccentColor))
    }
    if theme.name == .builtin(.day) || theme.name == .builtin(.dayClassic) {
        let title: String
        switch autoNightSettings.trigger {
            case .none:
                title = strings.AutoNightTheme_Disabled
            case .timeBased:
                title = strings.AutoNightTheme_Scheduled
            case .brightness:
                title = strings.AutoNightTheme_Automatic
        }
        entries.append(.autoNightTheme(presentationData.theme, strings.Appearance_AutoNightTheme, title))
    }
    entries.append(.themeListHeader(presentationData.theme, strings.Appearance_ColorTheme))
    entries.append(.themeItem(presentationData.theme, strings.Appearance_ThemeDayClassic, theme.name == .builtin(.dayClassic), 0))
    entries.append(.themeItem(presentationData.theme, strings.Appearance_ThemeDay, theme.name == .builtin(.day), 1))
    entries.append(.themeItem(presentationData.theme, strings.Appearance_ThemeNight, theme.name == .builtin(.nightGrayscale), 2))
    entries.append(.themeItem(presentationData.theme, strings.Appearance_ThemeNightBlue, theme.name == .builtin(.nightAccent), 3))
    
    return entries
}

public func themeSettingsController(account: Account) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?
    
    let arguments = ThemeSettingsControllerArguments(account: account, selectTheme: { index in
        let _ = updatePresentationThemeSettingsInteractively(postbox: account.postbox, { current in
            let wallpaper: TelegramWallpaper
            let theme: PresentationThemeReference
            if index == 0 {
                wallpaper = .builtin
                theme = .builtin(.dayClassic)
            } else if index == 1 {
                wallpaper = .color(0xffffff)
                theme = .builtin(.day)
            } else if index == 2 {
                wallpaper = .color(0x000000)
                theme = .builtin(.nightGrayscale)
            } else {
                wallpaper = .color(0x18222D)
                theme = .builtin(.nightAccent)
            }
            return PresentationThemeSettings(chatWallpaper: wallpaper, theme: theme, themeAccentColor: current.themeAccentColor, fontSize: current.fontSize, automaticThemeSwitchSetting: current.automaticThemeSwitchSetting)
        }).start()
    }, selectFontSize: { size in
        let _ = updatePresentationThemeSettingsInteractively(postbox: account.postbox, { current in
            return PresentationThemeSettings(chatWallpaper: current.chatWallpaper, theme: current.theme, themeAccentColor: current.themeAccentColor, fontSize: size, automaticThemeSwitchSetting: current.automaticThemeSwitchSetting)
        }).start()
    }, openWallpaperSettings: {
        pushControllerImpl?(ThemeGridController(account: account))
    }, openAccentColor: { color in
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        presentControllerImpl?(ThemeAccentColorActionSheet(theme: presentationData.theme, strings: presentationData.strings, currentValue: color, applyValue: { color in
            let _ = updatePresentationThemeSettingsInteractively(postbox: account.postbox, { current in
                return PresentationThemeSettings(chatWallpaper: current.chatWallpaper, theme: current.theme, themeAccentColor: color, fontSize: current.fontSize, automaticThemeSwitchSetting: current.automaticThemeSwitchSetting)
            }).start()
        }))
    }, openAutoNightTheme: {
        pushControllerImpl?(themeAutoNightSettingsController(account: account))
    })
    
    let themeSettingsKey = ApplicationSpecificPreferencesKeys.presentationThemeSettings
    let localizationSettingsKey = PreferencesKeys.localizationSettings
    let preferences = account.postbox.preferencesView(keys: [themeSettingsKey, localizationSettingsKey])
    
    let previousTheme = Atomic<PresentationTheme?>(value: nil)
    
    let signal = combineLatest(account.telegramApplicationContext.presentationData, preferences)
        |> deliverOnMainQueue
        |> map { presentationData, preferences -> (ItemListControllerState, (ItemListNodeState<ThemeSettingsControllerEntry>, ThemeSettingsControllerEntry.ItemGenerationArguments)) in
            let theme: PresentationTheme
            let fontSize: PresentationFontSize
            let wallpaper: TelegramWallpaper
            let strings: PresentationStrings
            let dateTimeFormat: PresentationDateTimeFormat
            
            let settings = (preferences.values[themeSettingsKey] as? PresentationThemeSettings) ?? PresentationThemeSettings.defaultSettings
            switch settings.theme {
                case let .builtin(reference):
                    switch reference {
                        case .dayClassic:
                            theme = defaultPresentationTheme
                        case .nightGrayscale:
                            theme = defaultDarkPresentationTheme
                        case .nightAccent:
                            theme = defaultDarkAccentPresentationTheme
                        case .day:
                            theme = makeDefaultDayPresentationTheme(accentColor: settings.themeAccentColor ?? defaultDayAccentColor)
                }
            }
            wallpaper = settings.chatWallpaper
            fontSize = settings.fontSize
            
            if let entry = preferences.values[localizationSettingsKey] as? LocalizationSettings {
                strings = PresentationStrings(languageCode: entry.languageCode, dict: dictFromLocalization(entry.localization))
            } else {
                strings = defaultPresentationStrings
            }
            
            dateTimeFormat = presentationData.dateTimeFormat
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.Appearance_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: strings.Common_Back))
            let listState = ItemListNodeState(entries: themeSettingsControllerEntries(presentationData: presentationData, theme: theme, themeAccentColor: settings.themeAccentColor, autoNightSettings: settings.automaticThemeSwitchSetting, strings: presentationData.strings, wallpaper: wallpaper, fontSize: fontSize, dateTimeFormat: dateTimeFormat), style: .blocks, animateChanges: false)
            
            if previousTheme.swap(theme)?.name != theme.name {
                presentControllerImpl?(ThemeSettingsCrossfadeController())
            }
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(account: account, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}

public final class ThemeSettingsCrossfadeController: ViewController {
    private let snapshotView: UIView?
    
    public init() {
        self.snapshotView = UIScreen.main.snapshotView(afterScreenUpdates: false)
        
        super.init(navigationBarPresentationData: nil)
        
        self.statusBar.statusBarStyle = .Hide
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        self.displayNode = ViewControllerTracingNode()
        
        self.displayNode.backgroundColor = nil
        self.displayNode.isOpaque = false
        if let snapshotView = self.snapshotView {
            self.displayNode.view.addSubview(snapshotView)
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.displayNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        })
    }
}

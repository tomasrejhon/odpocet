# Odpočet

Minimalistická aplikace pro iPhone: jedna událost a počet zbývajících dní na zamykací i domovské obrazovce. SwiftUI + WidgetKit, iOS 17 nebo novější. Bez závislostí, účtu, serveru a analytiky.

## Otevření a spuštění

1. Otevři `Odpocet.xcodeproj` v Xcode, nikoli `Package.swift`.
2. Vyber schéma **Odpocet** a simulátor iPhonu. Spusť pomocí **⌘R**.
3. Pro fyzický iPhone je u `Odpocet` i `OdpocetWidgetExtension` nastavený placený vývojářský tým `8F7DM4TGCN` a automatické podepisování, stejně jako v předchozím projektu. V Xcode vyber svůj iPhone a spusť **⌘R**.
4. Oba targety mají v nově vydaných profilech registrovanou společnou **App Group** `group.cz.tomasrejhon.Odpocet`. Identifikátory a společné nastavení jsou v `Configuration/Project.xcconfig`. Identitu aplikace ani App Group při běžných aktualizacích neměň, aby zůstala dostupná uložená událost.
5. V aplikaci nastav název a počet dní, případně přímo datum, a ulož. Widget přidej běžnou nabídkou iOS; návod je i pod ikonou ⓘ v aplikaci.

Projekt má cílovou rodinu zařízení nastavenou pouze na iPhone. Mac Catalyst, běh iPhone aplikace na Macu a Apple Vision jsou vypnuté. Widgety nejsou preferované pro přenos z iPhonu na Mac. Způsobilost pro dostupnost v obchodě a kompatibilní režimy se při případné distribuci řeší ještě v App Store Connect.

## Chování

- Existuje nejvýše jedna uložená událost. Úprava ji nahradí a požádá WidgetKit o obnovení všech jejích widgetů.
- Zadání 1 dne znamená zítřejší kalendářní datum, nikoli následujících 24 hodin. Rozsah je 0–36 500 dní, název má nejvýše 60 znaků.
- Ukládá se kalendářní datum bez času. Při cestování zůstává cílové datum stejné a odpočet se počítá v místním časovém pásmu.
- V cílový den se zobrazí **0 / Je to dnes**, později **0 / Událost proběhla**. Číslo nikdy neklesne do záporu.
- Domovská obrazovka: malý a střední widget. Zamykací obrazovka: obdélník, kruh a textový řádek nad hodinami.
- Prázdný widget vybídne k nastavení události. Klepnutí na widget standardně otevře aplikaci.
- Světlý a tmavý vzhled podle systému, systémové písmo, VoiceOver a podpora zvětšeného textu.

## Sdílení a aktualizace

### Průhledné pozadí / Liquid Glass

Na iOS 26 a novějším vyber na ploše **Upravit → Přizpůsobit → Clear (průhledný vzhled)**. Systém odstraní vlastní pozadí widgetu a nahradí jej materiálem Liquid Glass. Jde o vzhled celé plochy včetně ikon, nelze ho z aplikace samostatně vynutit pouze pro jeden widget. Widget ponechává pozadí odstranitelné, v průhledném/tónovaném režimu zesiluje číslo a zvyšuje kontrast popisků. V plnobarevném režimu má standardní systémové pozadí. Na zamykací obrazovce vzhled řídí systémový vibrant režim.

Podklad: [Optimizing your widget for accented rendering mode and Liquid Glass](https://developer.apple.com/documentation/WidgetKit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass).

### Ukládání

Aplikace atomicky zapisuje jediný soubor `event.json` do kontejneru App Group. Widget čte tentýž soubor. Neexistuje druhá, oddělená kopie dat; chyba sdíleného úložiště se zobrazí a uložení není předstíráno jako úspěšné.

Soubor je na iOS chráněn třídou `completeUntilFirstUserAuthentication`, takže widget může načíst data na zamčeném telefonu po prvním odemčení od restartu. Název události může být na zamykací obrazovce viditelný podle nastavení iOS.

Widget dostává časovou osu s místními půlnocemi na 35 dní dopředu a žádá o další načtení následující den. Nevyžaduje otevřenou aplikaci ani běžící časovač. Konkrétní okamžik překreslení a zpracování změny řídí iOS; okamžitá aktualizace na sekundu není garantována. Aplikace při významné změně systémového času požádá o přepočet.

## Struktura

- `App/` – obrazovka odpočtu, editor jediné události a návod pro widgety.
- `Widget/` – WidgetKit provider, časová osa a všech pět rozvržení.
- `Shared/` – model kalendářního dne, odpočet a sdílené úložiště; stejné soubory v obou targetech.
- `Configuration/` – společné identifikátory, oprávnění App Groups, Info.plist a privacy manifest.
- `Tests/` – 14 testů kalendářních hranic, validace, časové osy a sdíleného úložiště.

## Ověření

Ověřeno 26. 10. 2026 v Xcode 27.0 na simulátoru iPhone 18 Pro / iOS 27.0:

- Aplikace i přibalené widgetové rozšíření se sestavily a aplikace se spustila.
- Všech 14 testů prošlo v Xcode na iPhone simulátoru; stejných 14 testů prošlo i přes Swift Package Manager.
- Vytvoření události „Island“ s 28 dny, návrat do aplikace přes widget a úprava na 7 dní. Malý widget na ploše se aktualizoval na 7.
- Skutečný systémový Clear / Liquid Glass vzhled na ploše, čitelné číslo, název i popisek přes tapetu.
- Obdélníkový a kruhový widget přidaný na skutečnou zamykací obrazovku simulátoru. Oba načetly uloženou událost a zobrazily 7 dní.
- V simulátoru zůstává testovací událost „Island“ a přidané widgety. Nejde o předvyplněná data v nové instalaci aplikace.

Samostatné fyzické zařízení, všechny vzhledy a textový widget nad hodinami zatím nebyly ručně ověřeny.

Testy spustíš v Xcode přes **⌘U**. Samotnou logiku lze bez simulátoru ověřit také z kořene projektu:

```sh
swift test
```

`Package.swift` je pouze lokální testovací prostředí pro společný Foundation kód, nevytváří macOS aplikaci. Testy zahrnují půlnoc, přestupný rok, nový rok, oba přechody letního času, změnu pásma, nulový a ukončený odpočet, české tvary slov, poškozená data a výměnu události mezi dvěma instancemi úložiště.

Před distribucí otestuj na fyzickém iPhonu: přidání všech variant widgetů, změnu události, půlnoc bez otevřené aplikace, restart a odemčení telefonu, světlý/tmavý/tónovaný vzhled a přechod mezi časovými pásmy. Podpis a App Group jsou již nastavené pro tvůj Apple Developer tým.

## Podpis pro fyzický iPhone

Nastavení převzaté z existujícího projektu po ověření skutečného účtu v Xcode:

- Automatické podepisování, Team ID `8F7DM4TGCN`, pro Debug i Release aplikace a widgetu.
- Aplikace `cz.tomasrejhon.Odpocet`, widget `cz.tomasrejhon.Odpocet.widget`.
- App Group `group.cz.tomasrejhon.Odpocet` je obsažená v obou vydaných profilech i podepsaných oprávněních.
- Oba provisioning profily mají `TimeToLive = 365`. Datum je přečtené z balíčků sestavených pro fyzický iPhone, nikoli vypočtené pouze z dnešního data.

| Balíček | Vydání profilu (Praha) | Expirace profilu (Praha) |
| --- | --- | --- |
| Aplikace | 26. 10. 2026 13:29:06 | 26. 10. 2027 14:29:06 |
| Widget | 26. 10. 2026 13:29:51 | 26. 10. 2027 14:29:51 |

Rozdíl hodiny v místním čase odpovídá letnímu času. Nové sestavení automaticky neposouvá expiraci o další rok: Xcode může znovu použít existující vhodný profil. Při obnově je potřeba ověřit nové datum v `embedded.mobileprovision` aplikace i widgetu. [Postup Apple pro obnovu profilů](https://developer.apple.com/help/account/provisioning-profiles/edit-download-or-delete-profiles/).

Sestavení Debug pro fyzický iPhone úspěšně dokončeno v Xcode 27.0 dne 26. 10. 2026. Stávající vývojářský certifikát zůstal zachovaný. Po odemknutí telefonu Xcode potvrdil „Running Odpocet on Tomáš - iPhone“ — instalace a spuštění na fyzickém iPhonu jsou ověřené. Ruční testování widgetů popsané výše proběhlo na simulátoru.

## Dokumentace Apple

- [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date/)
- [Configuring app groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [Complications and widgets: Reloaded](https://developer.apple.com/videos/play/wwdc2022/10050/)

import SwiftUI

struct WidgetHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Průhledný vzhled") {
                    Text("Na iOS 26 a novějším podrž prst na ploše, otevři Upravit → Přizpůsobit a vyber průhledný vzhled (Clear). iOS pak widgetu přidá skutečné skleněné pozadí.")
                    Text("Toto nastavení platí pro celou plochu, včetně ostatních widgetů a ikon. Na zamykací obrazovce se vzhled přizpůsobí tapetě automaticky.")
                }
                .font(.subheadline)

                Section {
                    Label("Podrž prst na zamykací obrazovce a klepni na Přizpůsobit.", systemImage: "1.circle")
                    Label("Vyber zamykací obrazovku a klepni na místo pro widgety pod hodinami.", systemImage: "2.circle")
                    Label("Najdi Odpočet a vyber obdélníkový nebo kruhový widget.", systemImage: "3.circle")
                } header: { Text("Zamykací obrazovka") }
                footer: { Text("Textový odpočet můžeš přidat i do řádku nad hodinami.") }

                Section("Domovská obrazovka") {
                    Label("Podrž prst na prázdném místě na ploše.", systemImage: "1.circle")
                    Label("V nabídce úprav vyber Přidat widget. Na starších verzích iOS klepni na +.", systemImage: "2.circle")
                    Label("Najdi Odpočet, vyber velikost a klepni na Přidat widget.", systemImage: "3.circle")
                }

                Section {
                    Text("Všechny widgety ukazují stejnou událost. Změníš ji přímo v aplikaci.")
                    Text("Dny se počítají podle místního kalendářního data. V den události uvidíš nulu a „Je to dnes“. Potom zůstane nula a „Událost proběhla“.")
                    Text("Obnovování widgetů řídí iOS, proto se změna může zobrazit s krátkým zpožděním.")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Přidat widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") { dismiss() }
                }
            }
        }
    }
}

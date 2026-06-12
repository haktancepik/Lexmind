# Lexmind Ticari Olgunluk Yol Haritası

Bu dosya yayın öncesi ve ticarileştirme için yapılacakların kontrol listesidir. Bir oturum yarım kaldığında bu dosyayı oku, en üstteki tamamlanmamış kutudan devam et. Her kutu bittiğinde işaretle ve commit'le.

**Durum özeti:** Çekirdek mantık (FSRS, Datamuse, build-time enrichment, SwiftData modelleri) sağlam. Etrafındaki "ürün halkası" eksik — Settings ekranı, Onboarding, Privacy Manifest, Apple Intelligence cihaz fallback'i, GDPR akışları yok.

**Olgunluk hedefi:** Bugün ~3/10 → Faz 1 sonu 6/10 (TestFlight'a hazır) → Faz 2 sonu 8/10 (App Store ticari) → Faz 3 sonu 9/10 (büyüme).

**Strateji notları:**
- TR-only başla, EN'i Faz 2 sonu / Faz 3'te ekle (String Catalog altyapısı Faz 1'de kurulur, çeviri sonra)
- Freemium + subscription (Faz 2)
- Apple Intelligence sadece premium "bonus" değil, FALLBACK ŞART — kullanıcı tabanının %75-85'i iPhone 11/12/13/14 (Apple Intelligence yok)

---

## Faz 1 — Yayınlanabilir MVP (~4-6 hafta)

Amaç: Veri güvenliği + temel kalite + App Store reviewer geçer not. Bu kutular bitmeden TestFlight'a çıkma.

> **Faz 1 sıra mantığı:** Önce App Store rejection riskini sıfırla (1.0, 1.0.1), sonra ürünün eksik temellerini ekle (Settings, Onboarding), sonra stabilite/performans (1.x), sonra test/refactor, en sonda CI ve App Store Connect hazırlığı.

### 1.0 Apple Intelligence Cihaz Fallback'i (ACİL — yayın engelleyici)
ReadingPassageGenerator ve WordAnalyzer FoundationModels kullanıyor. iPhone 15 Pro+ dışında çalışmaz. Reviewer iPhone 13/14 ile test ederse "feature broken" diyebilir.

- [x] `ReadingPassageGenerator` fallback — `ReadingFallbackBuilder` + `recapCard` ile "Bugünün Kelimeleri" özet modu (stored example sentences + Turkish meanings; taklit-LLM metin üretmek yerine bundled curated veri kullanıldı)
- [x] `WordAnalyzer` için library fallback — `QuickLookupService`'e Oxford 5000 lookup eklendi; AI yoksa/başarısızsa `AddWordView` formu Common+Oxford'dan otomatik dolduruyor; popover AI yoksa anında net hata mesajı veriyor (sonsuz loading yok)
- [x] "Özet modu" banner'ı — Reading sekmesinde AI yoksa kullanıcıya net bilgi (sparkles.slash + availability mesajı)
- [ ] iPhone 13/14 simulator'da end-to-end manuel test (manuel adım — kullanıcı tarafında doğrulanacak)

### 1.0.1 Privacy Manifest (ACİL — iOS 17+ zorunlu)
- [x] `Lexmind/PrivacyInfo.xcprivacy` eklendi, Xcode target bundle'ına dahil edildi
- [x] `NSPrivacyAccessedAPITypes`: `FileTimestamp` (C617.1 — SwiftData/SQLite app container) + `UserDefaults` (CA92.1 — yakında gelecek @AppStorage için). SystemBootTime kullanılmadığından deklare edilmedi (yanlış beyandan kaçınmak için).
- [x] `NSPrivacyTracking: false`, `NSPrivacyCollectedDataTypes: []` (Datamuse trackingle ilgili değil, sadece sözlük lookup)
- [x] `NSPrivacyTrackingDomains: []` (boş ama deklare)
- [ ] Archive build + App Store Connect validate adımı (TestFlight'a yüklerken kontrol edilecek — şu an local build temiz)

### 1.1 Settings Ekranı (temel — gerisinin önkoşulu)
HomeView'da inline Stepper var ama yetersiz. StoreKit, bildirim, GDPR, dil seçimi hepsi buraya bağlanacak.

- [x] `Views/SettingsView.swift` oluşturuldu, RootTabView'a 5. tab olarak (gearshape.fill) eklendi
- [x] İçerik: Günlük Hedef (aktif), Bildirimler / Dil / Veri / Pro (Faz 2 placeholder satırları), Hakkında bölümü (gizlilik/koşullar/lisanslar — 1.10'da bağlanacak; sürüm bilgisi `CFBundleShortVersionString` + `CFBundleVersion`'dan)
- [x] HomeView'daki inline Stepper bölümü kaldırıldı; günlük hedef artık sadece Settings'ten yönetiliyor
- [x] Header: brain.head.profile gradient icon + "Lexmind" + tagline "FSRS tabanlı kelime öğrenme"

### 1.2 Onboarding + İlk Açılış Akışı
Şu anda app direkt 4-tab TabView açıyor, boş kelime listesi gösteriyor. Yüksek terk oranı riski.

- [x] `Views/OnboardingView.swift`: 4 sayfa paged TabView (Welcome → CEFR seviye → günlük hedef Stepper'ları → kütüphane import önerisi) + alt page dots + Devam butonu
- [x] `@AppStorage("hasCompletedOnboarding")` ile `LexmindApp` seviyesinde gate (false ise OnboardingView, true ise RootTabView)
- [x] Son sayfa: "Hazır kütüphaneden ekle" → `LibraryImportView` sheet (kapatınca onboarding tamamlanır), veya "Şimdilik atla" → direkt tamamla
- [x] `preferredCEFRLevel` AppStorage'a yazılıyor (Faz 3'te dil seçimi/filtre için), DailyGoal modeli onboarding'de oluşturulup hedeflerle dolduruluyor
- [x] `HomeView` boş kelime durumu: yeni `emptyHeroCard` (sparkles + "Hadi başlayalım" + "Hazır Kütüphaneden Ekle" + "Tek Kelime Ekle" CTA'ları); statsRow/upcoming gibi anlamsız 0 göstergeler boş durumda gizlendi

### 1.3 Performans & Stabilite

#### 1.3.1 JSON Lazy Loading
- [x] `CommonWordsLibrary` ve `OxfordWordsLibrary`'ye `preload() async` eklendi (`Task.detached(.utility)` ile arka planda warm-up); `LibraryImportView` `.task` içinden iki kütüphaneyi paralel preload ediyor, hazır olana kadar `ProgressView`. Lookup callsite'ları (StudyView, WordDetailView, ReadingPassageView, AddWordView) view appear'da preload tetikliyor — popover ilk açıldığında main thread'de senkron JSON decode olmuyor
- [x] Instruments Time Profiler ile app launch'ta JSON decode süresini ölç — hedef <500ms (ÖLÇÜLDÜ 2026-06-12 iPhone 15 Pro sim, iOS 26.1, Release build): **loadCommon = 8.69 ms, loadOxford = 7.69 ms** (Points of Interest signpost interval'leri). Hedefin 60× altında. `Task.detached(.utility)` arka plan preload'u main thread'i hiç bloke etmiyor — POI track'te schedule (FSRS) mikrosaniye düzeyinde, importWords (onboarding bulk insert) async 4 s ama UI'da görünmüyor. Ölçüm altyapısı için `Signpost.library` eklendi (`loadCommon`/`loadOxford` interval'leri), tüm signposters `PointsOfInterest` category'sine taşındı (default Instruments POI track yakalasın)

#### 1.3.2 Force Unwrap Temizliği
- [x] Denetim (2026-06-10): kod tabanında prod kodunda 0 force unwrap, 0 `as!`, 0 `try!`. Roadmap'in başında yapılan "120+" tahmini stale çıktı — son commit'lerle (1.0/1.1/1.2/1.3.5) zaten temizlenmiş. `Word.card!` pattern'i de hiç yok; SwiftData ilişkileri her yerde `if let card = word.card` ile ele alınıyor
- [x] Tek istisna `PreviewData.swift:13`'teki `try! ModelContainer(...)` — sadece SwiftUI preview'lerinde çalışır, App Store binary'sine girmez, Apple resmi şablonlarında kullanılan konvansiyon. Bırakıldı.
- Not — **Neden kritik:** Reviewer test ederken bir force_cast crash'i = direkt rejection (bu risk şu an mevcut değil)

#### 1.3.3 Datamuse Error UX
- [x] `DatamuseClient.terms(for:endpoint:)` ve `wordExists(_:)` artık `Result<Set<String>, DatamuseError>` / `Result<Bool, DatamuseError>` döndürüyor. `DatamuseError` enum'ı: `.offline`, `.timeout`, `.serverError(Int)`, `.invalidResponse`, `.invalidQuery` (+ `userMessage` + `isRetryable`). URLError kodları offline/timeout'a düzgün eşleniyor. Cache yalnızca success sonuçlarını saklıyor — failure'da tekrar denenir.
- [x] `RelationVerifier` `@Observable` oldu, `lastError: DatamuseError?` yayımlıyor. `WordDetailView.relationsCard`'a `retryable` hatada turuncu offline badge + "Tekrar dene" butonu eklendi; buton `verifier.retryVerification(for: word)` ile mevcut AI ilişkilerini Datamuse'a yeniden doğrulatıyor (başarılıysa badge kaybolur, badge'ler güncellenir)
- [x] Timeout sonrası 1 kez retry: `fetchWords(retriesRemaining:)` ilk `URLError.timedOut`'ta otomatik yeniden çağırılıyor; ikinci timeout'ta `.timeout` failure döner

#### 1.3.4 SwiftData Unique Constraint Normalize
- [x] `Word.init` term'i artık model katmanında normalize ediyor: `trimmingCharacters(.whitespacesAndNewlines).lowercased()`. Yeni `var displayTerm: String?` orijinal casing'i saklıyor (sadece lowercase'den farklıysa); `var displayName` computed property `displayTerm ?? term` ile fallback yapıyor. Static `Word.normalize(_:)` helper'ı eklendi.
- [x] "Apple" vs "apple" duplicate'i artık model katmanında engellenir: `@Attribute(.unique) var term` ve init'teki lowercased zorlaması birlikte garantiyi sağlıyor (önceden defense at caller idi — gelecekteki bir yazar lowercased'ı unutursa düşmez)
- [x] Display sites (`WordDetailView` navigationTitle + header, `StudyView` promptCard, `WordsListView` row, `HomeView` upcoming) `word.displayName` kullanıyor; `AddWordView.save()` artık trimmed-orijinal casing'i Word.init'e geçiriyor — kullanıcı "Apple" yazarsa term="apple", displayTerm="Apple"
- Migration notu: yeni alan optional (`String?`), mevcut kayıtlar `nil` olarak gelir → `displayName` `term`'e düşer, görsel regresyon yok

#### 1.3.5 Kelime Ailesi / İlişki Yükleme Göstergesi
**Mevcut sorun:** Popover ve WordDetail'de kelime ailesi / synonyms / antonyms bölümleri yüklenirken (~5s AI streaming + Datamuse fetch) hiçbir gösterge yok. Yeni kullanıcı boş alanı "veri yok" sanıyor ve ekrandan çıkıyor.
- [x] `QuickLookupService.LookupResult.isStreaming` computed eklendi (sadece `.partialAI`'de true). `WordQuickLookupCard.familySection` ve `inflectionSection` streaming sırasında alan boşsa `ProgressView(.controlSize(.mini))` + "Kelime ailesi yükleniyor…" / "Çekim örnekleri yükleniyor…" satırı gösteriyor; stream bitince veri varsa içerik, yoksa hiç bir şey
- [x] `WordDetailView.relationsCard` ve `familyCard`: `isRegenerating && empty` durumunda büyük loading row ("İlişkiler yükleniyor…" / "Kelime ailesi yükleniyor…"). `sectionCard` artık `isWorking` parametresi alıyor — başlık yanında `ProgressView(.controlSize(.small))` gösteriyor
- [x] Tüm transition'lar `.transition(.opacity)` + parent `.animation(.easeInOut(0.25), value:)` ile fade-in
- [x] Datamuse arka plan doğrulaması: `RelationVerifier.isVerifying: Bool` flag'i eklendi (defer ile applyVerifiedRelations boyunca true). WordDetailView ilişkiler/aile kartında `verifyingBadge` ("Doğrulanıyor…" + mini spinner) gösteriliyor — hata varsa offline badge önceliği alıyor

### 1.4 FSRS Unit Testleri (algoritma kullanıcı verisinin kalbi)
- [x] `LexmindTests/FSRSSchedulerTests.swift` oluşturuldu — 17 test, Swift Testing framework (`@Test`), in-memory `ModelContainer` ile FSRSCard instance üretiyor. Tüm testler Xcode GetTestList'te görünüyor
- [x] Bilinen input/output çiftleri: `newCard_initialStability_matchesWeights` w[0..3] sabitleriyle (.40255, 1.18385, 3.173, 15.69105) golden values; geri kalan değerler weight tuning'e dirençli olsun diye property/invariant style (ordering, bounds, monotonicity)
- [x] `again`/`hard`/`good`/`easy` etkileri: `review_stabilityGain_easy_outranks_good_outranks_hard` ordering; `reviewState_again_movesToRelearning_andLapsesIncrement`; `reps_alwaysIncrement_byOne`; `difficulty_alwaysInBounds` ([1,10] her state/rating kombinasyonunda)
- [x] State transitions: `new → learning/review` (again/hard/good vs easy); `learning → review` (good/easy); `review → relearning` (again); `relearning → review` (good/easy); `relearning → relearning` (again); `learning → learning` (again/hard); `review → review` (hard/good/easy)
- [x] Edge cases: `elapsedDays_clampsToZero_whenNowIsBeforeLastReview` (zaman geriye gitti); `longGap_doesNotCrash_andProducesFiniteStability` (365 gün gap, finite stability garantisi); `newCard_again_dueWithinShortLearningWindow` (1 dk window); `newCard_easy_dueAtLeastOneDayAway`; `apply_writesResultBackToCard`
- [x] **Testler koşturuldu ve geçti (2026-06-12):** `xcodebuild test -scheme Lexmind -only-testing:LexmindTests CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" CODE_SIGN_REQUIRED=NO` ile **6 suite, 67 test, 0.337s** PASSED. Xcode IDE'de Signing & Capabilities team eksik olsa bile CLI bypass çalışıyor — bu CI'da da işe yarayan yaklaşım. 67 = FSRS 17 + SwiftDataMigration 5 + LibraryImporter 10 + WordDeck 7 + HomeModel 24 + base testler
- [x] **Bugfix (2026-06-12):** İlk koşumda `SwiftData/BackingData.swift:835: Fatal error: This model instance was destroyed by calling ModelContext.reset` crash'i. Sebep: `FSRSSchedulerTests.makeCard` helper'ı lokal `let container = try makeContainer()` ile container yaratıp `FSRSCard` return ediyordu — fonksiyon scope'undan çıkınca ARC container'ı yıkıyor, dönen card unusable oluyor. Çözüm: container struct property'sine taşındı (`init() throws` ile yaratılır), `makeCard` non-throwing oldu. Container artık test struct ömrü boyunca yaşar
- [x] Scheme altyapısı: `Lexmind.xcscheme`'deki boş `<TestPlans></TestPlans>` elementi `xcodebuild test` ile çakışıyordu ("no test plan associated"); kaldırıldı, scheme `<Testables>` listesini doğrudan kullanıyor

### 1.5 SwiftData Migration Planı
- [x] `Models/LexmindSchema.swift` oluşturuldu — `LexmindSchemaV1: VersionedSchema` 6 model'i listeliyor (`Word`, `FSRSCard`, `ReviewLog`, `DailyGoal`, `WordRelation`, `DailyReadingPassage`), `versionIdentifier = Schema.Version(1, 0, 0)`
- [x] `LexmindMigrationPlan: SchemaMigrationPlan` iskelet: `schemas = [LexmindSchemaV1.self]`, `stages = []`. V2 geldiğinde stages array'ine `.lightweight(fromVersion:toVersion:)` eklenecek
- [x] `LexmindApp.swift` `init()` içinde manuel `ModelContainer(for:migrationPlan:configurations:)` kuruyor — `Schema(versionedSchema: LexmindSchemaV1.self)` ile, `.modelContainer(modelContainer)` scene modifier ile bağlandı. Eski `.modelContainer(for: [...])` çağrısı kaldırıldı
- [x] `LexmindTests/SwiftDataMigrationTests.swift` — 5 smoke test: V1 version `1.0.0`, models listesi tam 6 element, plan sadece V1 içeriyor, stages şu an boş, in-memory container migration plan ile build oluyor + insert/fetch round-trip çalışıyor. Toplam test sayısı 17→22 (FSRS 17 + Migration 5)
- Not: Gerçek V1→V2 lightweight migration testi V2 şeması yazıldığında eklenecek (şu an tek versiyon var)

### 1.6 Kullanıcı Desteleri (Decks)
Şu an tüm Word'ler global tek bucket'ta — kullanıcı 2000+ kelimeli kütüphaneyi sade çalışamıyor. Hazır kütüphane CEFR seviyeli alt-destelere bölünür (A1/A2/B1/B2/C1/C2), kullanıcı kendi destelerini oluşturup adlandırabilir, birleştirebilir. 1.5'te kurulan migration plan iskeletinin gerçek ilk kullanımı (V1 → V2 custom migration).

**Schema V2 (`LexmindSchemaV2`):**
- [x] `Models/WordDeck.swift`: yeni `@Model final class WordDeck` — `id: UUID @unique`, `name: String`, `isPreset: Bool`, `presetLevelRaw: String?` (preset desteler için "A1".."C2", kullanıcı destelerinde nil), `createdAt: Date`, `sortOrder: Int`, `@Relationship words: [Word]` (many-to-many, no cascade delete)
- [x] `Word.decks: [WordDeck]` inverse relationship. Cascade davranışı: deste silinince Word **silinmez** (sadece M:N bağ kalkar). Word silinince `deck.words`'ten otomatik çıkar
- [x] `Models/LexmindSchema.swift`'e `LexmindSchemaV2: VersionedSchema` ekle — V1 6 model + WordDeck. `versionIdentifier = Schema.Version(2, 0, 0)`
- [x] `LexmindMigrationPlan.stages` doldur: `.custom(fromVersion: LexmindSchemaV1.self, toVersion: LexmindSchemaV2.self, willMigrate: nil, didMigrate: { context in ... })`. `didMigrate` 6 preset deste oluşturur ("A1".."C2", `isPreset=true`), mevcut Word'leri `level` raw'larına göre ilgili preset desteye bağlar. Level'ı nil olan Word'ler preset deste DIŞINDA kalır
- [x] `LexmindApp.swift` — modelContainer artık `Schema(versionedSchema: LexmindSchemaV2.self)` kullanır

**LibraryImportView refaktör:**
- [x] Üst düzey "Hazır Desteler" listesi: A1, A2, B1, B2, C1, C2 — her destenin yanında kelime sayısı + "Bu desteyi ekle" butonu (LazyVGrid tile'lar). Tek tıkla tüm A1 / A2 / B1 / B2 / C1 / C2 import edilir
- [x] Mevcut chip filter UI'yi destenin altında koru (tek tek seçim hâlâ mümkün)
- [x] `LibraryImporter.importWords`: import edilen Word otomatik olarak `level`'ına karşılık gelen preset `WordDeck`'e bağlanır (idempotent — `presetByLevel` map'inden lookup, candidate filter zaten duplicate'leri eliyor)
- [x] `OnboardingView` son sayfa: `preferredCEFRLevel`'a göre o seviyenin preset destesini öneri olarak öne çıkar — kullanıcı CEFR seçtiyse libraryPage'de "Senin için önerilen: {level} destesi — N kelime" prominent kart ("sparkles" ikonu, accent-tinted), tap edince `LibraryImportView(initialLevel: level)` ile o seviye pre-filter'lı açılır. Mevcut "Tüm kütüphaneyi göster" ikincil `.bordered` button olur. Seviye seçilmediyse eski tek-CTA davranışı korunur. `LibraryImportView.init(initialLevel:)` parametresi eklendi; `.onAppear`'da `levelFilter == nil` ise initial level uygulanıyor

**Yeni Views:**
- [x] `Views/DecksView.swift`: RootTabView'ın 6. tab'ı. Üstte "Hazır Desteler" section (6 preset), altında "Kendi Destelerim" section. Plus toolbar menüsü → "Yeni Deste" sheet (isim girişi → boş deste) + "Desteleri Birleştir"
- [x] `Views/DeckDetailView.swift`: destenin içindeki kelimeler. Toolbar + → AddWordsToDeckSheet (multi-select picker), swipe → "Çıkar" (membership-only). Alt safe-area "Bu Desteyi Çalış" butonu → StudyView'i bu deck için aç
- [x] `RootTabView.swift`: 6. tab eklenir — `rectangle.stack.fill` icon, label "Desteler". TabView selection artık `@AppStorage("rootTabSelection")` ile persistent, deep-link routing için yazılabilir

**Deck işlemleri (yalnız kullanıcı desteleri):**
- [x] Yeniden adlandır: swipe action + context menu → RenameDeckSheet (mevcut isim prefilled, çakışma uyarısı). Preset'lerde menüler görünmez
- [x] Sil: swipe action + context menu + confirm alert (içerdeki Word'lere dokunulmayacağı vurgulanıyor). Preset'ler dokunulmaz
- [x] Birleştir: toolbar Menu → MergeDecksSheet. Multi-select kaynak (preset + user), yeni hedef ismi, benzersiz kelime sayacı, "Birleşim sonrası kaynak desteleri sil" toggle'ı (sadece user-deck kaynaklarını siler — preset'lere dokunmaz). Hedef her zaman yeni user deste

**StudyView deck filter:**
- [x] Üstte `Menu` chip ile aktif deste seçimi (default: "Tümü"). `@AppStorage("activeDeckID")` ile son seçim hatırlanır
- [x] `buildQueue()` güncellemesi: aktif deste seçiliyse queue `deck.words` içinden filter — due/new ayrımı korunur. `rebuildQueue()` deck değişince queue + current + revealed state'i temizler
- [x] DeckDetailView'dan tek tıkla "Bu Desteyi Çalış" → StudyView aktif deste prefilled (`rootTabSelection` AppStorage'a yazılır, tab Çalış'a geçer)

**HomeView:**
- [x] MVP: istatistikler global kalır (mevcut davranış korunur)
- [ ] Faz 2'de opsiyonel: "Aktif Deste" özet kartı

**Testler:**
- [x] `LexmindTests/WordDeckTests.swift` (yeni): CRUD, M:N insert/remove, deste silindiğinde Word kalıyor, Word silindiğinde `deck.words`'ten otomatik çıkıyor — 7 test
- [x] `LexmindTests/SwiftDataMigrationTests.swift` güncelle: V2 schema metadata + v1ToV2 custom stage `didMigrate` round-trip exercise eden testler
- [x] `LexmindTests/LibraryImporterTests.swift` (yeni): 10 test — preset deck binding (A1/A2/B2 router, levelless → unbound, preset yoksa crashe etmez), idempotency (ikinci import 0 ekler, FSRSCard + WordRelation duplicate olmaz, karışık payload sadece yenileri alır), edge cases (empty payload progress fire etmez, batchSize=1 ile progress running total raporlar)

**Notlar:**
- Many-to-many CloudKit uyumluluğu (Faz 2.1): inverse mandatory olabilir — V2 tasarımında inverse zorunlu kuralım
- Performance: 2000+ kelime × 6 preset deste M:N → SwiftData query maliyeti Instruments ile ölçülmeli
- Preset deste isimleri sadece CEFR kodu ("A1".."C2"); tint renkleri (yeşil/mint/sarı/turuncu/kırmızı/mor) zaten seviye sinyali veriyor

### 1.7 View Refactor (test edilebilirlik + bakım)
- [x] `StudyView` 688 → 306 satır (hedef <250'ye ulaşılamadı — addFromPopover 50 satır iş mantığı orada kalmak zorunda, ama 55% küçüldü). Yeni dosyalar: `StudySession.swift` (@Observable — queue/grade/reveal/preview), `StudyAnswerCard.swift` (StudyPromptCard + StudyAnswerCard — prompt/answer + family/relations chips), `StudyRatingControls.swift` (reveal + rating row + interval color), `StudyDeckPicker.swift` (capsule menu), `StudyEmptyState.swift` (boş queue durumu)
- [x] `WordDetailView` 724 → 384 satır (hedef <300'e ulaşılamadı — addWordFromTerm + lazyEnrichIfNeeded + regenerate AI iş akışı 130 satır view'da kalmak zorunda, ama 47% küçüldü). Yeni dosyalar: `WordDetailSectionCard` (generic regular-material wrapper), `WordDetailChips` (chips row + loading row + verifying badge + sortedRelationChips), `WordDetailHeader` (title + tag row + cefrColor), `WordDetailMeaningCard` (Phonetics + Meaning + Examples + InflectionExamples), `WordDetailFamilyCard`, `WordDetailRelationsCard` (Datamuse offline badge dahil), `WordDetailScheduleCard`
- [x] `LibraryImportView` 507 → 315 satır (hedef <300'e ulaşılamadı — `importInto` payload mapping + Task orkestrasyonu 95 satır view'da kalmak zorunda, ama 38% küçüldü). Yeni dosyalar: `LibraryImportProgressOverlay`, `LibraryImportPresetDecks`, `LibraryImportFilterChips`, `LibraryImportWordRow`, `LibraryImportMergedLibrary`, `LibraryImportSummaryRow`, `LibraryImportLevelSectionHeader`
- [x] Ortak `LookupPopover` 3 view'da kopyalanmış → tek component'e indir: yeni `LookupPopoverContent` `if let lookup` guard + retry closure'ı içeride hallediyor; sadece `onOpenDetail` opsiyonel (WordDetailView için). StudyView 306 → 299 satır (artık <300 hedefini yakaladı), WordDetailView 384 → 377
- [x] `HomeView`'daki iş mantığını `@Observable HomeModel`'e taşı: yeni `HomeModel.swift` (@Observable, @MainActor) — `dueCount`/`newCount`/`reviewedTodayCount`/`streak`/`nextDueWords`/`greeting` derived metrikleri + `ensureGoalExists(currentGoals:in:)` (static helper) + `greeting(forHour:)` (static, saat enjekte edilebilir). HomeView 329 → 285 satır
- [x] HomeModel sync trigger bugfix: ilk implementasyon `.onChange(of: words.count)` kullanıyordu — bu mevcut bir kaydın `card.due` mutation'ını (review sonrası) yakalamıyordu. Şimdi model `private var model: HomeModel` computed property — her body re-eval'de inline construct + sync, @Query güncellemeleri tam yayılıyor
- [x] `LexmindTests/HomeModelTests.swift`: 24 unit test (Swift Testing) — goal default/custom, dueCount nil-card semantics, newCount state filter, reviewedTodayCount calendar boundary, streak (empty / today / consecutive / gap-break / past-only), nextDueWords (nil-exclude / sort / 5-cap), greeting (5/12/17/22 boundary + fallback), ensureGoalExists (insert / noop), sync replace round-trip

### 1.8 Observability — MetricKit + os.Logger
- [x] `Lexmind/Services/Logging.swift`: subsystem bazlı `Logger` factory — `com.lexmind.app` subsystem, 8 kategori (`app`, `services.library`, `services.importer`, `services.ai`, `services.network`, `fsrs`, `data`, `metrics`) ve 3 `OSSignposter` (importer/fsrs/ai)
- [x] Tüm services'lerde `print` ve sessiz catch'leri `Logger.error`'a çevir — CommonWordsLibrary/OxfordWordsLibrary `print` çağrıları `Log.library.fault/error` oldu (DEBUG-only kaldırıldı, Console'da prod'da da görünür); WordAnalyzer.analyze + streamQuick, ReadingPassageGenerator.generate + stream, DatamuseClient decode catch'leri `Log.ai.error` / `Log.network.error` log + throw; StudyView/WordDetailView'daki "Silent" yorumlu lazyEnrich catch'leri `Log.ai.error` (CancellationError ayrı kola alındı); LexmindApp ModelContainer init failure `Log.app.fault` + fatalError
- [x] `MXMetricManagerSubscriber` implementasyonu (LexmindApp seviyesinde) — `Services/MetricKitObserver.swift` NSObject + protokol; LexmindApp init'te `metricObserver.start()` ile `MXMetricManager.shared.add(self)`; `didReceive(_ payloads: [MXMetricPayload])` günlük launch/hang/peakMem/cpuSeconds özetini `Log.metrics.info`'ya, `didReceive(_ payloads: [MXDiagnosticPayload])` crash/hang/cpu/disk diagnostic sayıları varsa `Log.metrics.fault`'a
- [x] Critical path'lere signpost: `LibraryImporter.importWords` (total + per-batch save error log), `FSRSScheduler.schedule` (rating/state metadata), `ReadingPassageGenerator.generate` (kelime sayısı metadata). Instruments'te os_signpost track'inden chartable

### 1.9 String Catalog Altyapısı (sadece TR, EN sonra)
- [x] `Localizable.xcstrings` oluştur — TR-only doldur: `Resources/Localizable.xcstrings` (sourceLanguage="tr"). Xcode build sırasında SwiftUI `LocalizedStringKey` otomasyonu ile tüm `Text`/`Label`/`navigationTitle`/`alert` literal'larını ve `String(localized:)` çağrılarını harvest etti — 220 entry, 687 satır
- [x] `HomeView`, `StudyView`, `StatsView`, `SettingsView`, `OnboardingView` inline TR string'leri `String(localized:)` ile değiştir: ek manuel sarma gerekmedi — SwiftUI initializer'ları zaten `LocalizedStringKey` kabul ediyor, build harvest etti
- [x] `AddWordView`, `WordDetailView`, `WordsListView`, `LibraryImportView`, `ReadingPassageView`, `RootTabView`: aynı şekilde otomatik harvest edildi
- [x] DataModels'deki `label` getter'ları: `CardState`, `WordTopic`, `RelationKind`, `ReviewRating` `var label: String` getter'larındaki ham TR string'ler `String(localized:)` ile sarmalandı (SwiftUI dışından çağrılabildiği için manuel sarma şart). `CEFRLevel.label = rawValue` zaten "A1"/"B2" gibi locale-bağımsız token döndürüyor — bırakıldı
- [ ] EN sütununu Faz 3'te doldur

### 1.10 CI — Minimum
- [x] `.github/workflows/ci.yml`: PR'da `xcodebuild test` çalıştır — `macos-latest` runner, iPhone 16 simulator UDID dinamik resolve ediliyor, `CODE_SIGNING_ALLOWED=NO` ile signing bypass (test target signing sorunu CI'da takılmasın); `concurrency` ile aynı ref üzerinde eski koşumlar iptal
- [x] SwiftLint config (`.swiftlint.yml`) + workflow step — minimal config (line_length / trailing_whitespace / todo / identifier_name vs. disabled, empty_count + redundant_nil_coalescing opt-in). Ayrı job, `brew install swiftlint`, `--reporter github-actions-logging` (ilk PR'da yanlış pozitif kırmasın diye `--strict` kullanılmadı; tabloya bakıp ileride sıkılaştırılacak)
- [x] README'ye build badge: `[![CI](.../actions/workflows/ci.yml/badge.svg)]`
- Not: Workflow ilk push'tan sonra tetiklenecek; manuel adım — kullanıcı push'larsa Actions sekmesinden ilk koşumun çıktısı doğrulanmalı, gerekirse runner Xcode sürümü / simulator adı fine-tune edilir

### 1.11 App Store Connect Hazırlığı
- [ ] App Store Connect'te app record (bundle ID, kategori: Education, age rating)
- [ ] Marketing metadata (TR): app name, subtitle, açıklama, keywords, support URL
- [ ] Privacy Policy URL + Terms of Use URL (basit statik sayfa — GitHub Pages yeter)
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max), 6.5" — en az 3 ekran/cihaz
- [ ] App Preview video (opsiyonel)
- [ ] App icon 1024×1024 + tüm asset boyutları Assets.xcassets'te

### 1.12 Faz 1 Çıkış Kriterleri
- [ ] Tüm yukarıdaki kutular tik
- [ ] TestFlight build yüklenmiş, en az 1 internal tester en az 3 gün kullanmış
- [ ] Crash-free session %100 (en az 3 gün)
- [ ] Reviewer simülasyonu: iPhone 13 simulator'da Reading Passages + tüm tab'lar boş veri ile dahi açılıyor

---

## Faz 2 — Ticari Sürüm (~1-2 ay)

Amaç: Para kazanmaya ve kullanıcı tutmaya hazır.

### 2.1 CloudKit Sync
- [ ] SwiftData şemasını CloudKit-uyumlu hale getir (unique constraint → composite, optional alanlar)
- [ ] `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.lexmind"))`
- [ ] Capabilities → iCloud + CloudKit aktif
- [ ] Conflict resolution stratejisi (en son yazan kazanır + ReviewLog append-only)
- [ ] İki cihazlı manuel test: yeni kelime, review, silme

### 2.2 StoreKit 2 + Paywall
- [ ] Free tier sınırı: 100 kelime, günde 1 reading passage, kütüphane import kısıtlı
- [ ] App Store Connect'te subscription product (aylık + yıllık, opsiyonel lifetime)
- [ ] `Services/EntitlementsService.swift` — `@Observable`, `Transaction.currentEntitlements` dinler
- [ ] `Views/PaywallView` — değer önerisi + iki plan + restore butonu
- [ ] Feature gate'ler: `AddWordView` limit kontrolü, `LibraryImportView` Pro badge

### 2.3 Accessibility Pass (somut hedef)
**Mevcut taban:** sadece 1 `accessibilityLabel` var. Reviewer için kabul edilemez.

- [ ] Hedef: 100+ `accessibilityLabel`, 30+ `accessibilityHint`, 0 VoiceOver dead-end
- [ ] Tüm rating button, stat card, chip, badge, navigation interactive element'i
- [ ] Dynamic Type: tüm view'ları en büyük setting'de aç, kırılanları `ScrollView` veya `Layout` ile çöz
- [ ] Reduce Motion: animasyon'lar `@Environment(\.accessibilityReduceMotion)` ile koşullu
- [ ] Color contrast: WCAG AA (özellikle CEFR tint renkleri)
- [ ] VoiceOver el ile test (iPhone'da Triple-click)

### 2.4 Push Notification (Retention için kritik)
- [ ] Local notification yeter başta: günlük review reminder, streak hatırlatması
- [ ] `Services/NotificationScheduler.swift` — kullanıcının review penceresine göre planla
- [ ] Settings'te bildirim saati seçimi
- [ ] **Bildirim izin promptu:** launch'ta DEĞİL, kullanıcı ilk kez "hatırlat" toggle'ına basınca iste (App Store guideline 5.4)
- [ ] APNs capability + entitlement (remote notification gerekirse)

### 2.5 Backup/Restore (manuel)
- [ ] Settings → "Verilerimi dışa aktar" (JSON dump: words + relations + cards + logs)
- [ ] "Verilerimi içe aktar" (validation + dry run + confirm)

### 2.6 Crash Reporting — MetricKit yeter
- [ ] MetricKit yeterli, Sentry ekleme — privacy maliyeti vs detay düşük ROI
- [ ] App Store Connect'te crash log'ları takip et
- [ ] Sentry sadece Faz 3'te ve gerçekten ihtiyaç doğarsa

### 2.7 GDPR / KVKK Veri Akışları
- [ ] Settings → "Tüm verilerimi sil" (one-shot DELETE FROM Word/Card/Log + CloudKit reset)
- [ ] Settings → "Verilerimi indir" (2.5'in GDPR formatında JSON versiyonu)
- [ ] In-app "Gizlilik Politikası" linki Settings'te

### 2.8 In-App Review Prompt
- [ ] `SKStoreReviewController.requestReview()` — 3. başarılı çalışma seansından sonra, 30 günde 1 kez
- [ ] `@AppStorage("lastReviewPrompt")` + session sayacı
- [ ] **Etki:** App Store puanı için kritik, ortalama %30 daha yüksek puan

### 2.9 Faz 2 Çıkış Kriterleri
- [ ] App Store'a submit edilmiş ve approved
- [ ] İlk 10 paying user
- [ ] CloudKit sync 2 cihaz arasında stabil
- [ ] App Store puanı 4.0+

---

## Faz 3 — Büyüme (sürekli)

Amaç: TAM genişletme + data-driven iterasyon.

### 3.1 İngilizce Lokalizasyon
- [ ] String Catalog'da EN sütununu doldur
- [ ] UI ekran görüntüleri EN versiyonu (App Store için)
- [ ] App Store metadata EN

### 3.2 Analytics
- [ ] Karar: Apple-only (App Analytics + MetricKit) yeterli mi yoksa product analytics (PostHog, Amplitude) gerekli mi
- [ ] Funnel: onboarding → ilk kelime → ilk review → 7 gün retention → conversion
- [ ] Privacy-respecting (no PII, opt-in)

### 3.3 İçerik Genişlemesi
- [ ] Phrasal verbs kütüphanesi (zaten PDF mevcut)
- [ ] Daha fazla CEFR seviyesi içerik
- [ ] Kullanıcı-paylaşımı kelime listeleri (Pro feature?)

---

## Faz 4 — Ertelenmiş Maddeler (sonra düşün)

Bu maddeler MVP için aşırı kapsam — yayın sonrası, gerçek kullanıcı sinyaliyle değerlendir.

- **Watch + iPad Companion** — iPhone'da product-market fit göstermeden ek platform yükü mantıksız
- **A/B Testing + Feature Flag** — İlk 1000 user altında istatistik anlamı yok, PostHog/GrowthBook privacy karmaşıklığı getirir
- **Deep Linking + Universal Links** — AASA dosyası + web hosting gerekir, MVP için düşük ROI
- **Sentry crash reporting** — MetricKit yetmiyorsa düşün, SDK boyutu + privacy ek deklarasyon

---

## Devam Etme Protokolü

Bir sonraki sessionda:
1. Bu dosyayı oku, en üstteki tamamlanmamış kutuyu bul.
2. `git log --oneline -10` ile son commit'i kontrol et — kutuyu işaretlemeyi unutmuş olabilirim.
3. O kutudaki işi yap, bittiğinde:
   - [ ] → [x] olarak işaretle
   - Commit mesajı: `roadmap: <kutu adı>` formatında
4. Faz sonu çıkış kriterlerine ulaşılınca o fazı bitmiş ilan et.

**Mevcut faz:** Faz 1 — yeni revizyonla başlangıç. İlk kutu: 1.0 Apple Intelligence Fallback.

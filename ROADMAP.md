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
- [ ] `CommonWordsLibrary.loadAll()` ve `OxfordWordsLibrary.loadAll()` startup'tan kaldır, `LibraryImportView` açıldığında `Task.detached` ile yükle
- [ ] Instruments Time Profiler ile app launch'ta JSON decode süresini ölç — hedef <500ms

#### 1.3.2 Force Unwrap Temizliği
- [ ] 120+ `!` operator → `guard let` / `if let` / default value
- [ ] `Word.card!` gibi optional ilişkilerde explicit nil handling
- [ ] **Neden kritik:** Reviewer test ederken bir force_cast crash'i = direkt rejection

#### 1.3.3 Datamuse Error UX
- [ ] `DatamuseClient` dönüş tipi `Result<[Suggestion], DatamuseError>`'a geç
- [ ] View'larda offline badge + retry butonu
- [ ] 4s timeout sonrası 1 kez retry

#### 1.3.4 SwiftData Unique Constraint Normalize
- [ ] `Word.term` save edilirken `lowercased() + trim`, görüntüleme için `displayTerm` ayrı
- [ ] "Apple" vs "apple" duplicate'ini engelle

#### 1.3.5 Kelime Ailesi / İlişki Yükleme Göstergesi
**Mevcut sorun:** Popover ve WordDetail'de kelime ailesi / synonyms / antonyms bölümleri yüklenirken (~5s AI streaming + Datamuse fetch) hiçbir gösterge yok. Yeni kullanıcı boş alanı "veri yok" sanıyor ve ekrandan çıkıyor.
- [ ] `WordQuickLookupCard.familySection` ve `inflectionSection`: veri henüz yokken `ProgressView` + "Kelime ailesi yükleniyor…" satırı
- [ ] `WordDetailView` family / relations bölümleri: aynı pattern, sectionHeader yanında küçük spinner (`ProgressView(.controlSize(.small))`)
- [ ] Yükleme bitince bölüm fade-in animation
- [ ] Datamuse arka plan doğrulaması ayrı: "Doğrulanıyor…" sub-badge (verified vs ai ikonu yüklenene kadar)

### 1.4 FSRS Unit Testleri (algoritma kullanıcı verisinin kalbi)
- [ ] `LexmindTests/FSRSSchedulerTests.swift` oluştur
- [ ] Bilinen input/output çiftleri (FSRS-4.5 paper'dan veya open-source referans)
- [ ] `again`, `hard`, `good`, `easy` her birinin stability/difficulty etkisi
- [ ] State transitions: `new → learning → review → relearning`
- [ ] Edge case: ilk review (reps=0), uzun gap (elapsedDays >> scheduledDays), zaman geriye giderse

### 1.5 SwiftData Migration Planı
- [ ] `VersionedSchema` enum'ı oluştur — şu anki şema `SchemaV1`
- [ ] `SchemaMigrationPlan` tanımla (boş bile olsa, sonraki sürüm için iskelet)
- [ ] `LexmindApp.swift`'te `ModelConfiguration` + migration plan'i bağla
- [ ] Test: önce eski şema ile DB oluştur, V2 ekle, lightweight migration çalıştığını doğrula

### 1.6 View Refactor (test edilebilirlik + bakım)
- [ ] `StudyView` 596 → <250 satır: `@Observable StudySession` ayrı sınıf, `RatingButtons` + `LookupPopover` subview'lar
- [ ] `WordDetailView` 625 → <300 satır: Header / Family / Relations / Examples / Notes section'lara böl
- [ ] `LibraryImportView` 507 → <300 satır: `ProgressOverlay` ayrı component
- [ ] Ortak `LookupPopover` 3 view'da kopyalanmış → tek component'e indir
- [ ] `HomeView`'daki iş mantığını `@Observable HomeModel`'e taşı

### 1.7 Observability — MetricKit + os.Logger
- [ ] `Lexmind/Services/Logging.swift`: subsystem bazlı `Logger` factory
- [ ] Tüm services'lerde `print` ve sessiz catch'leri `Logger.error`'a çevir
- [ ] `MXMetricManagerSubscriber` implementasyonu (LexmindApp seviyesinde)
- [ ] Critical path'lere signpost: `LibraryImporter.import`, `FSRSScheduler.schedule`, `ReadingPassageGenerator.generate`

### 1.8 String Catalog Altyapısı (sadece TR, EN sonra)
- [ ] `Localizable.xcstrings` oluştur — TR-only doldur
- [ ] `HomeView`, `StudyView`, `StatsView`, `SettingsView`, `OnboardingView` inline TR string'leri `String(localized:)` ile değiştir
- [ ] Sonra: `AddWordView`, `WordDetailView`, `WordsListView`, `LibraryImportView`, `ReadingPassageView`, `RootTabView`
- [ ] DataModels'deki `label` getter'ları
- [ ] EN sütununu Faz 3'te doldur

### 1.9 CI — Minimum
- [ ] `.github/workflows/ci.yml`: PR'da `xcodebuild test` çalıştır
- [ ] SwiftLint config (`.swiftlint.yml`) + workflow step
- [ ] README'ye build badge

### 1.10 App Store Connect Hazırlığı
- [ ] App Store Connect'te app record (bundle ID, kategori: Education, age rating)
- [ ] Marketing metadata (TR): app name, subtitle, açıklama, keywords, support URL
- [ ] Privacy Policy URL + Terms of Use URL (basit statik sayfa — GitHub Pages yeter)
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max), 6.5" — en az 3 ekran/cihaz
- [ ] App Preview video (opsiyonel)
- [ ] App icon 1024×1024 + tüm asset boyutları Assets.xcassets'te

### 1.11 Faz 1 Çıkış Kriterleri
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

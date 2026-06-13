#!/usr/bin/env python3
"""
Populates the English ("en") column in Localizable.xcstrings. The
source language is Turkish; this script walks every existing key and
attaches an `en` stringUnit with state="translated" so Xcode no longer
flags them as missing translations.

Map below is hand-authored — automated MT would butcher app-specific
copy ("hatırlat" vs "remind me", "Çalış" vs "Study"). New TR keys
added later will simply not appear here; rerun after Xcode harvests
and append the new pairs.
"""

import json
from pathlib import Path

XCSTRINGS = Path(__file__).resolve().parent.parent / "Lexmind" / "Resources" / "Localizable.xcstrings"

# TR → EN mapping. Order matches the keys file for reviewability.
TRANSLATIONS = {
    '"%@" analiz ediliyor…': 'Analyzing "%@"…',
    '"%@" kelimesi AI ile analiz edilip kütüphanene eklenecek.': '"%@" will be analyzed by AI and added to your library.',
    '"%@" listene eklendi': '"%@" added to your list',
    '"%@" silinecek. İçindeki %lld kelime silinmeyecek, sadece deste bağı kalkacak.': '"%1$@" will be deleted. The %2$lld words inside stay; only deck membership is removed.',
    '%@ destesi — %lld kelime': '%1$@ deck — %2$lld words',
    '%@. İlişkiler doğrulanamadı.': '%@. Relations could not be verified.',
    '%lld': '%lld',
    '%lld / %lld kelime': '%1$lld / %2$lld words',
    '%lld deste seçili • %lld benzersiz kelime': '%1$lld decks selected • %2$lld unique words',
    '%lld gün serisi': '%lld-day streak',
    '%lld kaldı': '%lld left',
    '%lld kelime': '%lld words',
    '%lld kelime · %lld yeni': '%1$lld words · %2$lld new',
    '%lld kelime eklendi, işlem yarıda durduruldu.': '%lld words added, import cancelled.',
    '%lld kelime kütüphaneye eklendi.': '%lld words added to your library.',
    '%lld tekrar': '%lld reviews',
    '%lld yeni': '%lld new',
    '%lld zaten ekli': '%lld already added',
    '%lld/%lld tekrar': '%1$lld/%2$lld reviews',
    '•': '•',
    'Adet': 'Count',
    'Adlandır': 'Rename',
    'AI ile Yeniden Analiz': 'Re-analyze with AI',
    'Akademik': 'Academic',
    'Analiz': 'Analysis',
    'Anlam alınamadı': 'Could not fetch meaning',
    'Anlam henüz eklenmedi.': 'No meaning yet.',
    'Aramayla eşleşen, destede olmayan kelime bulunamadı.': 'No words match your search outside this deck.',
    'Ayarlar': 'Settings',
    'Belirsiz': 'Unknown',
    'Bildirimler': 'Notifications',
    'Birleşim sonrası kaynak desteleri sil': 'Delete source decks after merge',
    'Birleşim sonucu yeni bir kullanıcı destesi oluşur.': 'Merging creates a new user deck.',
    'Birleştir': 'Merge',
    'Bitir': 'Finish',
    'Boş deste': 'Empty deck',
    'Bu desteye henüz kelime eklemedin. Sağ üstteki + ile ekleyebilirsin.': "You haven't added any words to this deck yet. Use the + in the top right to add some.",
    'Bu Desteyi Çalış': 'Study This Deck',
    'Bu isimde bir destem zaten var.': 'A deck with this name already exists.',
    'Bu kelimeyi kütüphanene eklemek ister misin?': 'Would you like to add this word to your library?',
    "Bu seviyede henüz kelime yok. Hazır Kütüphane'den ekleyebilirsin ya da sağ üstteki + ile manuel ekleyebilirsin.": "No words at this level yet. Add some from the built-in Library or use the + in the top right to add manually.",
    'Bugün': 'Today',
    'Bugün çalıştığın %lld kelimenin özeti.': 'A summary of the %lld words you studied today.',
    'Bugün çalıştığın %lld tekrar üzerinden bağlamlı bir metin.': 'A contextual passage based on the %lld reviews you completed today.',
    'Bugün çalıştığın kelimelerden bir paragraf hazırlanıyor.': 'A paragraph is being prepared from the words you studied today.',
    'Bugün gözden geçirilecek **%lld** kelimen var.': 'You have **%lld** words to review today.',
    'Bugünlük tüm tekrarlarını tamamladın 🎉': 'All your reviews are done for today 🎉',
    'Bugünün Kelimeleri': "Today's Words",
    'Bugünün Okuma Metni': "Today's Reading Passage",
    'Çalış': 'Study',
    'Çalışmaya Başla': 'Start Studying',
    'CEFR Seviyesi': 'CEFR Level',
    'Çekim Örnekleri': 'Inflection Examples',
    'Çekim Örnekleri (3)': 'Inflection Examples (3)',
    'Çekimli cümle %lld': 'Inflected sentence %lld',
    'Cevabı Göster': 'Show Answer',
    'Çıkar': 'Remove',
    'Cümle %lld': 'Sentence %lld',
    'Deste ismi': 'Deck name',
    'Deste İsmi': 'Deck Name',
    'Desteler': 'Decks',
    'Desteleri Birleştir': 'Merge Decks',
    'Desteyi sil': 'Delete deck',
    'Detayı Aç': 'Open Details',
    'Devam': 'Continue',
    'Dil': 'Language',
    'Doğa': 'Nature',
    'Doğrulanıyor…': 'Verifying…',
    'Durum': 'Status',
    'Duygular': 'Emotions',
    'Ekle': 'Add',
    'Ekle (%lld)': 'Add (%lld)',
    'Ekle ve Aç': 'Add and Open',
    'Eklendi': 'Added',
    'Eklenecek kelime kalmadı': 'No words left to add',
    'Ekleniyor…': 'Adding…',
    'Ekli': 'Added',
    'En az 2 deste seç.': 'Select at least 2 decks.',
    'Eş Anlamlı': 'Synonym',
    'Eşleşen kelime bulunamadı.': 'No matching words found.',
    'Filtre': 'Filter',
    'FSRS tabanlı kelime öğrenme': 'FSRS-based vocabulary learning',
    'Genel': 'General',
    'Gün': 'Day',
    'Günlük': 'Daily',
    'Günlük Hedef': 'Daily Goal',
    'Günlük tekrar': 'Daily reviews',
    'Hadi başlayalım': "Let's get started",
    'Hakkında': 'About',
    'Harika iş! 🎉': 'Great job! 🎉',
    'Hata': 'Error',
    'Hazır Desteler': 'Preset Decks',
    'Hazır Kütüphane': 'Built-in Library',
    'Hazır Kütüphaneden Ekle': 'Add from Built-in Library',
    'Hazırlanıyor…': 'Preparing…',
    'Hedef Deste': 'Target Deck',
    'Henüz bugün kelime çalışmadın': "You haven't studied any words yet today",
    'Henüz desten yok': "You don't have any decks yet",
    'Henüz IPA eklenmedi.': 'No IPA added yet.',
    'Henüz kelime eklemedin. İlk kelimelerini ekleyerek FSRS döngüsünü başlat.': "You haven't added any words yet. Start the FSRS cycle by adding your first words.",
    'Henüz tekrar yapılmadı.': 'No reviews yet.',
    'Hepsini ekle': 'Add all',
    'Hepsini Ekle (%lld)': 'Add All (%lld)',
    'Hiç deste yok.': 'No decks at all.',
    'İçe aktarıldı': 'Imported',
    'İlgili': 'Related',
    'İlişkiler doğrulanamadı, AI önerileri gösteriliyor.': 'Relations could not be verified; showing AI suggestions.',
    'İngilizce kelime': 'English word',
    'IPA (/ˈwɜːrd/)': 'IPA (/ˈwɜːrd/)',
    'İptal': 'Cancel',
    'İş': 'Work',
    'İş Dünyası': 'Business',
    'İşlem iptal edildi, kelime eklenmedi.': 'Operation cancelled, no words added.',
    'İstatistik': 'Stats',
    'İyi': 'Good',
    'Kapat': 'Close',
    'Kaydedilemedi: %@': 'Could not save: %@',
    'Kaydet': 'Save',
    'Kaynak Desteler': 'Source Decks',
    'Kelime': 'Word',
    'Kelime Ağı': 'Word Network',
    'Kelime Ailesi': 'Word Family',
    'Kelime ara': 'Search word',
    'Kelime bulunamadı': 'No word found',
    'Kelime Ekle': 'Add Word',
    'Kelime kütüphanesi hazırlanıyor…': 'Preparing the word library…',
    'Kelimeler': 'Words',
    'Kelimeler (0)': 'Words (0)',
    'Kelimeler ekleniyor…': 'Adding words…',
    'Kendi Destelerim': 'My Decks',
    'Kendi notunu yaz…': 'Write your note…',
    'Kişisel notların': 'Your personal notes',
    'Kök:': 'Root:',
    'Kolay': 'Easy',
    'Konular': 'Topics',
    "Kütüphane'den içe aktar veya manuel kelime ekle.": 'Import from the Library or add words manually.',
    'Kütüphanede ara': 'Search the library',
    'Lexmind': 'Lexmind',
    'Lexmind Pro': 'Lexmind Pro',
    'Listeme Ekle': 'Add to My List',
    'Metin oluşturulamadı': 'Passage could not be generated',
    'Metin yazılıyor…': 'Writing passage…',
    'Mevcut metin silinecek ve günün kelimelerinden yenisi üretilecek.': "The current passage will be deleted and a new one will be generated from today's words.",
    'Notlar': 'Notes',
    'Öğreniliyor': 'Learning',
    'Okuma Metni Oluştur': 'Generate Reading Passage',
    'Oluştur': 'Create',
    'Önce birkaç kelime çalış, sonra metnin hazır olsun.': "Study a few words first, then your passage will be ready.",
    'Önce kelime ekle': 'Add a word first',
    'Önerilen: 10 yeni / 50 tekrar': 'Suggested: 10 new / 50 reviews',
    'Örn. Seyahat': 'e.g. Travel',
    'Örnek cümle yok.': 'No example sentences.',
    'Örnek Cümleler (5)': 'Example Sentences (5)',
    'Örnekler': 'Examples',
    'Özet modu': 'Summary mode',
    'Sadece senin oluşturduğun desteler silinir; hazır CEFR desteleri silinmez.': 'Only the decks you created are deleted; preset CEFR decks are kept.',
    'Sağ üstteki + ile kendi desteni oluştur.': 'Use the + in the top right to create your own deck.',
    'Sağ üstteki + ile yeni bir kelime ekle.': 'Use the + in the top right to add a new word.',
    'Sağlık': 'Health',
    'Sayılabilirlik': 'Countability',
    'Senin için önerilen': 'Recommended for you',
    'Seviye & Konu': 'Level & Topic',
    'Seyahat': 'Travel',
    'Sil': 'Delete',
    'Şimdilik atla, kendim ekleyeceğim': "Skip for now, I'll add my own",
    'Sonuç yok': 'No results',
    'Şu an seçmek istemiyorum': "I don't want to choose right now",
    'Sürüm': 'Version',
    'Tamam': 'OK',
    'Tamamlandı': 'Completed',
    'Tanım': 'Definition',
    'Tanım ilk açışta cihazda dolar': 'Definition is filled in on first open',
    'Tek Kelime Ekle': 'Add a Single Word',
    'Teknoloji': 'Technology',
    'Tekrar': 'Again',
    'Tekrar dene': 'Try again',
    'Tekrar Dene': 'Try Again',
    'Tekrar Oluştur': 'Regenerate',
    'Tepki': 'Response',
    'Tüm kelimelerin bu destede zaten var.': 'All of your words are already in this deck.',
    'Tümü': 'All',
    'Tür (noun / verb …)': 'Part of speech (noun / verb …)',
    'Türkçe': 'Turkish',
    'Türkçe karşılık': 'Turkish equivalent',
    'Uygulama dili': 'App language',
    'Vazgeç': 'Cancel',
    'Veri': 'Data',
    'Yaklaşan tekrarlar': 'Upcoming reviews',
    'Yapay zeka kullanılamıyor': 'AI unavailable',
    'Yemek': 'Food',
    'Yeni': 'New',
    'Yeni bir metin oluşturulsun mu?': 'Generate a new passage?',
    'Yeni Deste': 'New Deck',
    'Yeni deste ismi': 'New deck name',
    'Yeni İsim': 'New Name',
    'Yeni kelime': 'New words',
    'Yeni Kelime': 'New Word',
    'Yeni kelime eklenmedi (hepsi zaten listende).': "No new words added (they're all already in your list).",
    'Yeni Kelime Öğren': 'Learn New Words',
    'Yeniden': 'Relearning',
    'Yeniden Adlandır': 'Rename',
    'Yükleniyor…': 'Loading…',
    'Zaten listende': 'Already in your list',
    'Zıt Anlamlı': 'Antonym',
    'Zor': 'Hard',
}


def main() -> int:
    data = json.loads(XCSTRINGS.read_text(encoding="utf-8"))
    strings = data["strings"]

    added = 0
    missing = []
    for key in strings.keys():
        if key not in TRANSLATIONS:
            missing.append(key)
            continue
        entry = strings[key]
        loc = entry.setdefault("localizations", {})
        loc["en"] = {
            "stringUnit": {
                "state": "translated",
                "value": TRANSLATIONS[key],
            }
        }
        added += 1

    XCSTRINGS.write_text(
        json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    print(f"Wrote {added} English translations to {XCSTRINGS}")
    if missing:
        print(f"WARNING: {len(missing)} keys had no translation:")
        for k in missing:
            print(f"  - {k!r}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

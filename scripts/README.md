# Oxford 5000 İçe Aktarma Boru Hattı

Bu klasör, `American_Oxford_5000.pdf`'i Lexmind'in
`Lexmind/Lexmind/Resources/oxford5000.json` kaynağına dönüştüren araçları içerir.

PDF aslında Oxford 5000'in Oxford 3000 *üstüne* eklediği ~1988 B2/C1
kelimesini içerir (5000 kelimenin tamamını değil).

## 1) PDF → starter JSON

```bash
python3 scripts/parse_oxford.py
```

Çıktı: `scripts/oxford5000_starter.json` (her satırı `{term, partOfSpeech, level}`).
Bağımlılık yok — Swift/PDFKit kullanır.

## 2) Starter → zenginleştirilmiş JSON (Anthropic batch API)

```bash
pip install anthropic
export ANTHROPIC_API_KEY=sk-ant-...

python3 scripts/enrich_oxford.py          # batch'i gönder
python3 scripts/enrich_oxford.py --poll   # tamamlanmasını bekle, sonucu yaz
```

- Model: `claude-haiku-4-5-20251001` (batch fiyatı: ~$1/M giriş, $5/M çıkış)
- 1988 istek × ~600 çıkış token ≈ **$8–25** tek seferlik
- Süre: 1–6 saat (batch kuyruğuna göre)
- Çıktı doğrudan `Lexmind/Lexmind/Resources/oxford5000.json`'a yazılır

Daha yüksek kalite için scriptin başındaki `MODEL` sabitini Sonnet ile
değiştirin (~$30–60).

## 3) Build

Xcode'da projeyi build edin. `OxfordWordsLibrary` JSON'u bundle'dan okur ve
`LibraryImportView`'ın "Oxford 5000" sekmesinde gösterir.

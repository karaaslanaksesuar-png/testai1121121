# Pazaryeri yönetim projesi

Skill, bağlantı geçmişi ve güvenli GET yardımcıları. Bu bir tam yönetim MCP sunucusu değildir; mevcut bağlantıları başka Codex oturumlarına taşımak için başlangıç projesidir.

## Bu bilgisayar

Trendyol ve Shopier anahtarları Desktop dosyalarından `scripts/Import-LegacySecrets.ps1` ile Windows kullanıcı/bilgisayarına bağlı şifreli `.secrets/credentials.clixml` dosyasına alınır. Anahtarlar GitHub'a yüklenmez. Kaynak Desktop dosyaları silinmez.

Hepsiburada anahtarı Pazarus'ta kayıtlıdır. Bu projede kopyası yoktur. BirFatura ve hubsan_dev anahtarlarını birbirine karıştırmayın. Shopify API erişimi henüz kurulmadı.

## Başka bilgisayar

1. Doğru GitHub deposunu klonlayın ve bu klasörü Codex'te proje olarak açın.
2. PowerShell'de `./scripts/Install-Skill.ps1` çalıştırın; yeni Codex sohbeti başlatın.
3. Trendyol ve Shopier anahtarlarını parola yöneticisi gibi güvenli bir kanaldan o bilgisayara sağlayın. Mevcut biçimdeki Desktop dosyaları varsa `./scripts/Import-LegacySecrets.ps1` çalıştırın. Windows şifreli vault dosyasını başka PC'ye kopyalamak işe yaramaz.
4. Alternatif olarak o oturuma TRENDYOL_SELLER_ID, TRENDYOL_BASIC_TOKEN, SHOPIER_TOKEN ortam değişkenlerini güvenli olarak sağlayın. Değerleri sohbet/Git'e yazmayın.
5. Pazarus hesabına giriş yapın; https://pazarus.io/mcp için OAuth bağlantısını kurun veya ChatGPT Pazarus uygulamasını bağlayın. Aynı hesapta oturum açmak bu projenin ve yerel anahtarların otomatik olarak gelmesini garanti etmez.
6. `$marketplace-operations` ile çalışın; önce yalnız okuma testi yapın.

Örnek okuma:

```powershell
./scripts/Invoke-MarketplaceRead.ps1 -Provider shopier -Path '/products/51623831' -OutputPath './responses/shopier-lavanta.json'
./scripts/Invoke-MarketplaceRead.ps1 -Provider trendyol -Path '/integration/product/sellers/{sellerId}/products?page=0&size=1' -OutputPath './responses/trendyol-products.json'
```

## Son bilinen durum — 2026-10-08

- Trendyol ürün okuma doğrulandı.
- Shopier Lavanta ürünü 51623831 oluşturuldu ve okundu.
- Hepsiburada → Pazarus bağlantı testi başarılı; 434 ürün önizlendi, içe aktarma başlatıldı. Tamamlanması henüz doğrulanmadı.
- Pazarus → ChatGPT/Codex OAuth henüz tamamlanmadı. AI yazma izinleri kapalı. Panelde opsiyonel fiyat/stok/yayın izinleri görülse de bunların gerçekten kullanılabilirliği test edilmedi.
- Shopify yalnız tarayıcıda gözlendi; API/MCP kurulmadı.
- GitHub hedefi https://github.com/karaaslanaksesuar-png/testai1121121. GitHub eklentisi depo sahibi karaaslanaksesuar-png hesabıyla yazma yetkili. Depo herkese açıktır; anahtarlar ve API yanıtları yüklenmez.

## Kaynaklar

- https://developer.shopier.com/llms.txt
- https://developers.hepsiburada.com/tr/
- https://pazarus.io/yardim/hepsiburada-entegrasyonu-kurulumu
- https://developers.openai.com/plugins/concepts/skills

İlk aşama için doğrudan API (Trendyol/Shopier) ve OAuth MCP (Pazarus) birlikte kullanılır. Merkezi özel MCP kurulumu ayrı bir dağıtım ve güvenlik çalışmasıdır; bu paket onu yapılmış gibi göstermez.

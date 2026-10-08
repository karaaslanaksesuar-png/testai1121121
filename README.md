# Pazaryeri yönetim projesi

Skill, bağlantı geçmişi ve güvenli GET yardımcıları. Bu bir tam yönetim MCP sunucusu değildir; mevcut bağlantıları başka Codex oturumlarına taşımak için başlangıç projesidir.

## Bu bilgisayar

Trendyol ve Shopier anahtarları Desktop dosyalarından `scripts/Import-LegacySecrets.ps1` ile Windows kullanıcı/bilgisayarına bağlı şifreli `.secrets/credentials.clixml` dosyasına alınır. Anahtarlar GitHub'a yüklenmez. Kaynak Desktop dosyaları silinmez.

Hepsiburada anahtarı Pazarus'ta kayıtlıdır. Bu projede kopyası yoktur. BirFatura ve hubsan_dev anahtarlarını birbirine karıştırmayın. Shopify API erişimi henüz kurulmadı.

## Başka bilgisayar

### Anahtarları tek parolalı paketle taşıma (Windows, PowerShell 7.4+)

Bu PC'de `pwsh -STA -File ./scripts/Portable-Vault.ps1 -Mode Export -Gui` çalıştırın. İki gizli parola penceresine aynı uzun ve benzersiz parolayı girin. Gerçek anahtarlar ekrana yazılmaz; `.secrets/marketplace-transfer.mpvault` oluşur. Parola unutulursa paket açılamaz. Kaynak yerel kasa değişmez.

Yalnız bu `.mpvault` dosyasını USB veya güvenli dosya aktarımıyla diğer PC'ye taşıyın; GitHub'a yüklemeyin. Diğer PC'de projeyi klonlayın ve `pwsh -STA -File ./scripts/Portable-Vault.ps1 -Mode Import -PackagePath 'C:/paketin/yolu/marketplace-transfer.mpvault' -Gui` çalıştırın. Parola gizli pencerede girilir; o PC'ye bağlı şifreli kasa oluşturulur. Mevcut kasa üzerine yazılmaz.

Paket mevcut yerel kasadaki Trendyol/Shopier anahtarlarını kapsar. Hepsiburada servis anahtarı yerel kasada olmadığından pakete eklenmez; Pazarus hesabından OAuth bağlantısı kullanılır. Shopify anahtarı henüz kurulmadı. Paket/parola Git'e veya sohbete konmaz. Format: AES-256-GCM, rastgele salt/nonce, PBKDF2-SHA256 600.000 tur; değişmiş paket veya yanlış parola reddedilir. Bu araç bağımsız güvenlik denetiminden geçmemiştir.

1. Doğru GitHub deposunu klonlayın ve bu klasörü Codex'te proje olarak açın.
2. PowerShell'de `./scripts/Install-Skill.ps1` çalıştırın; yeni Codex sohbeti başlatın.
3. Yukarıdaki taşınabilir paketi açın veya anahtarları parola yöneticisi gibi güvenli bir kanaldan sağlayın. Mevcut biçimdeki Desktop dosyaları varsa `./scripts/Import-LegacySecrets.ps1` çalıştırın. Windows şifreli vault dosyasını doğrudan başka PC'ye kopyalamak işe yaramaz.
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

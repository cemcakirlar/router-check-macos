# 🚀 RouterCheck (Native macOS)

ZTE mobil 4G/5G yönlendiricileri (MF286R, MC801A, MU5001 vb.) için %100 Swift ve SwiftUI ile yazılmış yerel (native) macOS yönetim ve teşhis uygulaması.

---

## ✨ Özellikler

- **%100 Yerel Swift & SwiftUI**: Electron, Node veya harici web wrapper'ları olmadan doğrudan macOS API'leri ile çalışır.
- **Pure Swift ZTE Client (`ZTEClient`)**:
  - `URLSession` tabanlı, otomatik çerez (cookie jar) yönetimi ve ZTE `goform` protokolü desteği.
  - Base64 şifrelenmiş kimlik doğrulama (`LOGIN_MULTI_USER`) ve oturum doğrulaması.
  - ATS (App Transport Security) yerel ağ desteği.
- **Canlı Sinyal Göstergesi**:
  - RSRP (dBm) ve SINR (dB) değerleri için derecelendirme (Mükemmel / İyi / Orta / Zayıf) ve görsel metreler.
  - Minimum, Ortalama ve Maksimum istatistikleri.
  - Hücre Kimliği (Cell ID - tek tıkla kopyalama) ve EARFCN gösterimi.
- **Anlık Hızlar**:
  - Canlı İndirme ve Yükleme hızları.
  - Akıcı trend sparkline grafikleri.
  - Toplam oturum veri aktarımı.
- **Ağ & Cihaz Bilgileri**:
  - WAN IP, LAN IP, Ağ Maskesi, DHCP durumu, WiFi MAC ve bağlı istemci sayısı.
  - Anlık PPP durumu ve tek tıkla PPP bağlantısını kesme/bağlama.
  - Aylık toplam veri, indirme, yükleme ve bağlantı süresi.
  - Donanım ve yazılım sürümleri, IMEI, MSISDN ve okunmamış SMS sayısı.
- **macOS Menu Bar (Menü Çubuğu) Desteği**:
  - Menü çubuğunda canlı durum (örn. `4G | -85dBm | 18dB`).
  - Hızlı menü: durumu durdurma/başlatma, manuel yenileme, ayarlar ve çıkış.
- **Ayarlar Paneli**:
  - Router IP/Host ve şifre yapılandırması.
  - Ayarlanabilir otomatik yoklama aralığı (1s, 2s, 3s, 5s, 10s).
  - Ayarların `~/Library/Application Support/RouterCheck/config.json` altında kalıcı olarak saklanması.

---

## 🛠️ Geliştirici ve Derleme Komutları

### Gereksinimler
- macOS 14.0+ (Sonoma, Sequoia veya üstü)
- Xcode Command Line Tools veya Swift 6+

### Kullanılabilir Komutlar (`Makefile`)

```bash
# 1. Yardım menüsünü görüntüle
make help

# 2. Debug derleyip arka planda başlat
make run

# 3. Canlı terminal logları ile ön planda çalıştır
make run-fg

# 4. Çalışan uygulamayı sonlandır
make stop

# 5. Debug veya Release derlemesi yap
make build      # Debug
make release    # Release
make app        # Release ve .app bundle (build/RouterCheck.app)

# 6. Dağıtım paketi oluştur (.zip ve .sha256)
make package    # dist/Router-Check-v<version>-macOS.zip

# 7. macOS /Applications dizinine kur
make install

# 8. Canlı macOS sistem loglarını dinle
make logs

# 9. Derleme önbelleğini ve çıktıları temizle
make clean
```

### Sürüm Yönetimi ve Yayınlama

Semantic Versioning standartlarına uygun otomatik sürüm artırımı, Changelog güncellemesi ve GitHub Release oluşturma:

```bash
# Sürüm artırma simülasyonu (güvenli test)
make release-dry-run

# Patch sürümü yayınla (örn. 1.0.0 -> 1.0.1)
make release-patch

# Minor sürümü yayınla (örn. 1.0.0 -> 1.1.0)
make release-minor

# Major sürümü yayınla (örn. 1.0.0 -> 2.0.0)
make release-major

# Belirli bir sürümü yayınla
make release-publish VERSION=1.2.0
```

---

## 🍏 macOS Kurulum ve Gatekeeper Notu

Uygulama Apple Developer ID sertifikası olmadan açık kaynak ad-hoc imzalandığı için macOS ilk açılışta *"Geliştirici doğrulanamadı"* uyarısı verebilir.

Uygulamayı açmak için Terminal'de şu komutu çalıştırmanız yeterlidir:
```bash
xattr -cr "/Applications/Router Check.app"
```
*Alternatif olarak: **Sistem Ayarları ➔ Gizlilik ve Güvenlik** altından **Yine de Aç** butonuna basabilirsiniz.*

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında açık kaynak olarak lisanslanmıştır. Detaylar için [LICENSE](LICENSE) ve [CHANGELOG.md](CHANGELOG.md) dosyalarını inceleyebilirsiniz.

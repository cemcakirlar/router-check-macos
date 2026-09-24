# 🚀 RouterCheck (Native macOS)

ZTE mobil 4G/5G yönlendiricileri (MF286R, MC801A, MU5001 vb.) için %100 Swift ve SwiftUI ile yazılmış yerel (native) macOS yönetim ve teşhis uygulaması.

---

## ✨ Aşama 1: PoC / MVP Özellikleri

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

## 🛠️ Derleme ve Çalıştırma

### Gereksinimler
- macOS 14.0+ (Sonoma, Sequoia veya üstü)
- Xcode Command Line Tools veya Swift 6+

### Komutlar

```bash
# 1. Hızlıca derleyip çalıştırmak için:
make run

# 2. Yalnızca .app bundle üretmek için:
make app
# Çıktı: build/RouterCheck.app

# 3. Geliştirici terminal derlemesi için:
swift run
```

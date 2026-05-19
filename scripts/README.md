# DEÜ Merkez Kampüsü Çevresel Analitik

Bu depo, Dokuz Eylül Üniversitesi Merkez Kampüsü için üretilen piksel tabanlı çevresel verilerin betimleyici istatistiklerini, parametrik olmayan testlerini, mekânsal bağımlılık analizlerini, NDBI yeniden örnekleme duyarlılık kontrolünü, GLCM pencere boyutu duyarlılık analizini ve figürlerini üretmek için düzenlenmiştir.

## Beklenen ham veri dosyaları

`data_raw/` klasörü içine şu dosyalar yerleştirilmelidir:

- `deu_kampus_piksel_2024_tumdegiskenler.csv`
- `deu_fakulte_piksel_2024_tumdegiskenler.csv`
- `deu_fakulte_ndbi_duyarlilik_2024.csv`
- `deu_fakulte_glcm_5x5_2024.csv`

## Web arayüzü notu

GitHub Pages yayını `docs/index.html` dosyasından çalışmaktadır. Web arayüzü iki CSV dosyasını `docs/` dizininden çağırmaktadır:

- `deu_kampus_piksel_2024_tumdegiskenler.csv`
- `deu_fakulte_piksel_2024_tumdegiskenler.csv`

Bu nedenle `docs/` dizinindeki iki CSV web sunumu için korunmuştur. R analizlerinde kullanılan düzenli ham veri kopyaları `data_raw/` klasöründe yer almaktadır.

## Google Earth Engine iş akışı

Google Earth Engine kodları `scripts/gee/` klasörü altında dört ayrı dosya halinde düzenlenmiştir:

- `01_gee_csv_export.js`: Kampüs ve fakülte düzeyindeki piksel CSV dosyalarını üretir.
- `02_gee_raster_export.js`: NDVI, NDBI, GLCM contrast ve GLCM homogeneity raster çıktılarını üretir.
- `03_gee_ndbi_sensitivity_export.js`: NDBI yeniden örnekleme duyarlılık kontrolü için nearest neighbor ve bilinear CSV çıktısını üretir.
- `04_gee_glcm_sensitivity_export.js`: GLCM 5x5 pencere boyutu duyarlılık kontrolü için fakülte CSV çıktısını üretir.

## R analiz iş akışı

R kodları `scripts/` klasörü altında modüler biçimde düzenlenmiştir:

1. `scripts/00_config.R`
2. `scripts/01_prepare_data.R`
3. `scripts/02_descriptive_stats.R`
4. `scripts/03_nonparametric_tests.R`
5. `scripts/04_spatial_analysis.R`
6. `scripts/05_main_figures.R`
7. `scripts/06_appendix_figures.R`
8. `scripts/07_ndbi_sensitivity_analysis.R`
9. `scripts/08_glcm_sensitivity_analysis.R`

Tek komutla çalıştırmak için:

```r
source("scripts/run_all.R")

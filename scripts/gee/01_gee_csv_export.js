/************************************************************
 DEU Main Campus
 Google Earth Engine CSV export
 NDVI + NDBI + GLCM Contrast + GLCM Homogeneity

 Cikti:
 1) deu_kampus_piksel_2024_tumdegiskenler.csv
 2) deu_fakulte_piksel_2024_tumdegiskenler.csv
************************************************************/

// ==========================================================
// 1) IMPORTS'TAN GEOMETRI URET
// Imports adlari:
// gsf, fenedebiyat, isletme, deniz, hukuk,
// muhendis, muhendis_II, mimari, turizm, kampusgenis
// ==========================================================
var kampus = ee.Geometry.Polygon([kampusgenis]);

var gsf_geom = ee.Geometry.Polygon([gsf]);
var fenedebiyat_geom = ee.Geometry.Polygon([fenedebiyat]);
var isletme_geom = ee.Geometry.Polygon([isletme]);
var deniz_geom = ee.Geometry.Polygon([deniz]);
var hukuk_geom = ee.Geometry.Polygon([hukuk]);
var mimari_geom = ee.Geometry.Polygon([mimari]);
var turizm_geom = ee.Geometry.Polygon([turizm]);

var muhendis_geom = ee.FeatureCollection([
  ee.Feature(ee.Geometry.Polygon([muhendis])),
  ee.Feature(ee.Geometry.Polygon([muhendis_II]))
]).geometry();

// ==========================================================
// 2) FAKULTE FEATURE COLLECTION
// ==========================================================
var fakulteler = ee.FeatureCollection([
  ee.Feature(gsf_geom, {fakulte: 'Guzel Sanatlar'}),
  ee.Feature(fenedebiyat_geom, {fakulte: 'Fen Edebiyat'}),
  ee.Feature(isletme_geom, {fakulte: 'Isletme'}),
  ee.Feature(deniz_geom, {fakulte: 'Denizcilik'}),
  ee.Feature(hukuk_geom, {fakulte: 'Hukuk'}),
  ee.Feature(muhendis_geom, {fakulte: 'Muhendislik'}),
  ee.Feature(mimari_geom, {fakulte: 'Mimarlik'}),
  ee.Feature(turizm_geom, {fakulte: 'Turizm'})
]);

// ==========================================================
// 3) HARITA
// ==========================================================
Map.centerObject(kampus, 14);
Map.addLayer(kampus, {color: 'ff00ff'}, 'Kampus Siniri');
Map.addLayer(
  fakulteler.style({color: 'ffffff', fillColor: '00000000', width: 2}),
  {},
  'Fakulte Sinirlari'
);

// ==========================================================
// 4) BULUT MASKESI
// SCL siniflari dislanir:
// 3 = cloud shadow, 8 = medium probability cloud,
// 9 = high probability cloud, 10 = cirrus, 11 = snow/ice
// ==========================================================
function maskS2(image) {
  var scl = image.select('SCL');
  var mask = scl.neq(3)
    .and(scl.neq(8))
    .and(scl.neq(9))
    .and(scl.neq(10))
    .and(scl.neq(11));

  return image.updateMask(mask);
}

// ==========================================================
// 5) SENTINEL-2 GORUNTUSU
// 2024 yaz doneminde bulut orani en dusuk sahne secilir
// ==========================================================
var koleksiyon = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(kampus)
  .filterDate('2024-06-01', '2024-08-31')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
  .map(maskS2)
  .sort('CLOUDY_PIXEL_PERCENTAGE');

var goruntu = ee.Image(koleksiyon.first());

print('Secilen goruntu:', goruntu);
print('Bulut orani:', goruntu.get('CLOUDY_PIXEL_PERCENTAGE'));
print('Tarih:', ee.Date(goruntu.get('system:time_start')).format('YYYY-MM-dd'));

// ==========================================================
// 6) NDVI + NDBI
// NDVI = (B8 - B4) / (B8 + B4)
// NDBI = (B11 - B8) / (B11 + B8)
// ==========================================================
var ndvi = goruntu.normalizedDifference(['B8', 'B4']).rename('ndvi');
var ndbi = goruntu.normalizedDifference(['B11', 'B8']).rename('ndbi');

// ==========================================================
// 7) GLCM ICIN NDVI'YI TAMSAYIYA CEVIR
// NDVI [-1, +1] araligi 0-200 tamsayi gri duzeylerine tasinir
// ==========================================================
var ndvi_int = ndvi
  .add(1)
  .multiply(100)
  .toInt()
  .rename('ndvi_int');

// ==========================================================
// 8) GLCM TEXTURE
// size = 3, average = true
// ==========================================================
var glcm = ndvi_int.glcmTexture({size: 3, average: true});

var contrast = glcm.select('ndvi_int_contrast').rename('glcm_contrast');
var homogeneity = glcm.select('ndvi_int_idm').rename('glcm_homogeneity');

// ==========================================================
// 9) TEK GORUNTUDE TUM BANTLAR
// ==========================================================
var analiz = ndvi
  .addBands(ndbi)
  .addBands(contrast)
  .addBands(homogeneity)
  .clip(kampus);

// ==========================================================
// 10) TUM KAMPUS PIKSEL ORNEKLEME
// ==========================================================
var kampus_samples = analiz.sample({
  region: kampus,
  scale: 10,
  geometries: true
});

var kampus_tablo = kampus_samples.map(function(f) {
  var xy = f.geometry().coordinates();

  return ee.Feature(null, {
    longitude: xy.get(0),
    latitude: xy.get(1),
    ndvi: f.get('ndvi'),
    ndbi: f.get('ndbi'),
    glcm_contrast: f.get('glcm_contrast'),
    glcm_homogeneity: f.get('glcm_homogeneity')
  });
});

// ==========================================================
// 11) FAKULTE BAZLI PIKSEL ORNEKLEME
// ==========================================================
var fakulte_samples = analiz.sampleRegions({
  collection: fakulteler,
  properties: ['fakulte'],
  scale: 10,
  geometries: true
});

var fakulte_tablo = fakulte_samples.map(function(f) {
  var xy = f.geometry().coordinates();

  return ee.Feature(null, {
    longitude: xy.get(0),
    latitude: xy.get(1),
    ndvi: f.get('ndvi'),
    ndbi: f.get('ndbi'),
    glcm_contrast: f.get('glcm_contrast'),
    glcm_homogeneity: f.get('glcm_homogeneity'),
    fakulte: f.get('fakulte')
  });
});

// ==========================================================
// 12) CSV EXPORT
// ==========================================================
Export.table.toDrive({
  collection: kampus_tablo,
  description: 'DEU_Kampus_Piksel_2024_TumDegiskenler',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_kampus_piksel_2024_tumdegiskenler',
  fileFormat: 'CSV',
  selectors: [
    'longitude',
    'latitude',
    'ndvi',
    'ndbi',
    'glcm_contrast',
    'glcm_homogeneity'
  ]
});

Export.table.toDrive({
  collection: fakulte_tablo,
  description: 'DEU_Fakulte_Piksel_2024_TumDegiskenler',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_fakulte_piksel_2024_tumdegiskenler',
  fileFormat: 'CSV',
  selectors: [
    'longitude',
    'latitude',
    'ndvi',
    'ndbi',
    'glcm_contrast',
    'glcm_homogeneity',
    'fakulte'
  ]
});

/************************************************************
 DEU Main Campus
 Google Earth Engine GLCM pencere boyutu duyarlilik exportu

 Amac:
 Ana analizde kullanilan 3x3 GLCM penceresine karsi 5x5 pencere
 boyutunun fakulte duzeyindeki doku olcumlerini ne kadar
 degistirdigini kontrol etmek.

 Cikti:
 deu_fakulte_glcm_5x5_2024.csv
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
// 6) NDVI
// GLCM ana analizle ayni NDVI tamsayi donusumunu kullanir.
// ==========================================================
var ndvi = goruntu.normalizedDifference(['B8', 'B4']).rename('ndvi');

var ndvi_int = ndvi
  .add(1)
  .multiply(100)
  .toInt()
  .rename('ndvi_int');

// ==========================================================
// 7) GLCM TEXTURE
// size = 5, average = true
// ==========================================================
var glcm_5x5 = ndvi_int.glcmTexture({size: 5, average: true});

var contrast_5x5 = glcm_5x5
  .select('ndvi_int_contrast')
  .rename('glcm_contrast_5x5');

var homogeneity_5x5 = glcm_5x5
  .select('ndvi_int_idm')
  .rename('glcm_homogeneity_5x5');

// ==========================================================
// 8) TEK GORUNTUDE DUYARLILIK BANTLARI
// ==========================================================
var analiz_5x5 = contrast_5x5
  .addBands(homogeneity_5x5)
  .clip(kampus);

// ==========================================================
// 9) FAKULTE BAZLI PIKSEL ORNEKLEME
// ==========================================================
var glcm_5x5_samples = analiz_5x5.sampleRegions({
  collection: fakulteler,
  properties: ['fakulte'],
  scale: 10,
  geometries: true
});

var glcm_5x5_tablo = glcm_5x5_samples.map(function(f) {
  var xy = f.geometry().coordinates();

  return ee.Feature(null, {
    longitude: xy.get(0),
    latitude: xy.get(1),
    fakulte: f.get('fakulte'),
    glcm_contrast_5x5: f.get('glcm_contrast_5x5'),
    glcm_homogeneity_5x5: f.get('glcm_homogeneity_5x5')
  });
});

// ==========================================================
// 10) CSV EXPORT
// ==========================================================
Export.table.toDrive({
  collection: glcm_5x5_tablo,
  description: 'DEU_Fakulte_GLCM_5x5_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_fakulte_glcm_5x5_2024',
  fileFormat: 'CSV',
  selectors: [
    'longitude',
    'latitude',
    'fakulte',
    'glcm_contrast_5x5',
    'glcm_homogeneity_5x5'
  ]
});

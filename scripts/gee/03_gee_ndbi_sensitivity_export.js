/************************************************************
 DEU Main Campus
 Google Earth Engine NDBI yeniden ornekleme duyarlilik exportu

 Amac:
 B11 bandinin 20 m cozunurlukten 10 m cozunurluge tasinmasinda
 nearest neighbor ve bilinear yaklasimlarinin NDBI sonuclarina
 etkisini kontrol etmek.

 Cikti:
 deu_fakulte_ndbi_duyarlilik_2024.csv
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
// 6) NDBI YENIDEN ORNEKLEME DUYARLILIK ANALIZI
// ==========================================================
var refProj_duyarlilik = goruntu.select('B8').projection();

var b8_duyarlilik = goruntu.select('B8');

// GEE varsayilan yeniden ornekleme mantigi nearest neighbor olarak korunur
var b11_nearest_duyarlilik = goruntu.select('B11')
  .reproject({
    crs: refProj_duyarlilik,
    scale: 10
  });

var b11_bilinear_duyarlilik = goruntu.select('B11')
  .resample('bilinear')
  .reproject({
    crs: refProj_duyarlilik,
    scale: 10
  });

var ndbi_nearest_duyarlilik = b11_nearest_duyarlilik
  .subtract(b8_duyarlilik)
  .divide(b11_nearest_duyarlilik.add(b8_duyarlilik))
  .rename('ndbi_nearest');

var ndbi_bilinear_duyarlilik = b11_bilinear_duyarlilik
  .subtract(b8_duyarlilik)
  .divide(b11_bilinear_duyarlilik.add(b8_duyarlilik))
  .rename('ndbi_bilinear');

var ndbi_duyarlilik = ndbi_nearest_duyarlilik
  .addBands(ndbi_bilinear_duyarlilik)
  .clip(kampus);

// ==========================================================
// 7) FAKULTE BAZLI ORNEKLEME
// ==========================================================
var ndbi_duyarlilik_samples = ndbi_duyarlilik.sampleRegions({
  collection: fakulteler,
  properties: ['fakulte'],
  scale: 10,
  geometries: true
});

var ndbi_duyarlilik_tablo = ndbi_duyarlilik_samples.map(function(f) {
  var xy = f.geometry().coordinates();

  return ee.Feature(null, {
    longitude: xy.get(0),
    latitude: xy.get(1),
    fakulte: f.get('fakulte'),
    ndbi_nearest: f.get('ndbi_nearest'),
    ndbi_bilinear: f.get('ndbi_bilinear')
  });
});

// ==========================================================
// 8) CSV EXPORT
// ==========================================================
Export.table.toDrive({
  collection: ndbi_duyarlilik_tablo,
  description: 'DEU_Fakulte_NDBI_Duyarlilik_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_fakulte_ndbi_duyarlilik_2024',
  fileFormat: 'CSV',
  selectors: [
    'longitude',
    'latitude',
    'fakulte',
    'ndbi_nearest',
    'ndbi_bilinear'
  ]
});

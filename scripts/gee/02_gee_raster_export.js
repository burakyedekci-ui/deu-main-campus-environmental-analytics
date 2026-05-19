/************************************************************
 DEU Main Campus
 Google Earth Engine raster export
 NDVI + NDBI + GLCM Contrast + GLCM Homogeneity

 Cikti:
 1) deu_kampus_ndvi_raster_2024.tif
 2) deu_kampus_ndbi_raster_2024.tif
 3) deu_kampus_glcm_contrast_raster_2024.tif
 4) deu_kampus_glcm_homogeneity_raster_2024.tif
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
// 6) NDVI + NDBI
// ==========================================================
var ndvi = goruntu.normalizedDifference(['B8', 'B4']).rename('ndvi');
var ndbi = goruntu.normalizedDifference(['B11', 'B8']).rename('ndbi');

// ==========================================================
// 7) GLCM ICIN NDVI'YI TAMSAYIYA CEVIR
// ==========================================================
var ndvi_int = ndvi
  .add(1)
  .multiply(100)
  .toInt()
  .rename('ndvi_int');

// ==========================================================
// 8) GLCM TEXTURE
// ==========================================================
var glcm = ndvi_int.glcmTexture({size: 3, average: true});

var contrast = glcm.select('ndvi_int_contrast').rename('glcm_contrast');
var homogeneity = glcm.select('ndvi_int_idm').rename('glcm_homogeneity');

// ==========================================================
// 9) RASTER KATMANLARI
// ==========================================================
var analiz = ndvi
  .addBands(ndbi)
  .addBands(contrast)
  .addBands(homogeneity)
  .clip(kampus);

// ==========================================================
// 10) GOSTERIM
// ==========================================================
Map.addLayer(
  analiz.select('ndvi'),
  {
    min: -0.2,
    max: 0.8,
    palette: ['8c510a', 'bf812d', 'dfc27d', '80cdc1', '35978f', '01665e']
  },
  'NDVI'
);

Map.addLayer(
  analiz.select('ndbi'),
  {
    min: -0.5,
    max: 0.5,
    palette: ['1a9850', '91cf60', 'd9ef8b', 'fee08b', 'fc8d59', 'd73027']
  },
  'NDBI'
);

Map.addLayer(
  analiz.select('glcm_contrast'),
  {
    min: 0,
    max: 300,
    palette: ['000000', '444444', '888888', 'dddddd', 'ffffff']
  },
  'GLCM Contrast'
);

Map.addLayer(
  analiz.select('glcm_homogeneity'),
  {
    min: 0,
    max: 1,
    palette: ['000000', '1a237e', '1565c0', '26a69a', 'dce775', 'fffde7']
  },
  'GLCM Homogeneity'
);

// ==========================================================
// 11) RASTER EXPORT
// ==========================================================
Export.image.toDrive({
  image: analiz.select('ndvi'),
  description: 'DEU_Kampus_NDVI_Raster_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_kampus_ndvi_raster_2024',
  region: kampus,
  scale: 10,
  crs: 'EPSG:4326',
  maxPixels: 1e13
});

Export.image.toDrive({
  image: analiz.select('ndbi'),
  description: 'DEU_Kampus_NDBI_Raster_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_kampus_ndbi_raster_2024',
  region: kampus,
  scale: 10,
  crs: 'EPSG:4326',
  maxPixels: 1e13
});

Export.image.toDrive({
  image: analiz.select('glcm_contrast'),
  description: 'DEU_Kampus_GLCM_Contrast_Raster_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_kampus_glcm_contrast_raster_2024',
  region: kampus,
  scale: 10,
  crs: 'EPSG:4326',
  maxPixels: 1e13
});

Export.image.toDrive({
  image: analiz.select('glcm_homogeneity'),
  description: 'DEU_Kampus_GLCM_Homogeneity_Raster_2024',
  folder: 'GEE_Exports',
  fileNamePrefix: 'deu_kampus_glcm_homogeneity_raster_2024',
  region: kampus,
  scale: 10,
  crs: 'EPSG:4326',
  maxPixels: 1e13
});

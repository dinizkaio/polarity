// Conditional export — escolhe implementação baseado em plataforma.
// Mobile/desktop: usa google_mobile_ads via ads_service_io.dart
// Web: usa stub que retorna no-op (web não suporta google_mobile_ads)
export 'ads_service_io.dart' if (dart.library.html) 'ads_service_stub.dart';

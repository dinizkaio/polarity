// Conditional export — escolhe implementação baseado em plataforma.
// Mobile: usa in_app_purchase via purchases_service_io.dart
// Web: usa stub que reporta loja indisponível
export 'purchases_service_io.dart' if (dart.library.html) 'purchases_service_stub.dart';

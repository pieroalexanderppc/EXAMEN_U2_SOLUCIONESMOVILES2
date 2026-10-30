/// Estados del permiso de ubicacion propios de la app. El ViewModel decide con
/// ellos, sin conocer la biblioteca de permisos.
enum EstadoPermisoUbicacion {
  noSolicitado,
  concedido,
  concedidoAproximado,
  denegado,
  denegadoPermanente,
}

/// Coordenadas obtenidas del telefono.
class Ubicacion {
  final double latitud;
  final double longitud;

  const Ubicacion({required this.latitud, required this.longitud});
}

import '../models/ubicacion.dart';

/// Consulta y solicita el permiso de ubicacion. El ViewModel recibe este
/// contrato desde fuera, asi las pruebas lo reemplazan por uno simulado.
abstract class PermisosUbicacion {
  Future<EstadoPermisoUbicacion> consultar();
  Future<EstadoPermisoUbicacion> solicitar();
  Future<void> abrirAjustes();
}

/// Lee la posicion actual del telefono.
abstract class LectorUbicacion {
  Future<Ubicacion> obtener();
}

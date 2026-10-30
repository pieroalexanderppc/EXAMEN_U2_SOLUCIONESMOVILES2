import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ubicacion.dart';
import 'permisos_ubicacion.dart';

/// Unico archivo de la app que usa las bibliotecas de permisos y de GPS.
class PermisosUbicacionDispositivo implements PermisosUbicacion {
  static const _claveDenegadoPermanente = 'ubicacion_denegada_permanente';

  @override
  Future<EstadoPermisoUbicacion> consultar() async {
    final concedido = await _estadoConcedido();
    if (concedido != null) return concedido;

    // Android solo informa el denegado permanente al solicitar, por eso se
    // recuerda en el telefono para no volver a pedirlo.
    final preferencias = await SharedPreferences.getInstance();
    if (preferencias.getBool(_claveDenegadoPermanente) ?? false) {
      return EstadoPermisoUbicacion.denegadoPermanente;
    }
    final yaDenego = await Permission.location.shouldShowRequestRationale;
    return yaDenego ? EstadoPermisoUbicacion.denegado : EstadoPermisoUbicacion.noSolicitado;
  }

  @override
  Future<EstadoPermisoUbicacion> solicitar() async {
    final respuesta = await Permission.location.request();

    // Con solo aproximada el plugin responde "denied" porque mira FINE, asi
    // que primero se revisa si de verdad quedo concedido.
    final concedido = await _estadoConcedido();
    if (concedido != null) return concedido;

    if (respuesta.isPermanentlyDenied) {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setBool(_claveDenegadoPermanente, true);
      return EstadoPermisoUbicacion.denegadoPermanente;
    }
    return EstadoPermisoUbicacion.denegado;
  }

  @override
  Future<void> abrirAjustes() async {
    await openAppSettings();
  }

  /// Devuelve el estado si hay permiso, o null si no lo hay.
  Future<EstadoPermisoUbicacion?> _estadoConcedido() async {
    final permiso = await Geolocator.checkPermission();
    if (permiso != LocationPermission.whileInUse && permiso != LocationPermission.always) {
      return null;
    }
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_claveDenegadoPermanente);
    final precision = await Geolocator.getLocationAccuracy();
    return precision == LocationAccuracyStatus.reduced
        ? EstadoPermisoUbicacion.concedidoAproximado
        : EstadoPermisoUbicacion.concedido;
  }
}

class LectorUbicacionDispositivo implements LectorUbicacion {
  @override
  Future<Ubicacion> obtener() async {
    // LocationManager evita el dialogo extra de precision de Google Play.
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
          forceLocationManager: true,
        ),
      );
      return Ubicacion(latitud: posicion.latitude, longitud: posicion.longitude);
    } on TimeoutException {
      // Sin lectura nueva (por ejemplo bajo techo) sirve la ultima conocida.
      final ultima = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
      if (ultima == null) rethrow;
      return Ubicacion(latitud: ultima.latitude, longitud: ultima.longitude);
    }
  }
}

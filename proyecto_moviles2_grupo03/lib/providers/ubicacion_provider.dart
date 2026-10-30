import 'package:flutter/foundation.dart';
import '../models/ubicacion.dart';
import '../services/permisos_ubicacion.dart';

/// Lo que la pantalla debe mostrar en cada momento del flujo.
enum PasoUbicacion {
  inicial,
  explicacion,
  buscando,
  ubicacionObtenida,
  ingresoManual,
  abrirAjustes,
}

/// ViewModel de "Usar mi ubicacion": elige un camino para cada estado del
/// permiso. No importa ninguna biblioteca de permisos ni de GPS.
class UbicacionProvider extends ChangeNotifier {
  final PermisosUbicacion _permisos;
  final LectorUbicacion _lector;

  EstadoPermisoUbicacion _estado = EstadoPermisoUbicacion.noSolicitado;
  PasoUbicacion _paso = PasoUbicacion.inicial;
  Ubicacion? _ubicacion;
  String? _ubicacionManual;
  String? _error;

  UbicacionProvider({
    required PermisosUbicacion permisos,
    required LectorUbicacion lector,
  })  : _permisos = permisos,
        _lector = lector;

  EstadoPermisoUbicacion get estado => _estado;
  PasoUbicacion get paso => _paso;
  Ubicacion? get ubicacion => _ubicacion;
  String? get ubicacionManual => _ubicacionManual;
  String? get error => _error;
  bool get esAproximada => _estado == EstadoPermisoUbicacion.concedidoAproximado;
  bool get tienePermiso => _estado == EstadoPermisoUbicacion.concedido || esAproximada;

  /// El usuario toca "Usar mi ubicacion". Solo la primera vez lleva a pedir el
  /// permiso; tras una negativa no se insiste.
  Future<void> tocarFuncion() async {
    _error = null;
    _estado = await _permisos.consultar();
    switch (_estado) {
      case EstadoPermisoUbicacion.concedido:
      case EstadoPermisoUbicacion.concedidoAproximado:
        await _ejecutar();
      case EstadoPermisoUbicacion.noSolicitado:
        _irA(PasoUbicacion.explicacion);
      case EstadoPermisoUbicacion.denegado:
        _irA(PasoUbicacion.ingresoManual);
      case EstadoPermisoUbicacion.denegadoPermanente:
        _irA(PasoUbicacion.abrirAjustes);
    }
  }

  /// "Continuar" en el dialogo propio.
  Future<void> continuarExplicacion() => _solicitar();

  /// "Ahora no" en el dialogo propio.
  void rechazarExplicacion() => _irA(PasoUbicacion.ingresoManual);

  /// "Permitir ubicacion": unico camino que vuelve a pedir el permiso.
  Future<void> permitirUbicacion() async {
    _estado = await _permisos.consultar();
    if (_estado == EstadoPermisoUbicacion.denegadoPermanente) {
      _irA(PasoUbicacion.abrirAjustes);
      return;
    }
    await _solicitar();
  }

  Future<void> abrirAjustes() => _permisos.abrirAjustes();

  /// Al volver de los ajustes el usuario pudo haber concedido el permiso.
  Future<void> alVolverALaApp() async {
    if (_paso != PasoUbicacion.ingresoManual && _paso != PasoUbicacion.abrirAjustes) return;
    _estado = await _permisos.consultar();
    if (tienePermiso) {
      _error = null;
      await _ejecutar();
    }
  }

  void guardarUbicacionManual(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    _ubicacionManual = limpio;
    _ubicacion = null;
    notifyListeners();
  }

  Future<void> _solicitar() async {
    _estado = await _permisos.solicitar();
    if (tienePermiso) {
      await _ejecutar();
    } else if (_estado == EstadoPermisoUbicacion.denegadoPermanente) {
      _irA(PasoUbicacion.abrirAjustes);
    } else {
      _irA(PasoUbicacion.ingresoManual);
    }
  }

  Future<void> _ejecutar() async {
    _irA(PasoUbicacion.buscando);
    try {
      _ubicacion = await _lector.obtener();
      _ubicacionManual = null;
      _irA(PasoUbicacion.ubicacionObtenida);
    } catch (e) {
      // GPS apagado o sin lectura: la funcion sigue disponible a mano.
      _error = 'No se pudo obtener tu ubicación';
      _irA(PasoUbicacion.ingresoManual);
    }
  }

  void _irA(PasoUbicacion paso) {
    _paso = paso;
    notifyListeners();
  }
}

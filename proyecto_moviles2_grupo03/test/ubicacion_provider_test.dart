import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_moviles2_grupo03/models/ubicacion.dart';
import 'package:proyecto_moviles2_grupo03/providers/ubicacion_provider.dart';
import 'package:proyecto_moviles2_grupo03/services/permisos_ubicacion.dart';

/// Reemplazo simulado del componente de permisos: responde lo que la prueba
/// indica y cuenta cuantas veces se solicito el permiso.
class PermisosSimulados implements PermisosUbicacion {
  EstadoPermisoUbicacion estado;
  final EstadoPermisoUbicacion respuestaSolicitud;
  int solicitudes = 0;

  PermisosSimulados(this.estado, {EstadoPermisoUbicacion? respuestaSolicitud})
      : respuestaSolicitud = respuestaSolicitud ?? estado;

  @override
  Future<EstadoPermisoUbicacion> consultar() async => estado;

  @override
  Future<EstadoPermisoUbicacion> solicitar() async {
    solicitudes++;
    estado = respuestaSolicitud;
    return estado;
  }

  @override
  Future<void> abrirAjustes() async {}
}

class LectorSimulado implements LectorUbicacion {
  int lecturas = 0;

  @override
  Future<Ubicacion> obtener() async {
    lecturas++;
    return const Ubicacion(latitud: -18.0066, longitud: -70.2463);
  }
}

void main() {
  late LectorSimulado lector;

  UbicacionProvider crear(PermisosSimulados permisos) =>
      UbicacionProvider(permisos: permisos, lector: lector);

  setUp(() => lector = LectorSimulado());

  group('Item 4: flujo de permisos', () {
    test('(a) al crear el ViewModel no se solicita ningun permiso', () {
      final permisos = PermisosSimulados(EstadoPermisoUbicacion.noSolicitado);

      final provider = crear(permisos);

      expect(permisos.solicitudes, 0);
      expect(lector.lecturas, 0);
      expect(provider.paso, PasoUbicacion.inicial);
    });

    test('(b) con el permiso concedido, al tocar la funcion esta se ejecuta', () async {
      final permisos = PermisosSimulados(EstadoPermisoUbicacion.concedido);
      final provider = crear(permisos);

      await provider.tocarFuncion();

      expect(lector.lecturas, 1);
      expect(provider.paso, PasoUbicacion.ubicacionObtenida);
      expect(provider.ubicacion?.latitud, -18.0066);
      expect(provider.ubicacion?.longitud, -70.2463);
      expect(permisos.solicitudes, 0);
    });

    test('(c) con denegado permanente se ofrecen los ajustes y no se solicita', () async {
      final permisos = PermisosSimulados(EstadoPermisoUbicacion.denegadoPermanente);
      final provider = crear(permisos);

      await provider.tocarFuncion();

      expect(provider.paso, PasoUbicacion.abrirAjustes);
      expect(permisos.solicitudes, 0);
      expect(lector.lecturas, 0);
    });
  });

  group('Item 5: permiso parcial y no insistir', () {
    test('(a) con ubicacion aproximada la funcion se ejecuta y el aviso queda visible', () async {
      final permisos = PermisosSimulados(EstadoPermisoUbicacion.concedidoAproximado);
      final provider = crear(permisos);

      await provider.tocarFuncion();

      expect(lector.lecturas, 1);
      expect(provider.paso, PasoUbicacion.ubicacionObtenida);
      expect(provider.esAproximada, isTrue);
    });

    test('(b) si deniega y vuelve a tocar, el permiso se solicito una sola vez', () async {
      final permisos = PermisosSimulados(
        EstadoPermisoUbicacion.noSolicitado,
        respuestaSolicitud: EstadoPermisoUbicacion.denegado,
      );
      final provider = crear(permisos);

      await provider.tocarFuncion();
      await provider.continuarExplicacion();
      await provider.tocarFuncion();

      expect(permisos.solicitudes, 1);
      expect(provider.paso, PasoUbicacion.ingresoManual);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ubicacion_provider.dart';

/// Panel de la pantalla principal con la funcion "Usar mi ubicacion".
class PanelUbicacion extends StatefulWidget {
  const PanelUbicacion({super.key});

  @override
  State<PanelUbicacion> createState() => _PanelUbicacionState();
}

class _PanelUbicacionState extends State<PanelUbicacion> with WidgetsBindingObserver {
  final _controlador = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlador.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<UbicacionProvider>().alVolverALaApp();
    }
  }

  Future<void> _usarUbicacion() async {
    final provider = context.read<UbicacionProvider>();
    await provider.tocarFuncion();
    if (!mounted || provider.paso != PasoUbicacion.explicacion) return;

    final continuar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Usar tu ubicación?'),
        content: const Text(
          'Pondera la usa solo para mostrar dónde estás ahora. '
          'No la guarda ni la comparte, y puedes escribir tu ciudad a mano.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continuar')),
        ],
      ),
    );
    if (continuar == true) {
      await provider.continuarExplicacion();
    } else {
      provider.rechazarExplicacion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UbicacionProvider>();
    final scheme = Theme.of(context).colorScheme;
    final paso = provider.paso;
    final conIngresoManual = paso == PasoUbicacion.ingresoManual || paso == PasoUbicacion.abrirAjustes;
    final ubicacion = provider.ubicacion;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: paso == PasoUbicacion.buscando ? null : _usarUbicacion,
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Usar mi ubicación'),
            ),
            if (paso == PasoUbicacion.buscando) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            if (ubicacion != null) ...[
              const SizedBox(height: 12),
              Text('Latitud: ${ubicacion.latitud}'),
              Text('Longitud: ${ubicacion.longitud}'),
            ],
            if (provider.esAproximada && ubicacion != null) ...[
              const SizedBox(height: 8),
              Text('Estás usando ubicación aproximada', style: TextStyle(color: scheme.primary)),
            ],
            if (provider.error != null) ...[
              const SizedBox(height: 12),
              Text(provider.error!, style: TextStyle(color: scheme.error)),
            ],
            if (paso == PasoUbicacion.abrirAjustes) ...[
              const SizedBox(height: 12),
              const Text('El permiso de ubicación está bloqueado. Puedes activarlo en los ajustes de la app.'),
              const SizedBox(height: 8),
              FilledButton(onPressed: provider.abrirAjustes, child: const Text('Abrir ajustes')),
            ],
            if (paso == PasoUbicacion.ingresoManual && !provider.tienePermiso) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: provider.permitirUbicacion, child: const Text('Permitir ubicación')),
            ],
            if (conIngresoManual) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _controlador,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Ciudad o dirección'),
                onSubmitted: provider.guardarUbicacionManual,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => provider.guardarUbicacionManual(_controlador.text),
                child: const Text('Guardar ubicación'),
              ),
            ],
            if (provider.ubicacionManual != null) ...[
              const SizedBox(height: 12),
              Text('Ubicación: ${provider.ubicacionManual}'),
            ],
          ],
        ),
      ),
    );
  }
}

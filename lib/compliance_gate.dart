import 'package:battery_saved/battery_api.dart';
import 'package:flutter/material.dart';
import 'compliance_config.dart';
import 'oem_confirmations_store.dart';

class ComplianceGate extends StatefulWidget {
  final Widget child;
  final bool requireIgnoreOptimizations; // en tu caso: true
  const ComplianceGate({
    super.key,
    required this.child,
    this.requireIgnoreOptimizations = true,
  });

  @override
  State<ComplianceGate> createState() => _ComplianceGateState();
}

class _ComplianceGateState extends State<ComplianceGate>
    with WidgetsBindingObserver {
  BatteryComplianceStatus? _status;
  ComplianceConfig? _config;
  OemProfile? _profile;

  bool _loading = true;
  Set<String> _confirmed = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    final cfg = await ComplianceConfig.loadAsset();
    final st = await BatteryComplianceApi.status();
    final profile = cfg.resolveForFlexible(
      manufacturer: st.manufacturer,
      brand: st.brand,
      model: st.model,
    );

    final confirmed = await OemConfirmationsStore.getConfirmedIds(
      configVersion: cfg.version,
      profileId: profile.id,
    );

    print(  '--------------- $confirmed' );

    setState(() {
      _config = cfg;
      _status = st;
      _profile = profile;
      _confirmed = confirmed;
      _loading = false;
    });
  }
  

  Future<void> _refreshStatus() async {
    final st = await BatteryComplianceApi.status();
    final cfg = _config;
    if (cfg == null) return;

    final profile = cfg.resolveForFlexible(
      manufacturer: st.brand,
      brand: st.brand,
      model: st.model,
    );
    final confirmed = await OemConfirmationsStore.getConfirmedIds(
      configVersion: cfg.version,
      profileId: profile.id,
    );

    setState(() {
      _status = st;
      _profile = profile;
      _confirmed = confirmed;
    });
  }

  bool get _hardBlocked {
    final st = _status!;
    if (st.backgroundRestricted) return true;
    if (widget.requireIgnoreOptimizations && !st.ignoringOptimizations) {
      return true;
    }
    return false;
  }

  bool get _oemBlocked {
    final st = _status!;
    final p = _profile!;
    if (!p.requiresUserConfirmation) return false;

    final requiredIds = p.userConfirmations.map((e) => e['id']!).toSet();
    // Si no requiere ignoreOptimizations, igual puedes pedir OEM confirmations,
    // pero en tu caso es requisito estricto.
    return !requiredIds.difference(_confirmed).isEmpty;
  }

  bool get _blocked => _hardBlocked || _oemBlocked;

  Future<void> _toggleConfirm(String id, bool value) async {
    final cfg = _config!;
    final profile = _profile!;
    final next = Set<String>.from(_confirmed);
    if (value) {
      next.add(id);
    } else {
      next.remove(id);
    }
    setState(() => _confirmed = next);

    await OemConfirmationsStore.setConfirmedIds(
      configVersion: cfg.version,
      profileId: profile.id,
      ids: next,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (!_blocked) return widget.child;

    final st = _status!;
    final p = _profile!;
    final showPowerSaveWarning = st.powerSaveMode;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Configuración requerida',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Dispositivo: ${st.manufacturer} / ${st.model} (Android ${st.sdkInt})'),
                const SizedBox(height: 16),

                // HARD BLOCKS
                if (st.backgroundRestricted) _blockCard(
                  title: 'Restricción en segundo plano',
                  desc: 'Android está restringiendo esta app. Debes quitar la restricción desde ajustes.',
                  actions: [
                    ElevatedButton(
                      onPressed: BatteryComplianceApi.openAppDetails,
                      child: const Text('Abrir ajustes de la app'),
                    ),
                  ],
                ),

                if (widget.requireIgnoreOptimizations && !st.ignoringOptimizations)
                  _blockCard(
                    title: 'Optimización de batería',
                    desc: 'Debes permitir “Sin restricciones / No optimizar” para esta app.',
                    actions: [
                      ElevatedButton(
                        onPressed: BatteryComplianceApi.requestIgnoreOptimizations,
                        child: const Text('Permitir “Sin restricciones”'),
                      ),
                      TextButton(
                        onPressed: BatteryComplianceApi.openOptimizationSettings,
                        child: const Text('Abrir optimización de batería'),
                      ),
                    ],
                  ),

                if (showPowerSaveWarning)
                  _warnCard(
                    title: 'Ahorro de batería activo',
                    desc: 'Puede afectar sincronización y notificaciones. Recomendado desactivarlo mientras uses la app.',
                  ),

                const SizedBox(height: 16),

                // OEM STEPS + CONFIRMATIONS
                if (p.requiresUserConfirmation) ...[
                  Text(
                    'Pasos adicionales (${p.title})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...p.steps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $s'),
                  )),
                  const SizedBox(height: 12),
                  const Text(
                    'Confirma cuando lo hayas configurado:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...p.userConfirmations.map((c) {
                    final id = c['id']!;
                    final label = c['label']!;
                    final why = c['why'] ?? '';
                    final checked = _confirmed.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) => _toggleConfirm(id, v == true),
                      title: Text(label),
                      subtitle: why.isEmpty ? null : Text(why),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],

                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _refreshStatus,
                  child: const Text('Revalidar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _blockCard({
    required String title,
    required String desc,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc),
            const SizedBox(height: 8),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _warnCard({required String title, required String desc}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(desc),
          ],
        ),
      ),
    );
  }
}

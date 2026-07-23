import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../world/pip/pip_params.dart';
import '../../world/world_view.dart';

/// Le banc d'essai de Pip.
///
/// C'est le remplacement de Rive : un curseur par paramètre, réglés au
/// hot-reload sur Windows. Cet écran n'est jamais livré en production.
/// Voir CONCEPT.md §10.
class DevBenchScreen extends StatefulWidget {
  const DevBenchScreen({super.key});

  @override
  State<DevBenchScreen> createState() => _DevBenchScreenState();
}

class _DevBenchScreenState extends State<DevBenchScreen> {
  PipParams _p = PipParams.defaults;
  PipPose _pose = PipPose.walking;
  double _scrollSpeed = 34;
  double _hour = 12;
  bool _followClock = false;
  bool _showCairns = true;
  bool _showDecor = true;

  void _reset() => setState(() {
    _p = PipParams.defaults;
    _pose = PipPose.walking;
    _scrollSpeed = 34;
    _hour = 12;
    _followClock = false;
    _showCairns = true;
    _showDecor = true;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banc d\'essai'),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Réinitialiser',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(AppRadii.card),
              child: SizedBox(
                height: 260,
                child: WorldView(
                  params: _p,
                  pose: _pose,
                  scrollSpeed: _scrollSpeed,
                  showCairns: _showCairns,
                  showDecor: _showDecor,
                  autoScalePip: false,
                  hourOverride: _followClock ? null : _hour,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                _section('Pose et réactions'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final pose in PipPose.values)
                      ChoiceChip(
                        label: Text(pose.label),
                        selected: _pose == pose,
                        onSelected: (_) => setState(() => _pose = pose),
                      ),
                  ],
                ),

                _section('Pip'),
                _slider(
                  'Taille',
                  _p.scale,
                  0.5,
                  3,
                  (v) => setState(() => _p = _p.copyWith(scale: v)),
                  decimals: 2,
                ),
                _slider(
                  'Vitesse de marche',
                  _p.walkSpeed,
                  0,
                  4,
                  (v) => setState(() => _p = _p.copyWith(walkSpeed: v)),
                  decimals: 2,
                ),
                _slider(
                  'Rebond',
                  _p.bobAmplitude,
                  0,
                  10,
                  (v) => setState(() => _p = _p.copyWith(bobAmplitude: v)),
                ),
                _slider(
                  'Squash',
                  _p.squash,
                  0,
                  0.2,
                  (v) => setState(() => _p = _p.copyWith(squash: v)),
                  decimals: 3,
                ),
                _slider(
                  'Débattement des jambes',
                  _p.legSwing,
                  0,
                  12,
                  (v) => setState(() => _p = _p.copyWith(legSwing: v)),
                ),
                _slider(
                  'Débattement des bras',
                  _p.armSwing,
                  0,
                  12,
                  (v) => setState(() => _p = _p.copyWith(armSwing: v)),
                ),
                _slider(
                  'Veine minérale',
                  _p.veinOpacity,
                  0,
                  1,
                  (v) => setState(() => _p = _p.copyWith(veinOpacity: v)),
                  decimals: 2,
                ),
                _slider(
                  'Ondulation du fanion',
                  _p.pennantWave,
                  0,
                  12,
                  (v) => setState(() => _p = _p.copyWith(pennantWave: v)),
                ),

                _section('Équipement'),
                _toggle(
                  'Fanion',
                  _p.showPennant,
                  (v) => setState(() => _p = _p.copyWith(showPennant: v)),
                ),
                _toggle(
                  'Sac à dos',
                  _p.showBackpack,
                  (v) => setState(() => _p = _p.copyWith(showBackpack: v)),
                ),
                _toggle(
                  'Lanterne',
                  _p.showLantern,
                  (v) => setState(() => _p = _p.copyWith(showLantern: v)),
                ),

                _section('Yeux'),
                _slider(
                  'Rayon',
                  _p.eyeRadius,
                  1,
                  6,
                  (v) => setState(() => _p = _p.copyWith(eyeRadius: v)),
                  decimals: 2,
                ),
                _slider(
                  'Écartement',
                  _p.eyeSpacing,
                  3,
                  14,
                  (v) => setState(() => _p = _p.copyWith(eyeSpacing: v)),
                ),
                _slider(
                  'Période de clignement',
                  _p.blinkPeriod,
                  1,
                  8,
                  (v) => setState(() => _p = _p.copyWith(blinkPeriod: v)),
                ),
                _slider(
                  'Sourcils',
                  _p.browLift,
                  0,
                  2,
                  (v) => setState(() => _p = _p.copyWith(browLift: v)),
                  decimals: 2,
                ),
                _slider(
                  'Joues rosées',
                  _p.blushOpacity,
                  0,
                  1,
                  (v) => setState(() => _p = _p.copyWith(blushOpacity: v)),
                  decimals: 2,
                ),

                _section('Monde'),
                _slider(
                  'Défilement',
                  _scrollSpeed,
                  0,
                  140,
                  (v) => setState(() => _scrollSpeed = v),
                  decimals: 0,
                ),
                _slider(
                  'Heure du jour',
                  _hour,
                  0,
                  24,
                  _followClock ? null : (v) => setState(() => _hour = v),
                  decimals: 1,
                ),
                _toggle(
                  'Suivre l\'horloge réelle',
                  _followClock,
                  (v) => setState(() => _followClock = v),
                ),
                _toggle(
                  'Cairns',
                  _showCairns,
                  (v) => setState(() => _showCairns = v),
                ),
                _toggle(
                  'Décor (arbres, rochers, herbe, nuages, étoiles)',
                  _showDecor,
                  (v) => setState(() => _showDecor = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSoft,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
        ),
        value: value,
        onChanged: onChanged,
      );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double>? onChanged, {
    int decimals = 1,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 168,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(decimals),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

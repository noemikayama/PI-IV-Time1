// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, restauração, remoção e
// persistência dos vínculos do cavalo.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do modal reutilizável de edição dos vínculos do cavalo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/destructive_confirmation_dialog.dart';
import 'package:horse_life/features/horses/data/models/horse_profile_data.dart';
import 'package:horse_life/features/horses/data/repositories/horse_profile_repository.dart';

/// Abre a edição modal e devolve o perfil atualizado quando a persistência
/// termina; fechar ou cancelar devolve `null`.
Future<HorseProfileData?> showHorseRelationshipsDialog(
  BuildContext context, {
  required HorseProfileData horse,
  required HorseProfileRepository repository,
}) => showDialog<HorseProfileData>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      _HorseRelationshipsDialog(horse: horse, repository: repository),
);

class _HorseRelationshipsDialog extends StatefulWidget {
  const _HorseRelationshipsDialog({
    required this.horse,
    required this.repository,
  });

  final HorseProfileData horse;
  final HorseProfileRepository repository;

  @override
  State<_HorseRelationshipsDialog> createState() =>
      _HorseRelationshipsDialogState();
}

class _HorseRelationshipsDialogState extends State<_HorseRelationshipsDialog> {
  // --- Cópia local dos vínculos e campos de substituição --------------------
  late HorseProfilePerson? _athlete;
  late HorseProfilePerson? _trainer;
  late final TextEditingController _athleteEmail;
  late final TextEditingController _trainerEmail;
  bool _saving = false;
  String? _error;

  // --- Inicialização, restauração e descarte --------------------------------

  @override
  void initState() {
    super.initState();
    _athleteEmail = TextEditingController();
    _trainerEmail = TextEditingController();
    _restoreDatabaseValues();
  }

  void _restoreDatabaseValues() {
    _athlete = widget.horse.athlete;
    _trainer = widget.horse.trainers.isEmpty
        ? null
        : widget.horse.trainers.first;
    _athleteEmail.clear();
    _trainerEmail.clear();
    _error = null;
  }

  @override
  void dispose() {
    _athleteEmail.dispose();
    _trainerEmail.dispose();
    super.dispose();
  }

  bool get _removedAthlete =>
      widget.horse.athlete != null && _athlete?.id != widget.horse.athlete?.id;

  bool get _removedTrainer {
    final original = widget.horse.trainers.isEmpty
        ? null
        : widget.horse.trainers.first;
    return original != null && _trainer?.id != original.id;
  }

  // --- Confirmação e persistência -------------------------------------------
  // Uma remoção exige confirmação destrutiva. Inclusões e remoções são então
  // reunidas em uma única operação do repositório e o novo perfil fecha o modal.

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final removed = _removedAthlete || _removedTrainer;
    if (removed) {
      final person = _removedTrainer
          ? widget.horse.trainers.first
          : widget.horse.athlete!;
      final kind = _removedTrainer ? 'treinador' : 'atleta';
      final confirmed = await showDestructiveConfirmationDialog(
        context,
        title: 'Tem certeza que quer desvincular esse usuário?',
        message:
            'Se você continuar essa operação, ${person.name} perderá o '
            'acesso a esse animal e aos recursos que o vínculo de $kind '
            'garantem a ele. Essa remoção depende apenas de você. Tem '
            'certeza que deseja prosseguir?\nObs.: Não é possível '
            'desvincular um treinador que seja autor do plano ativo do '
            'cavalo.',
      );
      if (!mounted) return;
      if (!confirmed) {
        setState(_restoreDatabaseValues);
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.updateRelationships(
        widget.horse.id,
        removeAthlete: _removedAthlete,
        removeTrainer: _removedTrainer,
        athleteEmail: _athlete == null ? _athleteEmail.text : null,
        trainerEmail: _trainer == null ? _trainerEmail.text : null,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _relationshipErrorMessage(error);
      });
    }
  }

  // --- Composição do formulário --------------------------------------------

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Dialog(
      key: const Key('horse-relationships-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 26, 28, 28 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edição de vínculos',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    key: const Key('close-horse-relationships-dialog'),
                    tooltip: 'Fechar',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 34),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Para vincular outros usuários ao seu animal, digite o '
                'e-mail de cada um deles nos campos correspondentes ao tipo '
                'de vínculo que eles possuem.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _RelationshipField(
                label: 'Treinador',
                person: _trainer,
                controller: _trainerEmail,
                fieldKey: const Key('horse-trainer-relationship-field'),
                unlinkKey: const Key('remove-horse-trainer-relationship'),
                onUnlink: _saving
                    ? null
                    : () => setState(() => _trainer = null),
              ),
              const SizedBox(height: 18),
              _RelationshipField(
                label: 'Atleta',
                person: _athlete,
                controller: _athleteEmail,
                fieldKey: const Key('horse-athlete-relationship-field'),
                unlinkKey: const Key('remove-horse-athlete-relationship'),
                onUnlink: _saving
                    ? null
                    : () => setState(() => _athlete = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  key: const Key('horse-relationships-error'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 60,
                child: OutlinedButton(
                  key: const Key('save-horse-relationships-button'),
                  onPressed: _saving ? null : _save,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seaGreen,
                    side: const BorderSide(color: AppColors.seaGreen, width: 2),
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator()
                      : Text(
                          'Salvar',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.seaGreen),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alterna entre a pessoa atualmente vinculada e o campo de e-mail usado para
/// cadastrar sua substituição.
class _RelationshipField extends StatelessWidget {
  const _RelationshipField({
    required this.label,
    required this.person,
    required this.controller,
    required this.fieldKey,
    required this.unlinkKey,
    required this.onUnlink,
  });

  final String label;
  final HorseProfilePerson? person;
  final TextEditingController controller;
  final Key fieldKey;
  final Key unlinkKey;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextField(
        key: fieldKey,
        controller: person == null ? controller : null,
        readOnly: person != null,
        decoration: InputDecoration(
          hintText: person?.name ?? 'exemplo@email.com',
          filled: true,
          fillColor: const Color(0xFFE8E8E8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          suffixIcon: person == null
              ? null
              : IconButton(
                  key: unlinkKey,
                  tooltip: 'Desvincular $label',
                  onPressed: onUnlink,
                  color: AppColors.error,
                  icon: const Icon(Icons.link_off_rounded),
                ),
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
      ),
    ],
  );
}

String _relationshipErrorMessage(Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  final text = error.toString();
  if (text.contains('plano ativo')) {
    return 'Não é possível desvincular o treinador porque ele é autor '
        'do plano ativo do cavalo.';
  }
  return 'Não foi possível salvar os vínculos. Confira os e-mails e tente '
      'novamente.';
}

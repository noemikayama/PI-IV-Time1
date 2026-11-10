// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição do card local pelo ProfileHorseCard compartilhado,
// com suporte à imagem remota e ao fallback visual.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da tela, do carregamento e dos estados apresentados.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de perfil do responsável com estados de carga,
// erro e vazio, listagem de cavalos e ações de edição, cadastro e saída.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_identity_header.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_horse_card.dart';
import 'package:horse_life/features/profile/presentation/widgets/red_sign_out_button.dart';

import '../../data/models/guardian_profile_data.dart';

/// Assinatura da função assíncrona que fornece o perfil do responsável.
typedef GuardianProfileLoader = Future<GuardianProfileData> Function();

/// Exibe a identidade, os cavalos e as ações do perfil do responsável.
class GuardianProfileScreen extends StatefulWidget {
  const GuardianProfileScreen({
    required this.loadGuardianProfile,
    required this.onLogout,
    this.onEditGuardianProfile,
    this.onShowAllGuardianHorses,
    this.onRegisterGuardianHorse,
    super.key,
  });

  final GuardianProfileLoader loadGuardianProfile;
  final Future<void> Function() onLogout;
  final VoidCallback? onEditGuardianProfile;
  final VoidCallback? onShowAllGuardianHorses;
  final VoidCallback? onRegisterGuardianHorse;

  @override
  State<GuardianProfileScreen> createState() => _GuardianProfileScreenState();
}

/// Mantém a requisição do perfil e coordena recarga e ações indisponíveis.
class _GuardianProfileScreenState extends State<GuardianProfileScreen> {
  // A Future é armazenada para impedir novas requisições a cada rebuild.
  late Future<GuardianProfileData> _guardianProfileFuture;

  @override
  void initState() {
    super.initState();
    _guardianProfileFuture = widget.loadGuardianProfile();
  }

  @override
  void didUpdateWidget(covariant GuardianProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadGuardianProfile != widget.loadGuardianProfile) {
      _guardianProfileFuture = widget.loadGuardianProfile();
    }
  }

  // Recarrega explicitamente os dados após uma falha.
  void _retryGuardianProfile() {
    setState(() => _guardianProfileFuture = widget.loadGuardianProfile());
  }

  // Mantém ações ainda não conectadas compreensíveis para o usuário.
  void _showGuardianActionUnavailable(String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$action estará disponível em breve.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GuardianProfileData>(
      future: _guardianProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _GuardianProfileError(onRetry: _retryGuardianProfile);
        }
        final guardianProfile =
            snapshot.data ??
            const GuardianProfileData(
              name: 'Usuário HorseLife',
              email: 'usuario@email.com',
              horses: [],
            );
        return _GuardianProfileBody(
          guardianProfile: guardianProfile,
          onLogout: widget.onLogout,
          onEditGuardianProfile:
              widget.onEditGuardianProfile ??
              () => _showGuardianActionUnavailable('A edição de perfil'),
          onShowAllGuardianHorses:
              widget.onShowAllGuardianHorses ??
              () => _showGuardianActionUnavailable('A lista de cavalos'),
          onRegisterGuardianHorse:
              widget.onRegisterGuardianHorse ??
              () => _showGuardianActionUnavailable('O cadastro de animais'),
        );
      },
    );
  }
}

/// Organiza a identidade, a relação de cavalos e as ações do perfil.
class _GuardianProfileBody extends StatelessWidget {
  const _GuardianProfileBody({
    required this.guardianProfile,
    required this.onLogout,
    required this.onEditGuardianProfile,
    required this.onShowAllGuardianHorses,
    required this.onRegisterGuardianHorse,
  });

  final GuardianProfileData guardianProfile;
  final Future<void> Function() onLogout;
  final VoidCallback onEditGuardianProfile;
  final VoidCallback onShowAllGuardianHorses;
  final VoidCallback onRegisterGuardianHorse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 26),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Meu perfil',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 28),
                ProfileIdentityHeader(
                  name: guardianProfile.name,
                  email: guardianProfile.email,
                ),
                const SizedBox(height: 26),
                OutlinedButton.icon(
                  key: const Key('edit-guardian-profile-button'),
                  onPressed: onEditGuardianProfile,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar perfil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seaGreen,
                    side: const BorderSide(color: AppColors.seaGreen, width: 2),
                    minimumSize: const Size.fromHeight(52),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Meus cavalos',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onShowAllGuardianHorses,
                      child: const Text('Mostrar tudo'),
                    ),
                  ],
                ),
                Text(
                  'Total: ${guardianProfile.horses.length}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 18),
                if (guardianProfile.horses.isEmpty)
                  _GuardianEmptyHorses(
                    onRegisterGuardianHorse: onRegisterGuardianHorse,
                  )
                else
                  _GuardianHorseList(horses: guardianProfile.horses),
                const SizedBox(height: 24),
                const Spacer(),
                RedSignOutButton(onLogout: onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exibe os cavalos vinculados em uma lista horizontal rolável.
class _GuardianHorseList extends StatelessWidget {
  const _GuardianHorseList({required this.horses});

  final List<GuardianProfileHorse> horses;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 202,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: horses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => ProfileHorseCard(
          name: horses[index].name,
          relationship: horses[index].relationship,
          imageUrl: horses[index].imageUrl,
        ),
      ),
    );
  }
}

/// Orienta o responsável a cadastrar o primeiro cavalo quando a lista está vazia.
class _GuardianEmptyHorses extends StatelessWidget {
  const _GuardianEmptyHorses({required this.onRegisterGuardianHorse});

  final VoidCallback onRegisterGuardianHorse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 30),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Nenhum animal cadastrado',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Cadastre um cavalo agora mesmo e\ncomece a desfrutar do HorseLife!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          GradientButton(
            key: const Key('register-guardian-horse-from-profile-button'),
            label: 'Cadastrar animal',
            icon: Icons.add_box_outlined,
            onPressed: onRegisterGuardianHorse,
          ),
        ],
      ),
    );
  }
}

/// Informa a falha no carregamento e oferece uma ação para tentar novamente.
class _GuardianProfileError extends StatelessWidget {
  const _GuardianProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar o perfil.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

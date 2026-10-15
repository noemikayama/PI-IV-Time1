// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da seleção de perfil que antecede os fluxos de cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/features/authentication/presentation/widgets/profile_information_row.dart';

import '../../../../app/theme/app_colors.dart';
import '../../application/controllers/registration_controller.dart';
import '../../data/models/user_type.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import 'registration_name_screen.dart';

// Coleta o perfil e entrega um valor tipado ao coordenador do cadastro.
class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({
    this.onContinue,
    this.onBack,
    this.registrationController,
    super.key,
  });

  // Contratos opcionais para testes, coordenação externa e futura submissão.
  final ValueChanged<UserType>? onContinue;
  final VoidCallback? onBack;
  final RegistrationController? registrationController;

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  // Seleção local; o responsável é a opção inicial apresentada no layout.
  UserType _selectedType = UserType.guardian;

  // Retorno injetável com fallback para a pilha de navegação.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Entrega o tipo ao coordenador ou inicia o fluxo padrão de responsável.
  void _continue() {
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(_selectedType);
      return;
    }

    if (_selectedType == UserType.guardian) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => RegistrationNameScreen.guardian(
            registrationController: widget.registrationController,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 24),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Seleção de perfil',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 46),
                            Text(
                              'Antes dos próximos passos, precisamos saber '
                              'que tipo de usuário você é.',
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // Seleção tipada que define o fluxo subsequente.
                            _ProfileDropdown(
                              value: _selectedType,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedType = value);
                              },
                            ),
                            const SizedBox(height: 36),
                            // Orientações que diferenciam os dois perfis.
                            const InformationRow(
                              text:
                                  'Usuários responsáveis (que representam '
                                  'tanto proprietários de animais quanto '
                                  'atletas) são aqueles que podem cadastrar '
                                  'ou gerenciar seus cavalos e executar os '
                                  'treinos prescritos pelos profissionais.',
                            ),
                            const SizedBox(height: 24),
                            const InformationRow(
                              text:
                                  'Usuários treinadores são aqueles que '
                                  'prescrevem e gerenciam os treinos para os '
                                  'animais, fazem avaliações iniciais e '
                                  'respondem feedbacks sobre as execuções.',
                            ),
                            const SizedBox(height: 74),
                            // Avanço compartilhado por toda a autenticação.
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-profile-selection',
                              ),
                              onPressed: _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({required this.value, required this.onChanged});

  final UserType value;
  final ValueChanged<UserType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserType>(
          key: const Key('profile-dropdown'),
          value: value,
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.text,
            size: 32,
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.text,
            fontSize: 20,
          ),
          itemHeight: 64,
          menuMaxHeight: 160,
          // Aparência compacta usada enquanto o menu permanece fechado.
          selectedItemBuilder: (context) => const [
            Align(alignment: Alignment.centerLeft, child: Text('Responsável')),
            Align(alignment: Alignment.centerLeft, child: Text('Treinador')),
          ],
          // O menu é deliberadamente limitado aos dois fluxos suportados.
          items: [
            _buildMenuItem(type: UserType.guardian, label: 'Responsável'),
            _buildMenuItem(type: UserType.professional, label: 'Treinador'),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  DropdownMenuItem<UserType> _buildMenuItem({
    required UserType type,
    required String label,
  }) {
    final isSelected = type == value;

    // Destaca a opção ativa com a cor e o check da identidade visual.
    return DropdownMenuItem<UserType>(
      value: type,
      child: Container(
        height: 52,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.seaGreen : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(13)),
        ),
        child: Row(
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : null),
            ),
          ],
        ),
      ),
    );
  }
}

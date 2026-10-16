// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de ValueChanged<TrainerRegistrationDraft> pelo
// typedef TrainerPasswordEditRequested na solicitação de edição da senha.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da confirmação exclusiva do treinador, com edição dos
// dados comuns e remoção das mídias e regiões previamente adicionadas.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../application/states/trainer_document.dart';
import '../../application/states/trainer_service_area.dart';
import '../messages/authentication_error_messages.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/editable_review_field.dart';
import '../widgets/registration_progress_indicator.dart';

typedef TrainerPasswordEditRequested =
    void Function(TrainerRegistrationDraft registration);

// Oitava e última etapa: revisa e envia exclusivamente o cadastro do treinador.
class TrainerConfirmationScreen extends StatefulWidget {
  const TrainerConfirmationScreen({
    required this.registration,
    required this.password,
    this.registrationController,
    this.onCreated,
    this.onBack,
    this.onEditPassword,
    super.key,
  });

  final TrainerRegistrationDraft registration;
  final String password;
  final RegistrationController? registrationController;
  final VoidCallback? onCreated;
  final VoidCallback? onBack;
  final TrainerPasswordEditRequested? onEditPassword;

  @override
  State<TrainerConfirmationScreen> createState() =>
      _TrainerConfirmationScreenState();
}

class _TrainerConfirmationScreenState extends State<TrainerConfirmationScreen> {
  // Formulário e cópias editáveis dos dados de contato recebidos no draft.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final Set<_TrainerReviewFieldId> _editingFields = {};

  TrainerDocument? _experienceDocument;
  late final List<TrainerDocument> _certificationDocuments;
  late final List<TrainerServiceArea> _serviceAreas;
  // Estados de apresentação da credencial e da operação final de envio.
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    // Inicializa os campos com os valores consolidados nas etapas anteriores.
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.registration.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.registration.lastName,
    );
    _emailController = TextEditingController(text: widget.registration.email);
    _passwordController = TextEditingController(text: widget.password);
    _experienceDocument = widget.registration.trainerExperienceDocument;
    _certificationDocuments = List.of(
      widget.registration.trainerCertificationDocuments,
    );
    _serviceAreas = List.of(widget.registration.serviceAreas);
  }

  @override
  void dispose() {
    // Remove primeiro a senha transitória e depois libera os recursos da tela.
    _passwordController.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Retorno injetável, usado também para reabrir a etapa anterior em testes.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Alterna a edição inline e direciona o foco ao campo selecionado.
  void _toggleEditing(_TrainerReviewFieldId field) {
    if (_editingFields.contains(field)) {
      setState(() => _editingFields.remove(field));
      _focusFor(field).unfocus();
      return;
    }

    setState(() => _editingFields.add(field));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(field).requestFocus();
    });
  }

  FocusNode _focusFor(_TrainerReviewFieldId field) {
    return switch (field) {
      _TrainerReviewFieldId.firstName => _firstNameFocus,
      _TrainerReviewFieldId.lastName => _lastNameFocus,
      _TrainerReviewFieldId.email => _emailFocus,
    };
  }

  // Validações reaplicadas após qualquer ajuste feito durante a revisão.
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    final isValid =
        password.length >= 8 &&
        password.length <= 30 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);

    if (!isValid) return 'Informe uma senha que atenda aos requisitos.';
    return null;
  }

  TrainerRegistrationDraft _buildUpdatedRegistration() {
    return widget.registration
        .copyWithContact(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        )
        .withTrainerExperienceDocument(_experienceDocument)
        .withTrainerCertificationDocuments(_certificationDocuments)
        .withServiceAreas(_serviceAreas);
  }

  // Volta à etapa de senha levando consigo todos os dados profissionais revistos.
  void _editPassword() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final onEditPassword = widget.onEditPassword;
    if (onEditPassword != null) {
      onEditPassword(_buildUpdatedRegistration());
      return;
    }
    Navigator.maybePop(context);
  }

  // Mantém a senha separada do draft e impede envios simultâneos.
  Future<void> _createAccount() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = widget.registrationController;
    if (controller == null) {
      _showConnectionError();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await controller.createAccount(
        registration: _buildUpdatedRegistration(),
        password: _passwordController.text,
      );
      _passwordController.clear();
      if (!mounted) return;
      widget.onCreated?.call();
    } catch (_) {
      if (mounted) _showConnectionError();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Expõe de forma explícita a indisponibilidade do backend ainda não integrado.
  void _showConnectionError() {
    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      message: AuthenticationErrorMessages.serverConnection,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Organiza contato, modalidade, anexos e áreas em uma revisão única.
    final textTheme = Theme.of(context).textTheme;

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
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const RegistrationProgressIndicator(
                              configuration:
                                  RegistrationProgressConfiguration.trainer,
                              currentStep: 8,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Revise seus dados',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Este é o último passo até o\nHorseLife.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 50),
                            _buildContactForm(),
                            const SizedBox(height: 38),
                            Text(
                              'Mídias adicionadas',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 26),
                            _buildExperienceSection(),
                            const SizedBox(height: 28),
                            _buildCertificationsSection(),
                            const SizedBox(height: 28),
                            _buildServiceAreasSection(),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'create-trainer-registration-account',
                              ),
                              label: 'Criar conta',
                              showArrow: false,
                              isLoading: _isSubmitting,
                              onPressed: _createAccount,
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

  // Bloco editável que reutiliza a mesma interação da confirmação do responsável.
  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EditableReviewField(
            fieldKey: const Key('trainer-review-first-name'),
            label: 'Primeiro nome',
            controller: _firstNameController,
            focusNode: _firstNameFocus,
            isEditing: _editingFields.contains(_TrainerReviewFieldId.firstName),
            validator: _validateRequired,
            textInputAction: TextInputAction.next,
            onToggleEditing: () =>
                _toggleEditing(_TrainerReviewFieldId.firstName),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('trainer-review-last-name'),
            label: 'Sobrenome',
            controller: _lastNameController,
            focusNode: _lastNameFocus,
            isEditing: _editingFields.contains(_TrainerReviewFieldId.lastName),
            validator: _validateRequired,
            textInputAction: TextInputAction.next,
            onToggleEditing: () =>
                _toggleEditing(_TrainerReviewFieldId.lastName),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('trainer-review-email'),
            label: 'E-mail',
            controller: _emailController,
            focusNode: _emailFocus,
            isEditing: _editingFields.contains(_TrainerReviewFieldId.email),
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_TrainerReviewFieldId.email),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('trainer-review-password'),
            label: 'Senha',
            controller: _passwordController,
            focusNode: _passwordFocus,
            isEditing: false,
            obscureText: !_isPasswordVisible,
            validator: _validatePassword,
            textInputAction: TextInputAction.done,
            onToggleEditing: _editPassword,
            externalEdit: true,
            leadingAction: IconButton(
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
              tooltip: _isPasswordVisible ? 'Ocultar senha' : 'Mostrar senha',
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.seaGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Exibe o comprovante opcional somente quando ele foi informado.
  Widget _buildExperienceSection() {
    final document = _experienceDocument;
    return _ReviewSection(
      title: 'Experiência',
      emptyMessage: 'Nenhum documento anexado.',
      children: document == null
          ? const []
          : [
              _RemovableReviewTile(
                key: const Key('trainer-review-experience-document'),
                icon: Icons.picture_as_pdf_rounded,
                label: document.name,
                removeKey: const Key('remove-trainer-review-experience'),
                onRemove: () => setState(() => _experienceDocument = null),
              ),
            ],
    );
  }

  // Lista as certificações com remoção local antes da submissão.
  Widget _buildCertificationsSection() {
    return _ReviewSection(
      title: 'Certificados',
      emptyMessage: 'Nenhum certificado anexado.',
      children: [
        for (var index = 0; index < _certificationDocuments.length; index++)
          _RemovableReviewTile(
            key: ValueKey('trainer-review-certification-$index'),
            icon: Icons.picture_as_pdf_rounded,
            label: _certificationDocuments[index].name,
            removeKey: ValueKey('remove-trainer-review-certification-$index'),
            onRemove: () =>
                setState(() => _certificationDocuments.removeAt(index)),
          ),
      ],
    );
  }

  // Lista as áreas com o contexto geográfico necessário à identificação.
  Widget _buildServiceAreasSection() {
    return _ReviewSection(
      title: 'Regiões de atendimento',
      emptyMessage: 'Nenhuma região adicionada.',
      children: [
        for (var index = 0; index < _serviceAreas.length; index++)
          _RemovableReviewTile(
            key: ValueKey('trainer-review-service-area-$index'),
            icon: Icons.location_on,
            label: _serviceAreaLabel(_serviceAreas[index]),
            removeKey: ValueKey('remove-trainer-review-service-area-$index'),
            onRemove: () => setState(() => _serviceAreas.removeAt(index)),
          ),
      ],
    );
  }

  // Concatena cidade e UF apenas quando ambos fazem parte da seleção.
  String _serviceAreaLabel(TrainerServiceArea area) {
    return switch (area.type) {
      TrainerServiceAreaType.countryRegion => area.countryRegion,
      TrainerServiceAreaType.state => '${area.stateName} - ${area.stateCode}',
      TrainerServiceAreaType.city => '${area.cityName} - ${area.stateCode}',
    };
  }
}

// Agrupa visualmente uma categoria da revisão e seu conteúdo opcional.
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Text(
            emptyMessage,
            key: ValueKey('empty-$title'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

// Item reutilizável para anexos e localidades que podem ser descartados.
class _RemovableReviewTile extends StatelessWidget {
  const _RemovableReviewTile({
    required this.icon,
    required this.label,
    required this.removeKey,
    required this.onRemove,
    super.key,
  });

  final IconData icon;
  final String label;
  final Key removeKey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 20, right: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blueSpruce, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 19),
            ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            tooltip: 'Remover $label',
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// Identifica os campos que aceitam edição inline na revisão final.
enum _TrainerReviewFieldId { firstName, lastName, email }

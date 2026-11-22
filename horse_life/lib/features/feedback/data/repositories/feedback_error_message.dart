// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Tratamento compartilhado dos erros da consulta e do cadastro.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

String feedbackErrorMessage(Object error) {
  if (error is StateError) return error.message;
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'unauthenticated': return 'Sua sessão expirou. Entre novamente.';
      case 'not-found': return 'Registro de treino não encontrado.';
      case 'permission-denied':
      case 'failed-precondition':
      case 'invalid-argument':
        return error.message ?? 'Não foi possível concluir esta operação.';
    }
  }
  return 'Não foi possível concluir a operação. Tente novamente.';
}

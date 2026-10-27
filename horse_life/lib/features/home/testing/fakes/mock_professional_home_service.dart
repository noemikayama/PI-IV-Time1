// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da Mock API da Home do Profissional com cenários
// normal, vazio e erro, sem dependência de Firebase.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Fake movido para testing/fakes; mantido para testes legados.
// -----------------------------------------------------------------------------

import '../../data/models/professional_home_data.dart';

/// Serviço de testes. Substituir por um repositório real na integração com a API.
class MockProfessionalHomeService {
  const MockProfessionalHomeService();

  Future<ProfessionalHomeData> fetchHome({
    String scenario = 'normal',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (scenario == 'error') {
      throw Exception('Falha simulada ao carregar a Home do Profissional.');
    }

    if (scenario == 'empty') {
      return const ProfessionalHomeData(
        professionalName: 'Mariana',
        specialty: 'Salto',
        todayTrainings: [],
        weeklyFeedbacksDone: 0,
        weeklyFeedbacksTotal: 0,
        activePlans: 0,
        weeklyTrainingsCompleted: 0,
        weeklyTrainingsPlanned: 0,
        createdExercises: 0,
        horses: [],
        clients: [],
      );
    }

    return const ProfessionalHomeData(
      professionalName: 'Mariana',
      specialty: 'Salto',
      todayTrainings: [
        ProfessionalTraining(
          id: 'training-01',
          title: 'Treino de salto',
          horseName: 'Apollo',
          planName: 'Preparação para competição',
        ),
        ProfessionalTraining(
          id: 'training-02',
          title: 'Treino de adestramento',
          horseName: 'Luna',
          planName: 'Condicionamento e técnica',
        ),
      ],
      weeklyFeedbacksDone: 2,
      weeklyFeedbacksTotal: 6,
      activePlans: 5,
      weeklyTrainingsCompleted: 3,
      weeklyTrainingsPlanned: 6,
      createdExercises: 16,
      horses: [
        ProfessionalHorse(id: 'horse-01', name: 'Apollo'),
        ProfessionalHorse(id: 'horse-02', name: 'Luna'),
        ProfessionalHorse(id: 'horse-03', name: 'Thor'),
      ],
      clients: [
        ProfessionalClient(id: 'client-01', name: 'Gabriela'),
      ],
    );
  }
}

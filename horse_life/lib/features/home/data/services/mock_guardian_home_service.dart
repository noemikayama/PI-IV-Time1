// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
import '../models/guardian_home_data.dart';

// Substituir futuramente pela implementação real HTTP ou Firebase.
/// Simula latência, falhas e cenários para testar widgets sem autenticação ou servidor.
class MockGuardianHomeService {
  const MockGuardianHomeService();

  Future<GuardianHomeData> fetchHome({
    bool simulateError = false,
    String scenario = 'normal',
  }) async {
    // Simula o tempo de rede para exercitar os indicadores de carregamento.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Falha simulada de conexão com o servidor.');
    }

    if (scenario == 'empty' || scenario == 'completed') {
      return GuardianHomeData(
        guardianName: 'Gabriela',
        todayTrainings: scenario == 'completed'
            ? const [
                GuardianTraining(
                  title: 'Salto com obstáculos',
                  horseName: 'Apollo',
                  trainerName: 'Mariana Costa',
                  durationMinutes: 45,
                  planName: 'Treino de salto',
                  isCompleted: true,
                ),
              ]
            : const [],
        weeklyCompleted: 0,
        weeklyPlanned: 0,
        monthlyCompleted: 0,
        monthlyPlanned: 0,
        allTimeCompleted: 0,
        horses: const [],
        trainers: const [],
      );
    }
    return const GuardianHomeData(
      guardianName: 'Gabriela',
      todayTrainings: [
        GuardianTraining(
          title: 'Salto com obstáculos',
          horseName: 'Apollo',
          trainerName: 'Mariana Costa',
          durationMinutes: 45,
          planName: 'Preparação para competição',
        ),
        GuardianTraining(
          title: 'Treino de adestramento',
          horseName: 'Luna',
          trainerName: 'Pedro Almeida',
          durationMinutes: 30,
          planName: 'Treinamento básico',
        ),
        GuardianTraining(
          title: 'Treino de resistência',
          horseName: 'Thor',
          trainerName: 'Mariana Costa',
          durationMinutes: 60,
          planName: 'Condicionamento físico',
        ),
      ],
      weeklyCompleted: 2,
      weeklyPlanned: 6,
      monthlyCompleted: 8,
      monthlyPlanned: 24,
      allTimeCompleted: 47,
      horses: ['Apollo', 'Luna', 'Thor', 'Estrela'],
      trainers: ['Mariana Costa', 'Pedro Almeida'],
    );
  }
}

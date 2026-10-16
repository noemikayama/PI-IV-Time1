import '../models/guardian_home_data.dart';

/// Serviço temporário: simula a resposta de um backend sem internet ou Firebase.
class MockGuardianHomeService {
  const MockGuardianHomeService();

  Future<GuardianHomeData> fetchHome({
    bool simulateError = false,
    String scenario = 'normal',
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (simulateError) {
      throw Exception('Falha simulada de conexão com o servidor.');
    }

    switch (scenario) {
      case 'empty':
        // Nenhum treino agendado, cavalo ou treinador vinculado.
        return const GuardianHomeData(
          guardianName: 'Gabriela',
          todayTrainings: [],
          weeklyCompleted: 0,
          weeklyPlanned: 0,
          monthlyCompleted: 0,
          monthlyPlanned: 0,
          allTimeCompleted: 0,
          horses: [],
          trainers: [],
        );

      case 'completed':
        // Treinos existem, mas todos foram concluídos hoje.
        // Os demais dados permanecem preenchidos para testar esse caso isoladamente.
        return const GuardianHomeData(
          guardianName: 'Gabriela',
          todayTrainings: [
            GuardianTraining(
              title: 'Salto com obstáculos',
              horseName: 'Apollo',
              trainerName: 'Mariana Costa',
              durationMinutes: 45,
              planName: 'Preparação para competição',
              isCompleted: true,
            ),
            GuardianTraining(
              title: 'Treino de adestramento',
              horseName: 'Luna',
              trainerName: 'Pedro Almeida',
              durationMinutes: 30,
              planName: 'Treinamento básico',
              isCompleted: true,
            ),
          ],
          weeklyCompleted: 6,
          weeklyPlanned: 6,
          monthlyCompleted: 24,
          monthlyPlanned: 24,
          allTimeCompleted: 63,
          horses: ['Apollo', 'Luna'],
          trainers: ['Mariana Costa', 'Pedro Almeida'],
        );

      default:
        // Três treinos pendentes e quatro cavalos para testar rolagem vertical.
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
}

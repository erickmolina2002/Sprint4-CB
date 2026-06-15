import { Injectable, OnModuleInit } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { SecurityLogger } from '../observability/security-logger.service';
import { Events } from '../observability/events';
import { User } from '../users/user.entity';

@Injectable()
export class SeedService implements OnModuleInit {
  constructor(
    private readonly users: UsersService,
    private readonly logger: SecurityLogger,
  ) {}

  async onModuleInit(): Promise<void> {
    const existing = await this.users.count();
    if (existing > 0) {
      return;
    }

    const seed: Partial<User>[] = [
      {
        name: 'Admin Care',
        heroCode: 'ADMIN-9X7Q',
        role: 'admin',
        xp: 9999,
        level: 50,
        streak: 120,
        healthNotes: 'Conta administrativa do servico Care Plus.',
      },
      {
        name: 'Estudante FIAP',
        heroCode: 'FIAP2025',
        role: 'user',
        xp: 320,
        level: 4,
        streak: 7,
        lastCompletedDate: '2026-06-13',
        completedDates: ['2026-06-09', '2026-06-10', '2026-06-13'],
        healthNotes: 'Pre-diabetico; acompanhamento nutricional semanal.',
      },
      {
        name: 'Marina Souza',
        heroCode: 'MAR-2231',
        role: 'user',
        xp: 540,
        level: 6,
        streak: 14,
        healthNotes:
          'Quadro de ansiedade; usa missoes de respiracao; alergia a penicilina.',
      },
      {
        name: 'Carlos Lima',
        heroCode: 'CAR-8842',
        role: 'user',
        xp: 110,
        level: 2,
        streak: 1,
        healthNotes: 'Hipertensao controlada; IMC 28.',
      },
      {
        name: 'Bia Nunes',
        heroCode: 'BIA-0099',
        role: 'user',
        xp: 760,
        level: 8,
        streak: 30,
        healthNotes: 'Gestante (2o trimestre); monitorando sono e hidratacao.',
      },
    ];

    await this.users.saveMany(seed);
    this.logger.log({
      event: Events.SEED_DONE,
      outcome: 'info',
      count: seed.length,
      detail: 'usuarios iniciais criados (inclui dados sensiveis de saude)',
    });
  }
}

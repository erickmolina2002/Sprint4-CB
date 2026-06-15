import { Controller, Get } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  async list() {
    const all = await this.users.findAll();
    return all.map((u) => ({
      name: u.name,
      level: u.level,
      xp: u.xp,
      streak: u.streak,
    }));
  }
}

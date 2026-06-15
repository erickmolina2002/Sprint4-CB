import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { SecurityLogger } from '../observability/security-logger.service';
import { Events } from '../observability/events';
import { AdminAccessGuard } from './admin-access.guard';
import { vulnV3 } from '../config/flags';

@Controller('admin')
export class AdminController {
  constructor(
    private readonly users: UsersService,
    private readonly logger: SecurityLogger,
  ) {}

  @UseGuards(AdminAccessGuard)
  @Get('users')
  async all(@Req() req: any) {
    const users = await this.users.findAll();

    this.logger.log({
      event: Events.ADMIN_USERS_ACCESS,
      outcome: 'success',
      count: users.length,
      ip: req.ip,
      identified: !!req.user,
      route: '/admin/users',
    });

    if (vulnV3()) {
      return users;
    }

    return users.map((u) => ({ id: u.id, role: u.role, level: u.level }));
  }
}

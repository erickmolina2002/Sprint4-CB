import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { AuthModule } from '../auth/auth.module';
import { AdminController } from './admin.controller';
import { AdminAccessGuard } from './admin-access.guard';

@Module({
  imports: [UsersModule, AuthModule],
  controllers: [AdminController],
  providers: [AdminAccessGuard],
})
export class AdminModule {}

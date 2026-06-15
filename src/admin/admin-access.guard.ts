import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { vulnV3 } from '../config/flags';

@Injectable()
export class AdminAccessGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    if (vulnV3()) {
      return true;
    }

    const req = context.switchToHttp().getRequest();
    const header: string | undefined = req.headers?.['authorization'];
    if (!header?.startsWith('Bearer ')) {
      throw new ForbiddenException('requer autenticacao de administrador');
    }
    try {
      const payload: any = this.jwt.verify(header.slice(7));
      req.user = payload;
      if (payload?.role !== 'admin') {
        throw new ForbiddenException('requer papel admin');
      }
      return true;
    } catch (e) {
      if (e instanceof ForbiddenException) throw e;
      throw new ForbiddenException('token invalido');
    }
  }
}

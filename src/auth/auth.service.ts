import {
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { SecurityLogger } from '../observability/security-logger.service';
import { Events } from '../observability/events';
import { resolveJwtSecret } from './jwt.constants';
import { vulnV2 } from '../config/flags';

const NOTIFY_URL = 'https://util.devi.tools/api/v1/notify';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    private readonly logger: SecurityLogger,
  ) {}

  async login(name: string, heroCode: string, ip?: string) {
    const user = await this.users.findByName(name);
    const credentialsOk = !!user && user.heroCode === heroCode;

    if (!credentialsOk || !user) {
      this.logger.log({
        event: Events.LOGIN_FAIL,
        outcome: 'fail',
        name,
        ip,
        detail: 'credenciais invalidas',
      });
      throw new UnauthorizedException('Credenciais invalidas');
    }

    if (vulnV2()) {
      const notifyOk = await this.notify(user.name, ip);
      if (!notifyOk) {
        throw new InternalServerErrorException(
          'Falha ao enviar notificacao (servico externo indisponivel)',
        );
      }
    }

    const { source } = resolveJwtSecret();
    const access_token = this.jwt.sign({
      sub: user.id,
      name: user.name,
      role: user.role,
    });

    this.logger.log({ event: Events.JWT_SECRET_SOURCE, outcome: 'info', detail: source });
    this.logger.log({ event: Events.LOGIN_OK, outcome: 'success', name, ip });
    this.logger.log({
      event: Events.TOKEN_ISSUED,
      outcome: 'success',
      name,
      ip,
      detail: `role=${user.role}`,
    });

    return { access_token, secret_source: source };
  }

  private async notify(name: string, ip?: string): Promise<boolean> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 8000);
    try {
      const res = await fetch(NOTIFY_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user: name, message: 'login realizado' }),
        signal: controller.signal,
      });
      this.logger.log({
        event: res.ok ? Events.NOTIFY_OK : Events.NOTIFY_FAILED,
        outcome: res.ok ? 'success' : 'fail',
        name,
        ip,
        detail: `notify HTTP ${res.status} (util.devi.tools)`,
      });
      return res.ok;
    } catch {
      this.logger.log({
        event: Events.NOTIFY_FAILED,
        outcome: 'fail',
        name,
        ip,
        detail: 'erro/timeout ao chamar util.devi.tools',
      });
      return false;
    } finally {
      clearTimeout(timer);
    }
  }
}

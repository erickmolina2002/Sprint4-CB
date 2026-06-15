import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly repo: Repository<User>,
  ) {}

  findAll(): Promise<User[]> {
    return this.repo.find();
  }

  findByName(name: string): Promise<User | null> {
    return this.repo.findOne({ where: { name } });
  }

  count(): Promise<number> {
    return this.repo.count();
  }

  saveMany(users: Partial<User>[]): Promise<User[]> {
    return this.repo.save(this.repo.create(users));
  }
}

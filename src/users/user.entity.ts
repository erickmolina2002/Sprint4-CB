import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;
  @Column()
  heroCode: string;

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ default: 0 })
  streak: number;

  @Column({ type: 'date', nullable: true })
  lastCompletedDate: string | null;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  completedDates: string[];

  @Column({ type: 'varchar', default: 'user' })
  role: 'user' | 'admin';

  @Column({ type: 'text', nullable: true })
  healthNotes: string | null;

  @CreateDateColumn()
  createdAt: Date;
}

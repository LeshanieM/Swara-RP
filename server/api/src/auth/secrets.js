// Password / PIN hashing (scrypt, no native dependency) and the two token kinds.
const crypto = require('crypto');
const { promisify } = require('util');
const jwt = require('jsonwebtoken');
const env = require('../config/env');

const scrypt = promisify(crypto.scrypt);
const KEY_LEN = 32;

async function hash(secret) {
  const salt = crypto.randomBytes(16);
  const key = await scrypt(secret, salt, KEY_LEN);
  return `scrypt$${salt.toString('base64')}$${key.toString('base64')}`;
}

async function verify(secret, stored) {
  const [scheme, salt, key] = String(stored || '').split('$');
  if (scheme !== 'scrypt' || !salt || !key) return false;
  const expected = Buffer.from(key, 'base64');
  const actual = await scrypt(secret, Buffer.from(salt, 'base64'), expected.length);
  return crypto.timingSafeEqual(actual, expected);
}

// The session token: who is signed in and, for a child account, which child it may act for.
const signSession = (account) => jwt.sign(
  { sub: account.id, role: account.role, childId: account.child?.childId ?? null, kind: 'session' },
  env.jwtSecret,
  { expiresIn: `${env.tokenDays}d` },
);

// A short-lived proof that the parent entered the PIN; sent as X-Parent-Token.
const signParent = (account) => jwt.sign(
  { sub: account.id, childId: account.child.childId, kind: 'parent' },
  env.jwtSecret,
  { expiresIn: `${env.parentModeMinutes}m` },
);

const decode = (token, kind) => {
  const claims = jwt.verify(token, env.jwtSecret);
  if (claims.kind !== kind) throw new Error('wrong token kind');
  return claims;
};

module.exports = { hash, verify, signSession, signParent, decode };

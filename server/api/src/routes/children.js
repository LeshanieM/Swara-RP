// /api/children: the child accounts a signed-in account can see, with C1's latest result.
// A therapist sees every child; a child account sees only its own child.
const express = require('express');
const { z } = require('zod');
const ApiError = require('../lib/ApiError');
const run = require('../lib/run');
const validate = require('../middleware/validate');
const Account = require('../auth/Account');
const c1Assessments = require('../modules/c1/services/assessmentService');
const progress = require('../progress/overall');

const router = express.Router();
const childParam = validate(z.object({ childId: z.string().trim().min(1).max(64) }), 'params');

const SEVERITY = { none_very_mild: 'Very mild', mild: 'Mild', moderate: 'Moderate', severe: 'Severe' };
const TYPE = {
  block: 'Block', prolongation: 'Prolongation', sound_repetition: 'Repetition', word_repetition: 'Repetition', interjection: 'Interjection',
};

async function describe(account) {
  const { latest } = await c1Assessments.summaryForChild(account.child.childId);
  return {
    id: account.child.childId,
    childId: account.child.childId,
    firstName: account.child.firstName,
    age: account.child.age,
    accountName: account.name,
    severity: latest ? SEVERITY[latest.severity] ?? null : null,
    stutterType: latest ? (latest.stutterType ?? TYPE[latest.primaryType] ?? null) : null,
    percentSS: latest?.percentSS ?? null,
    lastAssessedAt: latest?.date ?? null,
    createdAt: account.createdAt,
  };
}

const visible = (req) => (req.auth?.role === 'child' ? { 'child.childId': req.auth.childId } : { role: 'child' });

router.get('/', run(async (req, res) => {
  const accounts = await Account.find(visible(req)).sort({ createdAt: -1 });
  res.json(await Promise.all(accounts.map(describe)));
}));

router.get('/:childId', childParam, run(async (req, res) => {
  const account = await Account.findOne({ ...visible(req), 'child.childId': req.valid.params.childId });
  if (!account) throw ApiError.notFound('child_not_found', `No child with id ${req.valid.params.childId}.`);
  res.json(await describe(account));
}));

// Overall progress across C1–C4: the %SS trend (C1 + C4) with C3 / C4 / C2 as evidence, and a verdict.
router.get('/:childId/progress', childParam, run(async (req, res) => {
  const account = await Account.findOne({ ...visible(req), 'child.childId': req.valid.params.childId });
  if (!account) throw ApiError.notFound('child_not_found', `No child with id ${req.valid.params.childId}.`);
  res.json(await progress.overall(req.valid.params.childId));
}));

module.exports = router;

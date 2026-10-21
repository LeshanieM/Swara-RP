// Hybrid LinUCB (Li et al., 2010, Algorithm 2). The shared part (A0, b0 → β) is learned across all children, so a new
// child gets the population's preferences from session 1; the per-arm part (A, B, b → θ) is kept per child and takes over
// as that child's own data builds up. Plain functions over plain objects, so the state can be stored and exported as JSON.
const la = require('./linalg');

const newPopulation = (k) => ({ A0: la.identity(k), b0: la.zeros(k) });
// The per-child prior A = λI: a larger λ keeps a new child closer to the population model for longer.
const newArm = (d, k, lambda = 1) => ({
  A: la.scaleInPlace(la.identity(d), lambda), B: la.zeroMatrix(d, k), b: la.zeros(d), n: 0, rewardSum: 0,
});

function populationTerms(population) {
  const A0inv = la.inverse(population.A0);
  return { A0inv, beta: la.matVec(A0inv, population.b0) };
}

/**
 * UCB score for each candidate {armId, x, z}. Returns [{armId, mean, bonus, ucb, n}] in candidate order.
 * mean = zᵀβ + xᵀθ; bonus = α √s with s = (z − v)ᵀ A0⁻¹ (z − v) + xᵀ A⁻¹ x, where v = Bᵀ A⁻¹ x.
 */
function score(population, arms, candidates, alpha) {
  const { A0inv, beta } = populationTerms(population);
  return candidates.map(({ armId, x, z }) => {
    const arm = arms[armId];
    const Ainv = la.inverse(arm.A);
    const theta = la.matVec(Ainv, la.addVecInPlace([...arm.b], la.matVec(arm.B, beta), -1));
    const u = la.matVec(Ainv, x);
    const v = la.vecMat(u, arm.B);
    const zMinusV = z.map((zi, i) => zi - v[i]);
    const s = Math.max(0, la.dot(zMinusV, la.matVec(A0inv, zMinusV)) + la.dot(x, u));
    const mean = la.dot(z, beta) + la.dot(x, theta);
    const bonus = alpha * Math.sqrt(s);
    return { armId, mean, bonus, ucb: mean + bonus, n: arm.n };
  });
}

// Bᵀ A⁻¹ for one arm (k × d), used to move the arm's contribution in and out of the shared matrices.
const sharedCoupling = (arm) => la.matMul(la.transpose(arm.B), la.inverse(arm.A));

/** Add the arm's coupling back into A0/b0 (step before changing the arm). */
function detach(population, arm) {
  const C = sharedCoupling(arm);
  la.addInPlace(population.A0, la.matMul(C, arm.B));
  la.addVecInPlace(population.b0, la.matVec(C, arm.b));
}

/** Remove the arm's coupling from A0/b0 (step after changing the arm). */
function attach(population, arm) {
  const C = sharedCoupling(arm);
  la.addInPlace(population.A0, la.matMul(C, arm.B), -1);
  la.addVecInPlace(population.b0, la.matVec(C, arm.b), -1);
}

/** Observe reward r for (x, z) on one arm; mutates population and arm. */
function update(population, arm, x, z, r) {
  detach(population, arm);
  la.addInPlace(arm.A, la.outer(x, x));
  la.addInPlace(arm.B, la.outer(x, z));
  la.addVecInPlace(arm.b, x, r);
  attach(population, arm);
  la.addInPlace(population.A0, la.outer(z, z));
  la.addVecInPlace(population.b0, z, r);
  arm.n += 1;
  arm.rewardSum += r;
}

/**
 * Discounted variant: before each update, shrink every per-child arm towards its prior (A → γA + (1 − γ)λI, B → γB,
 * b → γb), so older results count less as the child's needs change. The shared population part is not discounted.
 */
function discountChild(population, arms, gamma, lambda = 1) {
  for (const arm of Object.values(arms)) {
    if (arm.n > 0) {
      detach(population, arm);
      const d = arm.A.length;
      la.scaleInPlace(arm.A, gamma);
      for (let i = 0; i < d; i += 1) arm.A[i][i] += (1 - gamma) * lambda;
      la.scaleInPlace(arm.B, gamma);
      arm.b = arm.b.map((v) => v * gamma);
      attach(population, arm);
    }
  }
}

/** Per-arm θ (per-child part) and the shared β, for export and inspection. */
function parameters(population, arm) {
  const { beta } = populationTerms(population);
  const theta = la.matVec(la.inverse(arm.A), la.addVecInPlace([...arm.b], la.matVec(arm.B, beta), -1));
  return { theta, beta };
}

module.exports = {
  newPopulation, newArm, score, update, discountChild, parameters, populationTerms,
};

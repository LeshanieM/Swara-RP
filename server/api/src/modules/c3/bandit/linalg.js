// Small dense linear algebra for the bandit (d ≈ 12, k ≈ 45). Matrices are arrays of row arrays.

const zeros = (n) => new Array(n).fill(0);
const zeroMatrix = (rows, cols) => Array.from({ length: rows }, () => zeros(cols));
const identity = (n) => Array.from({ length: n }, (_, i) => { const r = zeros(n); r[i] = 1; return r; });

const dot = (a, b) => a.reduce((s, v, i) => s + v * b[i], 0);
const matVec = (M, v) => M.map((row) => dot(row, v));
const vecMat = (v, M) => { const out = zeros(M[0].length); M.forEach((row, i) => row.forEach((m, j) => { out[j] += v[i] * m; })); return out; };
const transpose = (M) => M[0].map((_, j) => M.map((row) => row[j]));
const matMul = (A, B) => { const Bt = transpose(B); return A.map((row) => Bt.map((col) => dot(row, col))); };
const outer = (a, b) => a.map((x) => b.map((y) => x * y));

const addInPlace = (A, B, scale = 1) => { A.forEach((row, i) => row.forEach((_, j) => { row[j] += scale * B[i][j]; })); return A; };
const addVecInPlace = (a, b, scale = 1) => { a.forEach((_, i) => { a[i] += scale * b[i]; }); return a; };
const scaleInPlace = (A, s) => { A.forEach((row) => row.forEach((_, j) => { row[j] *= s; })); return A; };

/** Gauss-Jordan inverse with partial pivoting. A is symmetric positive definite here, so pivots stay well away from 0. */
function inverse(A) {
  const n = A.length;
  const M = A.map((row, i) => [...row, ...identity(n)[i]]);
  for (let c = 0; c < n; c += 1) {
    let p = c;
    for (let r = c + 1; r < n; r += 1) if (Math.abs(M[r][c]) > Math.abs(M[p][c])) p = r;
    if (Math.abs(M[p][c]) < 1e-12) throw new Error('singular matrix in bandit state');
    [M[c], M[p]] = [M[p], M[c]];
    const pivot = M[c][c];
    for (let j = 0; j < 2 * n; j += 1) M[c][j] /= pivot;
    for (let r = 0; r < n; r += 1) {
      if (r !== c && M[r][c] !== 0) {
        const f = M[r][c];
        for (let j = 0; j < 2 * n; j += 1) M[r][j] -= f * M[c][j];
      }
    }
  }
  return M.map((row) => row.slice(n));
}

const isFiniteMatrix = (M) => M.every((row) => row.every(Number.isFinite));

module.exports = {
  zeros, zeroMatrix, identity, dot, matVec, vecMat, transpose, matMul, outer,
  addInPlace, addVecInPlace, scaleInPlace, inverse, isFiniteMatrix,
};

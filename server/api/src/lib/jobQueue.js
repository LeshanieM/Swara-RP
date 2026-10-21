/**
 * Minimal in-process FIFO queue with a concurrency cap.
 *
 * State lives in MongoDB (each assessment's `status`), so a restart loses
 * nothing: assessmentService.recover() re-queues unfinished work on startup.
 */
class JobQueue {
  constructor(worker, concurrency) {
    this.worker = worker;
    this.concurrency = concurrency;
    this.waiting = [];
    this.running = new Set();
  }

  push(id) {
    const key = String(id);
    if (this.running.has(key) || this.waiting.includes(key)) return;
    this.waiting.push(key);
    this.pump();
  }

  pump() {
    while (this.running.size < this.concurrency && this.waiting.length) {
      const id = this.waiting.shift();
      this.running.add(id);
      Promise.resolve()
        .then(() => this.worker(id))
        .catch((err) => console.error(`[queue] job ${id} crashed:`, err))
        .finally(() => {
          this.running.delete(id);
          this.pump();
        });
    }
  }

  stats() {
    return { running: this.running.size, waiting: this.waiting.length, concurrency: this.concurrency };
  }
}

module.exports = JobQueue;

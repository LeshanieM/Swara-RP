// Within-session adaptation for the short-block session: keep going, offer a break, switch to a parent-led
// activity when low engagement continues after a break, or end when the session's activities (default 5) are
// done or the planned time is used up.
const config = require('../config');
const { elapsedMinutes, DONE } = require('./contextService');
const { round } = require('./scoring');

function evaluate(session, attempts) {
  const plannedMinutes = session.plannedMinutes;
  const maxActivities = session.maxActivities || config.maxActivitiesPerSession;
  const elapsed = elapsedMinutes(session, attempts);
  const done = attempts.filter((a) => DONE.includes(a.status)).length;
  const lastBreak = session.breaks.length ? session.breaks[session.breaks.length - 1] : null;
  const finished = attempts
    .filter((a) => DONE.includes(a.status) && (!lastBreak || a.completedAt > lastBreak.at))
    .sort((a, b) => a.sequence - b.sequence);

  // Low-engagement activities at the end of the session since the last break.
  const low = config.lowEngagement;
  const streak = [];
  for (let i = finished.length - 1; i >= 0; i -= 1) {
    if (!(finished[i].engagement?.score < low.threshold)) break;
    streak.unshift(finished[i]);
  }
  const streakMinutes = streak.reduce((s, a) => s + (a.result?.durationSec || 0), 0) / 60;

  let advice = 'continue';
  let reason = null;
  if (done >= maxActivities) {
    advice = 'end_session';
    reason = `All ${maxActivities} activities of today's session are done.`;
  } else if (elapsed >= plannedMinutes) {
    advice = 'end_session';
    reason = `The planned ${plannedMinutes} minutes have been used.`;
  } else if (lastBreak && lastBreak.reason === 'low_engagement' && streak.length >= 1) {
    advice = 'parent_led';
    reason = 'Engagement stayed low after a break; switch to an easy, parent-led activity.';
  } else if (streak.length >= low.minActivities && streakMinutes >= low.minMinutes) {
    advice = 'offer_break';
    reason = `Engagement has been below ${low.threshold} for ${streak.length} activities (${round(streakMinutes, 1)} min).`;
  }
  return {
    advice,
    reason,
    elapsedMinutes: round(elapsed, 2),
    plannedMinutes,
    activitiesDone: done,
    maxActivities,
    lowStreak: { activities: streak.length, minutes: round(streakMinutes, 2) },
  };
}

module.exports = { evaluate };

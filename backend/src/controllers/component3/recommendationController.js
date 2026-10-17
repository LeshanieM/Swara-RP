const recommendationService = require('../../services/component3/recommendationService');
const { buildContext, CONTEXT_DIM } = require('../../services/component3/contextBuilder');
const LinUCBState = require('../../models/component3/LinUCBState');
const Child = require('../../models/Child');

const canAccessChild = async (childId, user) => {
  if (!childId) return false;
  const ownership = user.role === 'therapist'
    ? { therapistId: user.id }
    : { parentId: user.id };
  return Boolean(await Child.exists({ _id: childId, ...ownership }));
};

const resolveChildId = async (childId, user) => {
  if (childId) {
    if (await canAccessChild(childId, user)) return childId;
    return null;
  }
  const child = await Child.findOne({ parentId: user.id }).select('_id').lean();
  return child ? child._id.toString() : null;
};

// ---------------------------------------------------------------------------
// GET /api/c3/recommendations/context
// ---------------------------------------------------------------------------
const getContext = async (req, res) => {
  try {
    const rawChildId = req.query.childId;
    const childId = await resolveChildId(rawChildId, req.user);
    if (!childId) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    const sessionId = req.query.sessionId || 'active';
    const cameraOn = req.query.cameraOn === 'true';
    const activityType = req.query.activityType;
    const parentHelpLevel = req.query.parentHelpLevel ? Number(req.query.parentHelpLevel) : undefined;

    const { vector, metadata } = await buildContext(childId, sessionId, {
      cameraOn,
      activityType,
      parentHelpLevel,
    });

    res.json({
      success: true,
      data: {
        vector,
        metadata,
        dimension: CONTEXT_DIM,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// GET /api/c3/recommendations/shared-state
// ---------------------------------------------------------------------------
const getSharedState = async (req, res) => {
  try {
    let sharedState = await LinUCBState.findOne({ scope: 'shared', actionId: 'global' }).lean();
    if (!sharedState) {
      // Initialize shared identity matrix & zero vector for 12 dimensions
      const I12 = Array.from({ length: CONTEXT_DIM }, (_, r) =>
        Array.from({ length: CONTEXT_DIM }, (_, c) => (r === c ? 1.0 : 0.0))
      );
      const b0 = new Array(CONTEXT_DIM).fill(0.0);

      sharedState = await LinUCBState.create({
        scope: 'shared',
        actionId: 'global',
        contextDim: CONTEXT_DIM,
        A: I12,
        b: b0,
        A0: I12,
        b0,
        totalUpdates: 0,
        totalReward: 0,
        modelVersion: 'hybrid_linucb_v1',
      });
    }

    res.json({
      success: true,
      data: {
        A0: sharedState.A0 || sharedState.A,
        b0: sharedState.b0 || sharedState.b,
        totalUpdates: sharedState.totalUpdates,
        modelVersion: sharedState.modelVersion,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// POST /api/c3/recommendations/sync
// ---------------------------------------------------------------------------
const syncState = async (req, res) => {
  try {
    const { childId: rawChildId, armUpdates, sharedDelta } = req.body;
    const childId = await resolveChildId(rawChildId, req.user);
    if (!childId) {
      return res.status(404).json({ success: false, message: 'Child profile not found' });
    }

    // 1. Upsert child arm updates if provided
    if (Array.isArray(armUpdates)) {
      for (const update of armUpdates) {
        if (!update.armId || !update.A || !update.b) continue;
        await LinUCBState.findOneAndUpdate(
          { scope: childId, actionId: update.armId },
          {
            $set: {
              contextDim: CONTEXT_DIM,
              A: update.A,
              b: update.b,
              B: update.B || null,
              lastUpdated: new Date(),
            },
            $inc: {
              totalUpdates: 1,
              totalReward: update.reward || 0,
            },
          },
          { upsert: true, new: true, setDefaultsOnInsert: true }
        );
      }
    }

    // 2. Accumulate sharedDelta into the shared aggregate (if provided)
    if (sharedDelta && sharedDelta.deltaA0 && sharedDelta.deltab0) {
      const sharedDoc = await LinUCBState.findOne({ scope: 'shared', actionId: 'global' });
      if (sharedDoc) {
        const A0 = sharedDoc.A0 || sharedDoc.A;
        const b0 = sharedDoc.b0 || sharedDoc.b;

        // Element-wise accumulation
        for (let i = 0; i < CONTEXT_DIM; i++) {
          b0[i] += sharedDelta.deltab0[i] || 0;
          for (let j = 0; j < CONTEXT_DIM; j++) {
            A0[i][j] += (sharedDelta.deltaA0[i] && sharedDelta.deltaA0[i][j]) || 0;
          }
        }

        sharedDoc.A0 = A0;
        sharedDoc.b0 = b0;
        sharedDoc.totalUpdates += 1;
        if (sharedDelta.reward) sharedDoc.totalReward += sharedDelta.reward;
        sharedDoc.lastUpdated = new Date();
        await sharedDoc.save();
      }
    }

    // Return the latest shared parameters
    const latestShared = await LinUCBState.findOne({ scope: 'shared', actionId: 'global' }).lean();
    res.json({
      success: true,
      data: {
        synced: true,
        sharedA0: latestShared?.A0 || null,
        sharedb0: latestShared?.b0 || null,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ---------------------------------------------------------------------------
// POST /api/c3/recommendations/next-activity
// ---------------------------------------------------------------------------
const getNextActivity = async (req, res) => {
  try {
    const { childId: rawChildId, sessionId } = req.body;
    const childId = await resolveChildId(rawChildId, req.user);
    if (!childId || !sessionId) {
      return res.status(400).json({ message: 'childId and sessionId are required' });
    }

    const activity = await recommendationService.recommendNextActivity(childId, sessionId);
    
    res.json({
      success: true,
      data: activity
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getContext,
  getSharedState,
  syncState,
  getNextActivity,
};

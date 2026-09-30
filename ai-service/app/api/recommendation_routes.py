from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any
from app.processing.linucb import LinUCB
import random

router = APIRouter(prefix="/c3/recommendations", tags=["Recommendation"])

# Initialize LinUCB model (Alpha = 1.0, Context Dimension = 10 for prototype)
linucb_model = LinUCB(alpha=1.0, context_dim=10)

class ContextRequest(BaseModel):
    childId: str
    sessionId: str
    context_vector: List[float]
    eligible_activities: List[str]

class RewardRequest(BaseModel):
    childId: str
    sessionId: str
    activityId: str
    context_vector: List[float]
    reward: float

@router.post("/next-activity")
async def get_next_activity(request: ContextRequest):
    """
    Recommends the next therapy activity using LinUCB.
    """
    try:
        if not request.eligible_activities:
            raise HTTPException(status_code=400, detail="No eligible activities provided.")
            
        if len(request.context_vector) != linucb_model.context_dim:
            raise HTTPException(status_code=400, detail=f"Context vector must be of dimension {linucb_model.context_dim}")

        selected_activity = linucb_model.select_activity(request.context_vector, request.eligible_activities)
        
        return {
            "activityId": selected_activity,
            "method": "LinUCB",
            "context_used": request.context_vector
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/update-reward")
async def update_reward(request: RewardRequest):
    """
    Updates the LinUCB model with the observed reward from a completed plan/activity.
    """
    try:
        if len(request.context_vector) != linucb_model.context_dim:
            raise HTTPException(status_code=400, detail=f"Context vector must be of dimension {linucb_model.context_dim}")

        linucb_model.update(request.activityId, request.context_vector, request.reward)
        
        return {
            "status": "success",
            "message": f"Updated LinUCB model for activity {request.activityId} with reward {request.reward}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

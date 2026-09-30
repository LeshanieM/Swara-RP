from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from linucb import LinUCBEngine

app = FastAPI(title="Component 3 LinUCB Engine")

engine = LinUCBEngine()

class RecommendRequest(BaseModel):
    context: List[float]
    eligible_activities: List[str]

class RecommendResponse(BaseModel):
    selected_activity: str
    ucb_scores: dict

class UpdateRequest(BaseModel):
    activity_id: str
    context: List[float]
    reward: float

@app.get("/")
def read_root():
    return {"message": "Welcome to Swara C3 LinUCB Recommendation API"}

@app.post("/recommend", response_model=RecommendResponse)
def recommend_activity(req: RecommendRequest):
    if not req.eligible_activities:
        raise HTTPException(status_code=400, detail="No eligible activities provided")
    
    selected_activity, scores = engine.recommend(req.context, req.eligible_activities)
    return {"selected_activity": selected_activity, "ucb_scores": scores}

@app.post("/update")
def update_model(req: UpdateRequest):
    engine.update(req.activity_id, req.context, req.reward)
    return {"message": "Model updated successfully"}

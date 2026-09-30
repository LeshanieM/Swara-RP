import numpy as np

class LinUCBEngine:
    def __init__(self, alpha: float = 1.0, context_dim: int = 3):
        self.alpha = alpha
        self.context_dim = context_dim
        # A dictionary to store matrix A for each activity arm
        self.A = {}
        # A dictionary to store vector b for each activity arm
        self.b = {}

    def _initialize_arm(self, activity_id: str):
        if activity_id not in self.A:
            # Identity matrix for A
            self.A[activity_id] = np.identity(self.context_dim)
            # Zero vector for b
            self.b[activity_id] = np.zeros(self.context_dim)

    def recommend(self, context: list, eligible_activities: list):
        x = np.array(context)
        p_t = {}
        
        for activity in eligible_activities:
            self._initialize_arm(activity)
            
            A_a = self.A[activity]
            b_a = self.b[activity]
            
            A_a_inv = np.linalg.inv(A_a)
            theta_a = A_a_inv.dot(b_a)
            
            # Contextual upper-confidence score
            p = theta_a.T.dot(x) + self.alpha * np.sqrt(x.T.dot(A_a_inv).dot(x))
            p_t[activity] = float(p)
            
        # Select activity with highest UCB score
        selected_activity = max(p_t, key=p_t.get)
        return selected_activity, p_t

    def update(self, activity_id: str, context: list, reward: float):
        self._initialize_arm(activity_id)
        
        x = np.array(context)
        
        # Update A and b based on the observed reward
        # A_a = A_a + x * x^T
        self.A[activity_id] += np.outer(x, x)
        
        # b_a = b_a + reward * x
        self.b[activity_id] += reward * x

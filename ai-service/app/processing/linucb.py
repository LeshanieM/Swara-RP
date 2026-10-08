import numpy as np
from typing import Dict, List, Tuple

class LinUCB:
    def __init__(self, alpha: float, context_dim: int):
        """
        LinUCB contextual bandit algorithm.
        :param alpha: Exploration parameter.
        :param context_dim: Dimension of the context vector.
        """
        self.alpha = alpha
        self.context_dim = context_dim
        # Maintain A and b for each activity (action).
        # A_a is d x d matrix (inverse of covariance).
        # b_a is d x 1 vector.
        self.A: Dict[str, np.ndarray] = {}
        self.A_inv: Dict[str, np.ndarray] = {}
        self.b: Dict[str, np.ndarray] = {}

    def _initialize_action(self, action_id: str):
        if action_id not in self.A:
            self.A[action_id] = np.identity(self.context_dim)
            self.A_inv[action_id] = np.identity(self.context_dim)
            self.b[action_id] = np.zeros((self.context_dim, 1))

    def select_activity(self, context_vector: List[float], eligible_activities: List[str]) -> str:
        """
        Selects an activity based on the LinUCB algorithm.
        :param context_vector: The context vector x.
        :param eligible_activities: List of eligible activity IDs.
        :return: Selected activity ID.
        """
        if not eligible_activities:
            raise ValueError("Eligible activities list is empty.")
            
        x = np.array(context_vector).reshape((self.context_dim, 1))
        
        highest_ucb = -float('inf')
        selected_activity = None
        
        for activity_id in eligible_activities:
            self._initialize_action(activity_id)
            
            A_inv_a = self.A_inv[activity_id]
            b_a = self.b[activity_id]
            
            theta_a = A_inv_a.dot(b_a)
            
            # expected reward = theta^T x
            expected_reward = theta_a.T.dot(x)[0, 0]
            
            # exploration term = alpha * sqrt(x^T A^-1 x)
            exploration = self.alpha * np.sqrt(x.T.dot(A_inv_a).dot(x)[0, 0])
            
            ucb = expected_reward + exploration
            
            if ucb > highest_ucb:
                highest_ucb = ucb
                selected_activity = activity_id
                
        return selected_activity

    def update(self, activity_id: str, context_vector: List[float], reward: float):
        """
        Updates the model parameters after observing a reward.
        :param activity_id: The activity ID that was recommended.
        :param context_vector: The context vector x.
        :param reward: The observed reward (e.g. TSS / 100).
        """
        self._initialize_action(activity_id)
        x = np.array(context_vector).reshape((self.context_dim, 1))
        
        # A_a = A_a + x * x^T
        self.A[activity_id] += x.dot(x.T)
        
        # Update A_inv efficiently or just invert
        self.A_inv[activity_id] = np.linalg.inv(self.A[activity_id])
        
        # b_a = b_a + r * x
        self.b[activity_id] += reward * x

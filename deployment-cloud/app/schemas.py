from pydantic import BaseModel, Field
from typing import List

class SentimentRequest(BaseModel):
    text: str = Field(min_length=3, max_length=500)

class WordContribution(BaseModel):
    word: str
    contribution: float

class SentimentExplanation(BaseModel):
    supporting_words: List[WordContribution]
    opposing_words: List[WordContribution]

class SentimentResponse(BaseModel):
    label: str
    score: float
    explanation: SentimentExplanation

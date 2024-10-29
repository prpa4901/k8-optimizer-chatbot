from pydantic import BaseModel
from typing import List

class ChatMessage(BaseModel):
    message: str

class NodeUsage(BaseModel):
    name: str
    cpu_usage: str
    memory_usage: str
    pod_count: int

class ResourceUsage(BaseModel):
    nodes: List[NodeUsage]

class ResourceAnalysis(BaseModel):
    recommendations: List[str]


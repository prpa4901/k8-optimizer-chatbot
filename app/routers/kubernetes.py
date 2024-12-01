from fastapi import APIRouter, Depends
from app.services.k8s_service import K8sService
from app.models.k8s_models import ResourceUsage, ResourceAnalysis, ChatMessage

router = APIRouter()

@router.post("/chat", response_model=dict)
async def chat(message: ChatMessage, k8s_service: K8sService = Depends(K8sService)):
    user_input = message.message.lower()
    
    if 'resource usage' in user_input:
        return {"response": "Here's the current resource usage:", "data": k8s_service.get_resource_usage()}
    elif 'optimize' in user_input:
        return {"response": "Here's the resource analysis and optimization suggestions:", "data": k8s_service.analyze_resources()}
    else:
        return {"response": "I'm not sure how to help with that. You can ask about resource usage or optimization."}

@router.get("/resources", response_model=ResourceUsage)
async def get_resources(k8s_service: K8sService = Depends(K8sService)):
    return k8s_service.get_resource_usage()

@router.get("/analyze", response_model=ResourceAnalysis)
async def analyze_resources(k8s_service: K8sService = Depends(K8sService)):
    return k8s_service.analyze_resources()

from fastapi import FastAPI
# from app.routers import kubernetes

app = FastAPI(title="K8 resource optimizer chat")

#app.include_router(kubernetes.router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "Welcome to the Kubernetes Resource Optimizer Chatbot!"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8089)

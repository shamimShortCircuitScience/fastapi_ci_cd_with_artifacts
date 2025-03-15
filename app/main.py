from fastapi import FastAPI


# create first api app
app = FastAPI()


@app.get("/")
def hello():
    return {"message": "Hello, CI/CD with FastAPI!"}
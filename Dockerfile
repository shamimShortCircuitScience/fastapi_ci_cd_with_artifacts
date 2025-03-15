# Python base Image 
FROM python:3.9-slim

# install the system dependencies 
# RUN apt-ge
# working directory inside the container 
WORKDIR /app 

# copy the requirements.txt
COPY requirements.txt /app 

# install the dependencies 
RUN pip install -r requirements.txt 

# Copy the rest of the file 
COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Worship Pads - Web Version

This is the web version of the Worship Pads mobile application. It is built as a monolithic app with a React frontend and a FastAPI backend.

## Project Structure
- `backend/`: FastAPI application containing the API endpoints and SQLite database models.
- `frontend/`: React application (built with Vite) featuring a premium dynamic user interface.

## How to Run the App (Monolithic Production Mode)

In this mode, the FastAPI backend serves both the API endpoints and the pre-built React frontend static files.

1. **Build the Frontend**:
   ```bash
   cd frontend
   npm install
   npm run build
   ```

2. **Run the Backend**:
   ```bash
   cd ../backend
   python -m venv venv
   
   # On Windows:
   .\venv\Scripts\activate
   
   # On macOS/Linux:
   # source venv/bin/activate
   
   # Install dependencies
   pip install fastapi "uvicorn[standard]" sqlalchemy pydantic python-pptx
   
   # Start the FastAPI server
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

3. **Access the App**:
   Open your browser and navigate to [http://localhost:8000](http://localhost:8000). The React app will be served directly by the backend!

## How to Run the App (Development Mode)

If you are actively developing and want Hot Module Replacement (HMR) for the frontend:

1. **Run the Backend (Terminal 1)**:
   ```bash
   cd backend
   .\venv\Scripts\activate
   uvicorn main:app --reload --port 8000
   ```

2. **Run the Frontend (Terminal 2)**:
   ```bash
   cd frontend
   npm run dev
   ```

3. **Access the Dev Server**:
   Open your browser and navigate to [http://localhost:5173](http://localhost:5173). The frontend is configured to talk to the backend via CORS.

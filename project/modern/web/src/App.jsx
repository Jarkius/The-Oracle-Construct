import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginForm from './components/Login/LoginForm';
import Dashboard from './pages/Dashboard';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import './App.css';

function App() {
  return (
    <BrowserRouter>
      <main>
        <Routes>
          {/* Public Route: Login */}
          <Route path="/" element={<LoginForm />} />

          {/* Protected Route: Dashboard */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />

          {/* Catch all: Redirect to Login */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </BrowserRouter>
  );
}

export default App;

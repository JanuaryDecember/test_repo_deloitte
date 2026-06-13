import { Navigate, Outlet } from 'react-router';
import { useAuth } from './useAuth';

export function ProtectedRoute() {
  const { user } = useAuth();

  if (user === null) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}


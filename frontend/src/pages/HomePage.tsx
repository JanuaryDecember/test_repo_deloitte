import { useEffect } from 'react';
import { useAuth } from '../auth/useAuth';
import styles from './HomePage.module.css';

export function HomePage() {
  const { user, logout } = useAuth();

  useEffect(() => {
    document.title = 'Deloitter';
  }, []);

  return (
    <div className={styles.page}>
      <h1 className={styles.heading}>Welcome, {user?.firstName}!</h1>
      <p className={styles.subtext}>
        Your next connection is one swipe away. Start discovering colleagues who share your interests.
      </p>
      <button type="button" className={styles.logoutBtn} onClick={logout}>
        Log out
      </button>
    </div>
  );
}

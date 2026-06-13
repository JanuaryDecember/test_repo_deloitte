import { Outlet, useNavigate, useLocation } from 'react-router';
import { useAuth } from '../auth/useAuth';
import styles from './AppShell.module.css';

export function AppShell() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { pathname } = useLocation();

  // Derive active tab from current path
  const activeTab = pathname.startsWith('/matches')
    ? 'matches'
    : pathname.startsWith('/profile')
      ? 'profile'
      : 'discover'; // covers '/' and '/discover'

  const initials = user
    ? `${user.firstName.charAt(0)}${user.lastName.charAt(0)}`.toUpperCase()
    : '';

  return (
    <div className={styles.wrapper}>
      <header className={styles.header}>
        {/* Logo */}
        <div className={styles.logoGroup}>
          <div className={styles.logoMark}>d</div>
          <span className={styles.logoText}>Deloitter</span>
        </div>

        {/* Nav + avatar */}
        <nav className={styles.nav}>
          <button
            type="button"
            className={styles.navBtn}
            onClick={() => navigate('/discover')}
            aria-current={activeTab === 'discover' ? 'page' : undefined}
          >
            Discover
            {activeTab === 'discover' && (
              <div className={styles.navActiveBar} />
            )}
          </button>
          <button
            type="button"
            className={styles.navBtn}
            onClick={() => navigate('/matches')}
            aria-current={activeTab === 'matches' ? 'page' : undefined}
          >
            Matches
            {activeTab === 'matches' && (
              <div className={styles.navActiveBar} />
            )}
          </button>
          <button
            type="button"
            className={styles.navBtn}
            onClick={() => navigate('/profile')}
            aria-current={activeTab === 'profile' ? 'page' : undefined}
          >
            Profile
            {activeTab === 'profile' && (
              <div className={styles.navActiveBar} />
            )}
          </button>

          <div className={styles.avatar} aria-label={`User ${user?.firstName ?? ''}`}>
            {initials}
          </div>
        </nav>
      </header>

      <main className={styles.main}>
        <Outlet />
      </main>
    </div>
  );
}




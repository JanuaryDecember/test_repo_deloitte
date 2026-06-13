import { Outlet } from 'react-router';
import { useAuth } from '../auth/useAuth';
import styles from './AppShell.module.css';

type Tab = 'discover' | 'matches' | 'profile';

export function AppShell() {
  const { user } = useAuth();

  // Nav tabs are non-functional placeholders in S-01.
  // Active tab defaults to "Discover".
  const activeTab = 'discover' as Tab;

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
          <button type="button" className={styles.navBtn}>
            Discover
            {activeTab === 'discover' && (
              <div className={styles.navActiveBar} />
            )}
          </button>
          <button type="button" className={styles.navBtn}>
            Matches
            {activeTab === 'matches' && (
              <div className={styles.navActiveBar} />
            )}
          </button>
          <button type="button" className={styles.navBtn}>
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




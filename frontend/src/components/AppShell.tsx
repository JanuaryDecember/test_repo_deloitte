import { useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router';
import { useAuth } from '../auth/useAuth';
import { useMatchCount } from '../contexts/MatchContext';
import { fetchMatches } from '../api/client';
import styles from './AppShell.module.css';

export function AppShell() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const { matchCount, setMatchCount } = useMatchCount();

  // Fetch initial match count once on mount
  useEffect(() => {
    let cancelled = false;
    fetchMatches()
      .then((data) => {
        if (!cancelled) setMatchCount(data.length);
      })
      .catch(() => {
        // Silently ignore — badge will just show 0
      });
    return () => {
      cancelled = true;
    };
  }, [setMatchCount]);

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
            {matchCount > 0 && (
              <span className={styles.matchBadge} aria-label={`${matchCount} matches`}>
                {matchCount}
              </span>
            )}
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




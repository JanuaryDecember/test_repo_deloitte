import { useNavigate } from 'react-router';
import styles from './MatchesPlaceholder.module.css';

export function MatchesPlaceholder() {
  const navigate = useNavigate();

  return (
    <div className={styles.page}>
      <div className={styles.card}>
        <div className={styles.iconWrap} aria-hidden="true">💚</div>
        <h1 className={styles.title}>No matches yet</h1>
        <p className={styles.subtitle}>
          Keep swiping in Discover — matches show up here.
        </p>
        <button
          type="button"
          className={styles.ctaBtn}
          onClick={() => navigate('/discover')}
        >
          Start swiping
        </button>
      </div>
    </div>
  );
}


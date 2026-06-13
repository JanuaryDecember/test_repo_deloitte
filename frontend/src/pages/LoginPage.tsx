import { useState, useEffect } from 'react';
import { useNavigate, Navigate } from 'react-router';
import { useAuth } from '../auth/useAuth';
import styles from './LoginPage.module.css';

export function LoginPage() {
  const { user, login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    document.title = 'Deloitter — Log in';
  }, []);

  // Already authenticated — redirect away
  if (user !== null) {
    return <Navigate to="/" replace />;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await login(email, password);
      navigate('/', { replace: true });
    } catch {
      setError('Invalid email or password');
    } finally {
      setLoading(false);
    }
  }

  const hasError = error !== null;

  return (
    <div className={styles.page}>
      <div className={styles.circle1} aria-hidden="true" />
      <div className={styles.circle2} aria-hidden="true" />

      <div className={styles.card}>
        {/* Logo row */}
        <div className={styles.logoRow}>
          <div className={styles.logoIcon} aria-hidden="true">d</div>
          <div className={styles.logoText}>Deloitter</div>
        </div>

        {/* Heading */}
        <h1 className={styles.heading}>
          Find your people<br />inside the firm.
        </h1>
        <p className={styles.subtext}>
          Swipe through colleagues who share your interests and skills. Match, then take it to Teams.
        </p>

        {/* Form */}
        <form className={styles.form} onSubmit={handleSubmit} noValidate>
          <label htmlFor="email" className={styles.label}>Work email</label>
          <input
            id="email"
            type="email"
            className={`${styles.input} ${styles.emailField}`}
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoFocus
            autoComplete="username"
            aria-invalid={hasError ? 'true' : undefined}
          />

          <label htmlFor="password" className={styles.label}>Password</label>
          <input
            id="password"
            type="password"
            className={`${styles.input} ${styles.passwordField}`}
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            autoComplete="current-password"
            aria-invalid={hasError ? 'true' : undefined}
          />

          <button
            type="submit"
            className={styles.submitBtn}
            disabled={loading}
          >
            {loading ? 'Logging in…' : 'Log in'}
          </button>

          {error && (
            <p className={styles.error} role="alert" aria-live="assertive">
              {error}
            </p>
          )}
        </form>

        <p className={styles.footer}>Pre-seeded demo account · no real data</p>
      </div>
    </div>
  );
}


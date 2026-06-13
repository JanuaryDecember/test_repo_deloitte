import { useEffect, useState } from 'react';
import { fetchCatalog, fetchProfile, fetchSelections, updateSelections } from '../api/client';
import type { CatalogResponse, UserProfile } from '../types/profile';
import { Toast } from '../components/Toast';
import styles from './ProfilePage.module.css';

export function ProfilePage() {
  const [catalog, setCatalog] = useState<CatalogResponse | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [catalogLoading, setCatalogLoading] = useState(true);
  const [catalogError, setCatalogError] = useState(false);
  const [selectedInterestIds, setSelectedInterestIds] = useState<Set<number>>(new Set());
  const [selectedCompetencyIds, setSelectedCompetencyIds] = useState<Set<number>>(new Set());
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    document.title = 'Deloitter — Profile';
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setCatalogLoading(true);
      setCatalogError(false);
      try {
        const [catalogData, profileData, selectionsData] = await Promise.all([
          fetchCatalog(),
          fetchProfile(),
          fetchSelections(),
        ]);
        if (cancelled) return;
        setCatalog(catalogData);
        setProfile(profileData);
        setSelectedInterestIds(new Set(selectionsData.interestIds));
        setSelectedCompetencyIds(new Set(selectionsData.competencyIds));
      } catch {
        if (!cancelled) setCatalogError(true);
      } finally {
        if (!cancelled) setCatalogLoading(false);
      }
    }

    load();
    return () => { cancelled = true; };
  }, [retryKey]);

  function toggleInterest(id: number) {
    setSelectedInterestIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }

  function toggleCompetency(id: number) {
    setSelectedCompetencyIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }

  async function handleSave() {
    setSaving(true);
    try {
      await updateSelections({
        interestIds: Array.from(selectedInterestIds),
        competencyIds: Array.from(selectedCompetencyIds),
      });
      setToast('Profile updated');
    } catch {
      setToast('Failed to save — please try again');
    } finally {
      setSaving(false);
    }
  }

  if (catalogLoading) {
    return (
      <div className={styles.page}>
        <p className={styles.loading}>Loading…</p>
      </div>
    );
  }

  if (catalogError) {
    return (
      <div className={styles.page}>
        <div className={styles.error}>
          <span>Could not load catalog.</span>
          <button type="button" className={styles.retryBtn} onClick={() => setRetryKey((k) => k + 1)}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.page}>
      {/* User header card */}
      {profile && (
        <div className={styles.headerCard}>
          <div className={styles.avatar}>{profile.initials}</div>
          <div className={styles.userInfo}>
            <h1 className={styles.userName}>
              {profile.firstName} {profile.lastName}
            </h1>
            <p className={styles.userMeta}>
              {profile.roleFamily} · {profile.serviceLine}
            </p>
          </div>
        </div>
      )}

      {/* Interests section */}
      <section className={styles.section}>
        <h2 className={styles.sectionHeading}>Your interests</h2>
        <p className={styles.sectionSubtitle}>
          These drive who you match with. Tap to toggle.
        </p>
        <div className={styles.chips}>
          {catalog?.interests.map((item) => (
            <button
              key={item.id}
              type="button"
              className={`${styles.chip}${selectedInterestIds.has(item.id) ? ` ${styles.chipSelected}` : ''}`}
              aria-pressed={selectedInterestIds.has(item.id)}
              onClick={() => toggleInterest(item.id)}
            >
              {item.name}
            </button>
          ))}
          {catalog?.interests.length === 0 && (
            <span className={styles.loading}>No interests available</span>
          )}
        </div>
      </section>

      {/* Competencies section */}
      <section className={styles.section}>
        <h2 className={styles.sectionHeading}>Your competencies</h2>
        <p className={styles.sectionSubtitle}>
          Skills you bring — shared skills raise your compatibility.
        </p>
        <div className={styles.chips}>
          {catalog?.competencies.map((item) => (
            <button
              key={item.id}
              type="button"
              className={`${styles.chip}${selectedCompetencyIds.has(item.id) ? ` ${styles.chipSelected}` : ''}`}
              aria-pressed={selectedCompetencyIds.has(item.id)}
              onClick={() => toggleCompetency(item.id)}
            >
              {item.name}
            </button>
          ))}
          {catalog?.competencies.length === 0 && (
            <span className={styles.loading}>No competencies available</span>
          )}
        </div>
      </section>

      {/* Save button */}
      <button
        type="button"
        className={styles.saveBtn}
        onClick={handleSave}
        disabled={saving || catalogLoading}
      >
        {saving ? 'Saving…' : 'Save profile'}
      </button>

      <Toast message={toast} onDismiss={() => setToast(null)} />
    </div>
  );
}

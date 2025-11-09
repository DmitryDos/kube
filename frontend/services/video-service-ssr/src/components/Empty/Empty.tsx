import styles from './Empty.module.css';

interface EmptyProps {
  title: string;
  message: string;
  icon?: React.ReactNode;
}

export function Empty({ title, message, icon }: EmptyProps) {
  return (
    <div className={styles['container']}>
      {icon || (
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.35-4.35" />
        </svg>
      )}
      <h2>{title}</h2>
      <p>{message}</p>
    </div>
  );
}


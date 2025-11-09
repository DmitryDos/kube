import styles from './Loading.module.css';

interface LoadingProps {
  message?: string;
}

export function Loading({ message = 'Загрузка...' }: LoadingProps) {
  return (
    <div className={styles['container']}>
      <div className={styles['spinner']}></div>
      <p>{message}</p>
    </div>
  );
}


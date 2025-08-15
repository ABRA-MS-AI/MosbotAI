import React from 'react';
import styles from './Logo.module.css';
import logo from '../../assets/images/logo.png';

interface LogoProps {
  size?: 'small' | 'medium' | 'large';
  animated?: boolean;
  className?: string;
}

const Logo: React.FC<LogoProps> = ({ 
  size = 'medium', 
  animated = true, 
  className = '' 
}) => {
  const sizeClass = {
    small: styles.logoSmall,
    medium: styles.logoMedium,
    large: styles.logoLarge
  };

  return (
    <div className={`${styles.logoContainer} ${sizeClass[size]} ${animated ? styles.animated : ''} ${className}`}>
      <img 
        src={logo} 
        alt="Company Logo" 
        className={styles.logo}
      />
      <div className={styles.logoGlow}></div>
    </div>
  );
};

export default Logo;
import React, { useState, useEffect, useRef, RefObject } from "react";
import { Outlet, NavLink, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import styles from "./Layout.module.css";

import { useLogin } from "../../authConfig";
import { LoginButton } from "../../components/LoginButton";

// Import your logo
import logo from "../../assets/images/mosbot-logo.png";

const Layout = () => {
    const { t } = useTranslation();

    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <div className={styles.headerContainer}>
                    {/* Left side - Login button */}
                    <div className={styles.headerLeft}>
                        {useLogin && <LoginButton />}
                    </div>

                    {/* Center - Navigation */}
                    <nav className={styles.headerCenter}>
                        <NavLink
                            to="/qa"
                            className={({ isActive }) => 
                                isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink
                            }
                        >
                            שאלה
                        </NavLink>
                        <NavLink
                            to="/"
                            className={({ isActive }) => 
                                isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink
                            }
                        >
                            צ'אט
                        </NavLink>
                    </nav>

                    {/* Right side - Logo and title */}
                    <Link to="/" className={styles.headerRight}>
                        <span className={styles.headerTitle}>מוסבוט</span>
                        <img 
                            src={logo} 
                            alt="מוסבוט" 
                            className={styles.headerLogo}
                        />
                    </Link>
                </div>
            </header>
            <Outlet />
        </div>
    );
};

export default Layout;

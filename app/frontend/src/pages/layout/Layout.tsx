import React from "react";
import { Outlet, Link } from "react-router-dom";
import styles from "./Layout.module.css";
import { useLogin } from "../../authConfig";
import { LoginButton } from "../../components/LoginButton";
import logo from "../../assets/images/mosbot-logo.png";

const Layout = () => {
    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <div className={styles.headerContainer}>
                    {/* Right corner - Login button */}
                    <div className={styles.headerRight}>
                        {useLogin && <LoginButton />}
                    </div>
                    
                    {/* Center - Big Mosbot title */}
                    <div className={styles.headerCenter}>
                        <h1 className={styles.headerTitleBig}>מוסבוט</h1>
                    </div>
                    
                    {/* Left corner - Logo only */}
                    <div className={styles.headerLeft}>
                        <img 
                            src={logo} 
                            alt="מוסבוט" 
                            className={styles.headerLogoCorner}
                        />
                    </div>
                </div>
            </header>
            <Outlet />
        </div>
    );
};

export default Layout;

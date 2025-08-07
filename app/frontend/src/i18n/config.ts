import i18next from "i18next";
import { initReactI18next } from "react-i18next";

import heTranslation from "../locales/he/translation.json";

export const supportedLngs: { [key: string]: { name: string; locale: string } } = {
    he: {
        name: "עברית",
        locale: "he-IL"
    }
};

i18next
    .use(initReactI18next)
    // init i18next
    // for all options read: https://www.i18next.com/overview/configuration-options
    .init({
        resources: {
            he: { translation: heTranslation }
        },
        lng: "he", // Set Hebrew as default
        fallbackLng: "he",
        supportedLngs: ["he"],
        debug: import.meta.env.DEV,
        interpolation: {
            escapeValue: false // not needed for react as it escapes by default
        }
    });

export default i18next;

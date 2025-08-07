// Language picker disabled for Hebrew-only version
interface Props {
    onLanguageChange: (language: string) => void;
}

export const LanguagePicker = ({ onLanguageChange }: Props) => {
    // Return null for Hebrew-only version - no language picker needed
    return null;
};

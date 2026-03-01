import { StatusBar } from "expo-status-bar";
import { AuthProvider } from "./src/auth/AuthContext";
import { BackendUrlProvider } from "./src/dev/BackendUrlContext";
import { I18nProvider } from "./src/i18n/I18nContext";
import { AppNavigator } from "./src/navigation/AppNavigator";

export default function App() {
  return (
    <BackendUrlProvider>
      <I18nProvider>
        <AuthProvider>
          <AppNavigator />
          <StatusBar style="auto" />
        </AuthProvider>
      </I18nProvider>
    </BackendUrlProvider>
  );
}

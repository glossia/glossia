import { createRoot } from 'react-dom/client';
import '@shopify/polaris/build/esm/styles.css';

import enTranslations from '@shopify/polaris/locales/en.json';
import {AppProvider, Page, LegacyCard, Button} from '@shopify/polaris';

const domNode = document.getElementById('root') as HTMLElement;
const root = createRoot(domNode);
root.render(<AppProvider i18n={enTranslations}>
    <Page title="Example app">
      <LegacyCard sectioned>
        <Button onClick={() => alert('Button clicked!')}>Example button</Button>
      </LegacyCard>
    </Page>
  </AppProvider>);
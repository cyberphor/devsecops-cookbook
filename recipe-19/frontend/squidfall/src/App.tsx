import { CacheProvider } from '@emotion/react';
import createCache from '@emotion/cache';
import DashboardIcon from '@mui/icons-material/Dashboard';
import PersonIcon from '@mui/icons-material/Person';
import { Outlet } from 'react-router';
import { ReactRouterAppProvider } from '@toolpad/core/react-router';
import type { Navigation } from '@toolpad/core/AppProvider';

const nonce = '12345'; 

const emotionCache = createCache({ key: 'css', nonce: nonce });

const NAVIGATION: Navigation = [
  {
    kind: 'header',
    title: 'Main items',
  },
  {
    title: 'Dashboard',
    icon: <DashboardIcon />,
  },
  {
    segment: 'employees',
    title: 'Employees',
    icon: <PersonIcon />,
    pattern: 'employees{/:employeeId}*',
  },
];

const BRANDING = {
  title: "squidfall",
};

export default function App() {
  return (
    <CacheProvider value={emotionCache}>
      <ReactRouterAppProvider navigation={NAVIGATION} branding={BRANDING}>
        <Outlet />
      </ReactRouterAppProvider>
    </CacheProvider>
  );
}

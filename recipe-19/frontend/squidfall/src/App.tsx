import * as React from 'react';
import DashboardIcon from '@mui/icons-material/Dashboard';
import PersonIcon from '@mui/icons-material/Person';
import { Outlet } from 'react-router';
import { ReactRouterAppProvider } from '@toolpad/core/react-router';
import type { Navigation } from '@toolpad/core/AppProvider';
import { CacheProvider } from '@emotion/react';
import createCache from '@emotion/cache';

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

const nonce = document
  .querySelector('meta[name="csp-nonce"]')
  ?.getAttribute('content') || 'not-set';

const cache = createCache({
  key: 'css',
  nonce: nonce,
  prepend: true
});


export default function App() {
  return (
    <CacheProvider value={cache}>
      <ReactRouterAppProvider navigation={NAVIGATION} branding={BRANDING}>
        <Outlet />
      </ReactRouterAppProvider>
    </CacheProvider>
  );
}

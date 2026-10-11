import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { PreviewShell } from './app/PreviewShell';
import './styles/tokens.css';
import './styles/base.css';
import './styles/shell.css';
import './styles/components.css';
import './styles/screens.css';

const root = document.getElementById('root');
if (!root) throw new Error('Root element #root is missing from index.html');

createRoot(root).render(
  <StrictMode>
    <PreviewShell />
  </StrictMode>,
);

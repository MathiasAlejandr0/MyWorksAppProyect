import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClientProvider } from '@tanstack/react-query'
import '@fontsource-variable/dm-sans/wght.css'
import './index.css'
import App from './App.tsx'
import { AcademicNoticeBanner } from './components/AcademicNoticeBanner.tsx'
import { AuthProvider } from './context/AuthContext.tsx'
import { queryClient } from './queryClient'
import { PasswordRecoveryModal } from './components/PasswordRecoveryModal'
import { TestingSurveyModal } from './components/TestingSurveyModal'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <AcademicNoticeBanner />
          <App />
          <PasswordRecoveryModal />
          <TestingSurveyModal />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
)

if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {});
  });
}

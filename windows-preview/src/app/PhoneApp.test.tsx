import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ToastProvider } from '../components/Toast';
import { DataProvider } from '../data/store';
import { PhoneApp } from './PhoneApp';
import { RouterProvider } from './router';

let n = 0;
const renderApp = () =>
  render(
    <DataProvider dbName={`app-test-${++n}`}>
      <RouterProvider>
        <ToastProvider>
          <PhoneApp />
        </ToastProvider>
      </RouterProvider>
    </DataProvider>,
  );

describe('PhoneApp flows', () => {
  it('walks through onboarding into the dashboard', async () => {
    const user = userEvent.setup();
    renderApp();
    expect(await screen.findByText('Grow with confidence.')).toBeInTheDocument();
    for (let i = 0; i < 3; i++) await user.click(screen.getByRole('button', { name: /continue/i }));
    await user.click(screen.getByRole('button', { name: /get started/i }));
    expect(await screen.findByRole('navigation', { name: 'Main' })).toBeInTheDocument();
  });

  it('validates and adds a plant, then shows its details', async () => {
    const user = userEvent.setup();
    renderApp();
    await user.click(await screen.findByRole('button', { name: /skip/i }));
    const nav = await screen.findByRole('navigation', { name: 'Main' });
    await user.click(within(nav).getByRole('button', { name: /^my plants/i }));
    await user.click(await screen.findByRole('button', { name: 'Add plant' }));

    const dialog = await screen.findByRole('dialog');
    await user.click(within(dialog).getByRole('button', { name: 'Add' }));
    expect(await within(dialog).findByText('Give your plant a name.')).toBeInTheDocument();

    await user.type(within(dialog).getByLabelText(/plant name/i), 'Fernando');
    await user.selectOptions(within(dialog).getByLabelText(/^category/i), 'fern');
    await user.click(within(dialog).getByRole('button', { name: 'Add' }));

    expect(await screen.findByRole('heading', { name: 'Fernando' })).toBeInTheDocument();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('labels identification results as simulated in the preview', async () => {
    const user = userEvent.setup();
    renderApp();
    await user.click(await screen.findByRole('button', { name: /skip/i }));
    const nav = await screen.findByRole('navigation', { name: 'Main' });
    await user.click(within(nav).getByRole('button', { name: /identify/i }));
    expect((await screen.findAllByText(/simulat/i)).length).toBeGreaterThan(0);
  });
});

import { invoke } from '@tauri-apps/api/core';

const greetBtn = document.getElementById('greet-btn');
const greetingEl = document.getElementById('greeting');

greetBtn.addEventListener('click', async () => {
    try {
        const message = await invoke('greet_command', { name: 'Tauri User' });
        greetingEl.textContent = message;
    } catch (error) {
        console.error('Error invoking greet command:', error);
        greetingEl.textContent = 'Error: Could not invoke command';
    }
});

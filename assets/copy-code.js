if (navigator.clipboard?.writeText) {
  const icons = {
    'Copy code': '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V4a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h4"/>',
    'Copied!': '<path d="m5 12 4 4L19 6"/>',
    'Copy failed': '<path d="m6 6 12 12M6 18 18 6"/>',
  };

  document.querySelectorAll('.post-content pre > code').forEach((code) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'copy-code';
    button.setAttribute('aria-live', 'polite');
    let resetTimer;

    function showStatus(label) {
      button.title = label;
      button.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[label]}</svg><span>${label}</span>`;
    }

    showStatus('Copy code');

    button.addEventListener('click', async () => {
      clearTimeout(resetTimer);
      try {
        await navigator.clipboard.writeText(code.textContent);
        showStatus('Copied!');
      } catch {
        showStatus('Copy failed');
      }
      resetTimer = setTimeout(() => showStatus('Copy code'), 2000);
    });

    const pre = code.parentElement;
    const wrapper = document.createElement('div');
    wrapper.className = 'copyable-code';
    pre.before(wrapper);
    wrapper.append(pre, button);
    pre.addEventListener('scroll', () => {
      button.style.visibility = pre.scrollLeft === 0 ? '' : 'hidden';
    });
  });
}

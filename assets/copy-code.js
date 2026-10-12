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

const markdownButton = document.querySelector('.copy-markdown');
const markdownLink = document.querySelector('.view-markdown');
if (markdownButton && markdownLink) {
  const markdownLabel = markdownButton.textContent;
  let resetTimer;
  let markdownRequest;
  let markdownText;

  function loadMarkdown() {
    if (!markdownRequest) {
      markdownRequest = fetch(markdownLink.href).then((response) => {
        if (!response.ok) throw new Error('Could not load Markdown');
        return response.text();
      }).then((text) => {
        markdownText = text;
        return text;
      }).catch((error) => {
        markdownRequest = undefined;
        throw error;
      });
    }
    return markdownRequest;
  }

  function copySelection(text) {
    const selection = document.getSelection();
    const ranges = Array.from({ length: selection.rangeCount }, (_, i) => selection.getRangeAt(i).cloneRange());
    const activeElement = document.activeElement;
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.readOnly = true;
    textarea.style.cssText = 'position:fixed;top:0;left:0;opacity:0;font-size:16px;';
    document.body.append(textarea);
    try {
      textarea.focus({ preventScroll: true });
      textarea.select();
      textarea.setSelectionRange(0, textarea.value.length);
      if (!document.execCommand('copy')) throw new Error('Copy failed');
    } finally {
      textarea.remove();
      selection.removeAllRanges();
      ranges.forEach((range) => selection.addRange(range));
      activeElement?.focus({ preventScroll: true });
    }
  }

  // Have the text ready so the fallback can copy during the user's click.
  const prepareMarkdown = () => { loadMarkdown().catch(() => {}); };
  markdownButton.addEventListener('pointerenter', prepareMarkdown);
  markdownButton.addEventListener('focus', prepareMarkdown);
  if (!navigator.clipboard?.writeText) prepareMarkdown();

  markdownButton.addEventListener('click', async () => {
    if (markdownButton.getAttribute('aria-busy') === 'true') return;
    clearTimeout(resetTimer);
    markdownButton.setAttribute('aria-busy', 'true');
    markdownButton.textContent = 'Copying…';

    try {
      if (navigator.clipboard?.writeText) {
        try {
          if (navigator.clipboard.write && window.ClipboardItem) {
            // Start the clipboard write during the click, before fetching finishes.
            // Safari requires this user gesture even when the data arrives later.
            await navigator.clipboard.write([new ClipboardItem({
              'text/plain': loadMarkdown().then((text) => new Blob([text], { type: 'text/plain' })),
            })]);
          } else {
            await navigator.clipboard.writeText(await loadMarkdown());
          }
        } catch {
          copySelection(markdownText ?? await loadMarkdown());
        }
      } else {
        copySelection(markdownText ?? await loadMarkdown());
      }
      markdownButton.textContent = 'Copied!';
    } catch {
      markdownButton.textContent = 'Copy failed';
    } finally {
      markdownButton.removeAttribute('aria-busy');
      resetTimer = setTimeout(() => {
        markdownButton.textContent = markdownLabel;
      }, 2000);
    }
  });
}

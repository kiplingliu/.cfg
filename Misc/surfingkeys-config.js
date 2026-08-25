const DEBUG = false;

/* -------------------------------- Settings -------------------------------- */

// Problems with https://github.com/benbusby/farside:
// - On a VPN, some instances using https://github.com/TecharoHQ/anubis give "Invalid response"
// - Some instances are out of date
// - Slow
const REDLIB_URL = 'https://redlib.catsarch.com';
const NITTER_URL = 'https://nitter.net';

settings.blocklistPattern = /monkeytype\.com/;
settings.enableAutoFocus = false; // Required for e.g. discord, which autofocuses the input even on Esc
settings.hintAlign = 'left';
settings.smoothScroll = false;
settings.tabsThreshold = 0;

// 5ch.net, news.yahoo.co.jp, suki-kira.com
settings.nextLinkRegex = /\bnext\b|>>$|(?<!›)›(?!›)|(?<!‹.*)次(へ|\d+)/i;
settings.prevLinkRegex = /\bprev(ious)?\b|<<|(?<!‹)‹(?!‹)|前(へ|\d+)(?!.*›)/i;

settings.theme = `
#sk_status {
    border-radius: 4px;
    border: 1px solid #777;
    bottom: 0;
    font-size: 20px;
    opacity: 0.5;
    padding: 8px;
    position: fixed;
    right: 0;
    z-index: 2147483000;
}
`;

api.Hints.style('font-size: 14px');
api.Hints.style('font-size: 14px', 'text');

api.addSearchAlias(
    'r',
    'redlib',
    `${REDLIB_URL}/r/`,
    's',
    null,
    null,
    'o',
    {
        favicon_url: 'https://raw.githubusercontent.com/redlib-org/redlib/refs/heads/main/static/favicon.ico',
        skipMaps: true,
    }
);

/* --------------------------------- Helpers -------------------------------- */

const errors = [];
const escapeRegex = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const TWITTER_HOSTS = new Set([
    'twitter.com',
    'x.com',
    'fxtwitter.com',
    'fixupx.com',
    'vxtwitter.com',
    'fixvx.com'
]);

const parsedNitter = new URL(NITTER_URL);
const parsedRedlib = new URL(REDLIB_URL);

// Structured URL Transformation Rules
const forwardRules = [
    // 1. YouTube Redirect Unwrapping
    (parsed) => {
        if (parsed.hostname === 'www.youtube.com' && parsed.pathname === '/redirect') {
            const target = parsed.searchParams.get('q');
            return target ? target : null;
        }
    },
    // 2. YouTube Shorts -> /watch?v=
    (parsed) => {
        if (parsed.hostname === 'www.youtube.com' && parsed.pathname.startsWith('/shorts/')) {
            const videoId = parsed.pathname.split('/')[2];
            if (videoId) {
                parsed.pathname = '/watch';
                parsed.searchParams.set('v', videoId);
                return parsed.href;
            }
        }
    },
    // 3. YouTube Channel @handle -> /videos
    (parsed) => {
        if (parsed.hostname === 'www.youtube.com' && /^\/@[^/]+$/.test(parsed.pathname)) {
            parsed.pathname = `${parsed.pathname}/videos`;
            return parsed.href;
        }
    },
    // 4. Twitter / X / FXTwitter -> Nitter
    (parsed) => {
        if (TWITTER_HOSTS.has(parsed.hostname)) {
            parsed.protocol = parsedNitter.protocol;
            parsed.host = parsedNitter.host;
            return parsed.href;
        }
    },
    // 5. Reddit -> Redlib
    (parsed) => {
        if (parsed.hostname.endsWith('reddit.com') && parsed.hostname !== parsedRedlib.hostname) {
            parsed.protocol = parsedRedlib.protocol;
            parsed.host = parsedRedlib.host;
            return parsed.href;
        }
    }
];

const reverseRules = [
    // 1. Nitter -> Twitter
    (parsed) => {
        if (parsed.host === parsedNitter.host) {
            parsed.protocol = 'https:';
            parsed.host = 'twitter.com';
            return parsed.href;
        }
    },
    // 2. Redlib -> Reddit
    (parsed) => {
        if (parsed.host === parsedRedlib.host) {
            parsed.protocol = 'https:';
            parsed.host = 'www.reddit.com';
            return parsed.href;
        }
    }
];

function transformUrl(url, rules = forwardRules) {
    let currentUrl = url;
    let transformed = true;
    let depth = 0;

    // Loop to allow chained transformations (e.g. YouTube redirect -> Reddit -> Redlib)
    while (transformed && depth < 5) {
        transformed = false;
        depth++;
        const parsed = new URL(currentUrl);

        for (const rule of rules) {
            const result = rule(new URL(parsed.href)); // Pass clean instance
            if (result && result !== currentUrl) {
                currentUrl = result;
                transformed = true;
                break;
            }
        }
    }
    return currentUrl;
}

function transformUrlReverse(url) {
    return transformUrl(url, reverseRules);
}

function dispatchMouseClick(element, callback = api.Hints.dispatchMouseClick) {
    if (!element.hasAttribute('href') && element.parentElement?.hasAttribute('href')) {
        // TODO: Hack for google: sometimes hints are created for children of <a> elements
        element = element.parentElement;
    }

    const original = element.href;
    const transformed = transformUrl(original);
    if (transformed !== original) {
        element.href = transformed;
    }

    callback(element);
}

const [map, mapkey, getKeysStatus, descToTmpKeyDict] = (function () {
    const keyToDescDict = {
        '<Alt-i>': 'Enter PassThrough mode',
        'C': 'Open a link in non-active new tab',
        'D': 'Go forward in history',
        'E': 'Go one tab left',
        'F': 'Go one tab history forward',
        'H': 'Open opened URL in current tab',
        'L': 'Enter regional Hints mode',
        'O': 'Open detected links from text',
        'P': 'Scroll full page down',
        'R': 'Go one tab right',
        'S': 'Go back in history',
        'f': 'Open a link',
        'go': 'Open a URL in current tab',
        'j': 'Scroll down',
        'k': 'Scroll up',
        'on': 'Open newtab',
        'q': 'Click on an image or a button',
        'sog': 'Search selected within current site with google',
        't': 'Open a URL',
        'w': 'Switch frames',
        'ya': 'Copy a link URL to the clipboard',
        'yy': 'Copy current page\'s URL',
    };

    const currMappedKeys = new Set();

    const descToTmpKeyDict = Object.fromEntries(
        Object.values(keyToDescDict).map((desc, index) => {
            const letters = 'abcdefghijklmnopqrstuvwxyz';
            const prefixCount = Math.floor(index / letters.length) + 1;
            const letter = letters[index % letters.length];
            return [desc, '#'.repeat(prefixCount) + letter];
        })
    );

    Object.keys(keyToDescDict).forEach(keys => {
        api.map(descToTmpKeyDict[keyToDescDict[keys]], keys);
        currMappedKeys.add(descToTmpKeyDict[keyToDescDict[keys]]);
        api.unmap(keys);
    });

    function map(keys, desc, domain) {
        if (!(desc in descToTmpKeyDict)) {
            errors.push(`map('${keys}', '${desc}'): description '${desc}' doesn't exist`);
            return;
        }
        api.map(keys, descToTmpKeyDict[desc], domain);
        currMappedKeys.add(keys);
    }

    function mapkey(keys, desc, jscode, options) {
        api.mapkey(keys, desc, jscode, options);
        currMappedKeys.add(keys);
    }

    function getKeysStatus() {
        const prevMappedKeys = new Set(Object.keys(keyToDescDict));
        return [
            currMappedKeys.difference(prevMappedKeys),
            currMappedKeys.intersection(prevMappedKeys),
            prevMappedKeys.difference(currMappedKeys),
        ];
    }

    return [map, mapkey, getKeysStatus, descToTmpKeyDict];
})();

function waitForElement(root, selector, timeout = 5000) {
    return new Promise((resolve, reject) => {
        const existing = root.querySelector(selector);
        if (existing) return resolve(existing);

        let timeoutId;
        const observer = new MutationObserver(() => {
            const el = root.querySelector(selector);
            if (el) {
                clearTimeout(timeoutId);
                observer.disconnect();
                resolve(el);
            }
        });

        observer.observe(root === document ? document.body || document.documentElement : root, {
            childList: true,
            subtree: true
        });

        timeoutId = setTimeout(() => {
            observer.disconnect();
            reject(new Error(`Timeout: Element "${selector}" did not appear within ${timeout}ms`));
        }, timeout);
    });
}

/* -------------------------------- Mappings -------------------------------- */

mapkey('f', '#1Open a link with transformation', () => {
    api.Hints.create('', dispatchMouseClick);
});

mapkey('F', '#1Open a link with transformation in active new tab', () => {
    api.Hints.create('', dispatchMouseClick, { tabbed: true, active: true });
});

mapkey('C', '#1Open a link with transformation in non-active new tab', () => {
    api.Hints.create('', dispatchMouseClick, { tabbed: true, active: false });
});

mapkey('ci', '#1Open a link with transformation in incognito window', () => {
    // TODO: Hack for youtube: sometimes hints are created for parents of <a> elements
    api.Hints.create('[href]', (element) => {
        dispatchMouseClick(element, (e) => {
            api.RUNTIME('openIncognito', { url: e.href || undefined });
        });
    });
});

mapkey('P', '#7Open a link from clipboard with transformation in active new tab', () => {
    api.Clipboard.read(response => {
        try {
            api.tabOpenLink(transformUrl(response.data));
        } catch {
            api.Front.showBanner(`Invalid URL: "${response.data}"`);
        }
    });
});

mapkey('ya', '#7Copy a link URL to the clipboard', () => {
    api.Hints.create('*[href]', element => {
        const reversed = transformUrlReverse(element.href);
        api.Clipboard.write(reversed);
        api.Front.showBanner(`Copied: ${reversed}`);
    });
});

mapkey('yy', '#7Copy current page\'s URL', () => {
    const reversed = transformUrlReverse(window.location.href);
    api.Clipboard.write(reversed);
    api.Front.showBanner(`Copied: ${reversed}`);
});

mapkey('yA', '#7Copy all external links on page to clipboard', () => {
    const uniqueLinks = Array.from(
        new Set(
            Array.from(document.querySelectorAll('a[href]'), a => a.href)
                .filter(href => href && !href.startsWith('javascript:') && !href.startsWith(window.location.origin))
        )
    );

    if (uniqueLinks.length > 0) {
        api.Clipboard.write(uniqueLinks.join('\n'));
        api.Front.showBanner(`Copied ${uniqueLinks.length} links to clipboard`);
    } else {
        api.Front.showBanner('No external links found on page.');
    }
});

map('q', 'Click on an image or a button');
// TODO: Even with `settings.clickableSelector = 'summary'`, hints for <summary> elements aren't created
mapkey('q', '#1Toggle a comment open/closed', () => {
    api.Hints.create('summary', dispatchMouseClick);
}, { domain: new RegExp(escapeRegex(parsedRedlib.hostname)) });

mapkey(',s', 'Search full text of item with google', () => {
    // See filterOverlapElements
    api.Hints.create('[role="heading"]', element => {
        const query = `${element.innerText.trim()} site:aliexpress.com`;
        api.RUNTIME('openLink', {
            tab: { tabbed: true },
            url: `https://www.google.com/search?q=${encodeURIComponent(query)}`
        });
    });
}, { domain: /aliexpress\.us/ });

mapkey(',d', 'Delete chat', () => {
    api.Hints.create('gem-nav-list-item[data-test-id="conversation"]', async element => {
        try {
            const actionsMenuButton = await waitForElement(element, 'gem-icon-button[data-test-id="actions-menu-button"]');
            actionsMenuButton.click();

            const deleteButton = await waitForElement(document, 'button[data-test-id="delete-button"]');
            deleteButton.click();

            const confirmDeleteButton = await waitForElement(document, 'mat-dialog-actions > gem-button:nth-child(2)');
            confirmDeleteButton.click();
        } catch (err) {
            console.error('[SurfingKeys] ,d error:', err);
        }
    });
}, { domain: /gemini\.google\.com/ });

map('j', 'Scroll down');
map('k', 'Scroll up');
map('s', 'Scroll down'); // Removes all bindings with leader key 's'
map('w', 'Scroll up');

map('E', 'Go one tab left');
map('R', 'Go one tab right');
map('S', 'Go back in history');
map('D', 'Go forward in history');
map('J', 'Go one tab left');
map('K', 'Go one tab right');
map('H', 'Go back in history');
map('L', 'Go forward in history');

map('<Ctrl-X>', 'Enter PassThrough mode');
map('O', 'Open a URL');
map('o', 'Open a URL in current tab'); // Removes all bindings with leader key 'o'
map('t', 'Open newtab');

api.iunmap('<Ctrl-a>');

if (DEBUG) {
    const tmp = getKeysStatus().map(s => Array.from(s).join(', '));
    console.log(`[SurfingKeys] Previously unmapped keys: ${tmp[0]}`);
    console.log(`[SurfingKeys] Remapped keys: ${tmp[1]}`);
    console.log(`[SurfingKeys] Currently unmapped keys: ${tmp[2]}`);
}

/* -------------------------------------------------------------------------- */

if (errors.length) {
    api.Front.showPopup('[SurfingKeys] Errors found in settings: see console');
    console.log(errors.map(e => '[SurfingKeys] Error found in settings: ' + e).join('\n'));
}
